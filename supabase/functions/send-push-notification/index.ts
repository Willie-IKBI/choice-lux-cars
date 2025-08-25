import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationPayload {
  user_id: string;
  title: string;
  body: string;
  data?: Record<string, any>;
  priority?: 'normal' | 'high';
  sound?: boolean;
  badge?: number;
}

serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get request body
    const payload: NotificationPayload = await req.json()

    // Validate required fields
    if (!payload.user_id || !payload.title || !payload.body) {
      return new Response(
        JSON.stringify({ 
          error: 'Missing required fields: user_id, title, and body are required' 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get user's FCM token
    const { data: profile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('fcm_token, display_name')
      .eq('id', payload.user_id)
      .single()

    if (profileError || !profile) {
      return new Response(
        JSON.stringify({ 
          error: 'User not found or profile error',
          details: profileError?.message 
        }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    if (!profile.fcm_token) {
      return new Response(
        JSON.stringify({ 
          error: 'User has no FCM token registered',
          user_id: payload.user_id 
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Prepare FCM message
    const fcmMessage = {
      to: profile.fcm_token,
      notification: {
        title: payload.title,
        body: payload.body,
        sound: payload.sound !== false ? 'default' : undefined,
        badge: payload.badge,
      },
      data: {
        ...payload.data,
        user_id: payload.user_id,
        timestamp: new Date().toISOString(),
      },
      priority: payload.priority || 'normal',
      android: {
        priority: payload.priority || 'normal',
        notification: {
          sound: payload.sound !== false ? 'default' : undefined,
          priority: payload.priority || 'normal',
          channel_id: 'choice_lux_cars_channel',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: payload.sound !== false ? 'default' : undefined,
            badge: payload.badge,
            'content-available': 1,
          },
        },
      },
    }

    // Send FCM notification
    const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${Deno.env.get('FIREBASE_SERVER_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(fcmMessage),
    })

    const fcmResult = await fcmResponse.json()

    if (!fcmResponse.ok) {
      console.error('FCM Error:', fcmResult)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to send FCM notification',
          fcm_error: fcmResult,
          user_id: payload.user_id 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Check FCM response
    if (fcmResult.failure === 1) {
      const failureReason = fcmResult.results?.[0]?.error
      console.error('FCM Failure:', failureReason)
      
      // Handle specific FCM errors
      if (failureReason === 'NotRegistered' || failureReason === 'InvalidRegistration') {
        // Remove invalid token
        await supabaseClient
          .from('profiles')
          .update({ 
            fcm_token: null,
            fcm_token_updated_at: null 
          })
          .eq('id', payload.user_id)
        
        return new Response(
          JSON.stringify({ 
            error: 'Invalid FCM token - token removed',
            failure_reason: failureReason,
            user_id: payload.user_id 
          }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
      }
      
      return new Response(
        JSON.stringify({ 
          error: 'FCM delivery failed',
          failure_reason: failureReason,
          user_id: payload.user_id 
        }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Log successful delivery
    const messageId = fcmResult.results?.[0]?.message_id
    console.log(`FCM notification sent successfully to user ${payload.user_id}, message_id: ${messageId}`)

    // Store delivery log (optional)
    try {
      await supabaseClient
        .from('notification_delivery_log')
        .insert({
          user_id: payload.user_id,
          fcm_token: profile.fcm_token.substring(0, 20) + '...', // Truncate for privacy
          message_id: messageId,
          title: payload.title,
          body: payload.body,
          data: payload.data,
          priority: payload.priority || 'normal',
          delivery_status: 'delivered',
          delivered_at: new Date().toISOString(),
        })
    } catch (logError) {
      console.warn('Failed to log delivery:', logError)
      // Don't fail the request if logging fails
    }

    return new Response(
      JSON.stringify({ 
        success: true,
        message_id: messageId,
        user_id: payload.user_id,
        user_name: profile.display_name,
        delivered_at: new Date().toISOString(),
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error in send-push-notification:', error)
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        details: errorMessage 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
