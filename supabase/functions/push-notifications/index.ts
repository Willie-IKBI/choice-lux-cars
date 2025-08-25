import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Types for webhook payload
interface Notification {
  id: string
  user_id: string
  message: string
  notification_type: string
  priority: string
  job_id?: string
  action_data?: any
  created_at: string
}

interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE'
  table: string
  record: Notification
  schema: 'public'
  old_record: null | Notification
}

// Initialize Supabase client
const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const supabase = createClient(supabaseUrl, supabaseServiceKey)

// FCM configuration
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')
const FCM_PROJECT_ID = Deno.env.get('FCM_PROJECT_ID')

serve(async (req) => {
  try {
    console.log('=== PUSH NOTIFICATION EDGE FUNCTION STARTED ===')
    
    // Parse webhook payload
    const payload: WebhookPayload = await req.json()
    console.log('Webhook payload:', JSON.stringify(payload, null, 2))
    
    // Only handle INSERT events on app_notifications table
    if (payload.type !== 'INSERT' || payload.table !== 'app_notifications') {
      console.log('Ignoring non-INSERT event or wrong table')
      return new Response(JSON.stringify({ message: 'Ignored' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200
      })
    }
    
    const notification = payload.record
    console.log('Processing notification:', notification.id)
    
    // Get user's FCM token from profiles table
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('fcm_token, display_name')
      .eq('id', notification.user_id)
      .single()
    
    if (profileError || !profile?.fcm_token) {
      console.log('No FCM token found for user:', notification.user_id)
      return new Response(JSON.stringify({ 
        message: 'No FCM token found',
        user_id: notification.user_id 
      }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200
      })
    }
    
    console.log('Found FCM token for user:', profile.display_name)
    
    // Prepare FCM message
    const fcmMessage = {
      to: profile.fcm_token,
      notification: {
        title: getNotificationTitle(notification.notification_type),
        body: notification.message,
        sound: 'default',
        priority: notification.priority === 'high' ? 'high' : 'normal'
      },
      data: {
        notification_id: notification.id,
        notification_type: notification.notification_type,
        job_id: notification.job_id || '',
        action_data: JSON.stringify(notification.action_data || {}),
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        priority: notification.priority === 'high' ? 'high' : 'normal',
        notification: {
          sound: 'default',
          priority: notification.priority === 'high' ? 'high' : 'normal',
          channel_id: 'choice_lux_cars_channel'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    }
    
    console.log('Sending FCM message:', JSON.stringify(fcmMessage, null, 2))
    
    // Send push notification via FCM
    const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `key=${FCM_SERVER_KEY}`
      },
      body: JSON.stringify(fcmMessage)
    })
    
    const fcmResult = await fcmResponse.json()
    console.log('FCM response:', JSON.stringify(fcmResult, null, 2))
    
    // Log the notification delivery (optional)
    try {
      await supabase
        .from('notification_delivery_log')
        .insert({
          notification_id: notification.id,
          user_id: notification.user_id,
          fcm_token: profile.fcm_token,
          fcm_response: fcmResult,
          sent_at: new Date().toISOString(),
          success: fcmResult.success === 1
        })
    } catch (logError) {
      console.log('Failed to log delivery (non-critical):', logError)
    }
    
    console.log('=== PUSH NOTIFICATION SENT SUCCESSFULLY ===')
    
    return new Response(JSON.stringify({
      success: true,
      notification_id: notification.id,
      fcm_result: fcmResult
    }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200
    })
    
  } catch (error) {
    console.error('=== PUSH NOTIFICATION ERROR ===')
    console.error('Error:', error)
    
    return new Response(JSON.stringify({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500
    })
  }
})

// Helper function to get notification title based on type
function getNotificationTitle(notificationType: string): string {
  switch (notificationType) {
    case 'job_assignment':
      return 'New Job Assignment'
    case 'job_reassignment':
      return 'Job Reassigned'
    case 'job_confirmation':
      return 'Job Confirmed'
    case 'job_cancellation':
      return 'Job Cancelled'
    case 'job_status_change':
      return 'Job Status Updated'
    case 'payment_reminder':
      return 'Payment Reminder'
    case 'system_alert':
      return 'System Alert'
    default:
      return 'New Notification'
  }
}
