import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface Profile {
  fcm_token: string;
  display_name: string;
}

interface PendingNotification {
  id: string;
  job_id: number;
  driver_id: string;
  is_reassignment: boolean;
  profiles: Profile;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get pending notifications
    const { data: pendingNotifications, error: fetchError } = await supabase
      .from('job_notification_log')
      .select(`
        id,
        job_id,
        driver_id,
        is_reassignment,
        profiles!inner(fcm_token, display_name)
      `)
      .eq('status', 'pending')
      .order('created_at', { ascending: true })

    if (fetchError) {
      console.error('Error fetching pending notifications:', fetchError)
      return new Response(JSON.stringify({ error: 'Failed to fetch notifications' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    if (!pendingNotifications || pendingNotifications.length === 0) {
      return new Response(JSON.stringify({ message: 'No pending notifications' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    console.log(`Processing ${pendingNotifications.length} pending notifications`)

    const results = []

    for (const notification of pendingNotifications) {
      try {
        // Handle the profiles array structure from Supabase
        const profile = Array.isArray(notification.profiles) ? notification.profiles[0] : notification.profiles
        
        // Create notification record in the app_notifications table (not the old notifications table)
        const message = notification.is_reassignment 
          ? 'Job reassigned to you. Please confirm your job in the app.'
          : 'New job assigned. Please confirm your job in the app.'

        const { error: notificationError } = await supabase
          .from('app_notifications')
          .insert({
            user_id: notification.driver_id,
            job_id: notification.job_id,
            message: message,
            notification_type: 'job_assignment',
            priority: 'high',
            is_read: false,
            is_hidden: false,
          })

        if (notificationError) {
          console.error(`Error creating notification record: ${notificationError}`)
        } else {
          console.log(`Created notification record for driver ${notification.driver_id}`)
        }

        if (!profile?.fcm_token) {
          console.log(`No FCM token for driver ${notification.driver_id}`)
          // Mark as processed even if no token
          await supabase
            .from('job_notification_log')
            .update({ 
              status: 'processed', 
              processed_at: new Date().toISOString() 
            })
            .eq('id', notification.id)
          continue
        }

        // Send FCM notification (no emojis in messages)
        const fcmMessage = notification.is_reassignment 
          ? 'Job reassigned to you. Please confirm your job in the app.'
          : 'New job assigned. Please confirm your job in the app.'

        const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
          method: 'POST',
          headers: {
            'Authorization': `key=${Deno.env.get('FIREBASE_SERVER_KEY')}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            to: profile.fcm_token,
            notification: {
              title: 'New Job Assignment',
              body: fcmMessage,
            },
            data: {
              job_id: notification.job_id.toString(),
              action: 'new_job_assigned',
              is_reassignment: notification.is_reassignment.toString(),
            },
            priority: 'high',
          }),
        })

        if (fcmResponse.ok) {
          // Mark as processed
          await supabase
            .from('job_notification_log')
            .update({ 
              status: 'processed', 
              processed_at: new Date().toISOString() 
            })
            .eq('id', notification.id)

          results.push({
            id: notification.id,
            status: 'sent',
            driver_name: profile.display_name
          })
        } else {
          console.error(`FCM failed for notification ${notification.id}:`, fcmResponse.statusText)
          results.push({
            id: notification.id,
            status: 'failed',
            error: fcmResponse.statusText
          })
        }
      } catch (error) {
        console.error(`Error processing notification ${notification.id}:`, error)
        results.push({
          id: notification.id,
          status: 'error',
          error: error instanceof Error ? error.message : 'Unknown error'
        })
      }
    }

    return new Response(JSON.stringify({ 
      processed: results.length,
      results,
      message: `Processed ${pendingNotifications.length} pending notifications`
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('Error in process-job-notifications:', error)
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : 'Unknown error' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
}) 