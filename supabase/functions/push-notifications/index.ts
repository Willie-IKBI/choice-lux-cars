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

// FCM configuration - use Firebase Admin SDK with service account
const SERVICE_ACCOUNT_KEY = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY')

// Initialize Firebase Admin SDK approach (manual implementation)
let accessToken: string | null = null
let tokenExpiry: number = 0

async function getFirebaseAccessToken(): Promise<string> {
  // Check if we have a valid token
  if (accessToken && Date.now() < tokenExpiry) {
    return accessToken
  }
  
  if (!SERVICE_ACCOUNT_KEY) {
    throw new Error('Service account key not configured')
  }
  
  try {
    const serviceAccount = JSON.parse(SERVICE_ACCOUNT_KEY)
    
    // Generate JWT for service account authentication
    const now = Math.floor(Date.now() / 1000)
    const payload = {
      iss: serviceAccount.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600, // 1 hour
    }

    const header = {
      alg: 'RS256',
      typ: 'JWT',
      kid: serviceAccount.private_key_id,
    }

    // Use built-in btoa for base64url encoding
    const encodedHeader = btoa(JSON.stringify(header)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
    const encodedPayload = btoa(JSON.stringify(payload)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
    
    const signatureInput = `${encodedHeader}.${encodedPayload}`
    
    // Convert PEM to DER and import the private key
    const pemContent = serviceAccount.private_key
      .replace(/-----BEGIN PRIVATE KEY-----/g, '')
      .replace(/-----END PRIVATE KEY-----/g, '')
      .replace(/\\n/g, '\n')
      .replace(/\n/g, '')
      .trim()
    
    const binaryString = atob(pemContent)
    const derKey = new Uint8Array(binaryString.length)
    for (let i = 0; i < binaryString.length; i++) {
      derKey[i] = binaryString.charCodeAt(i)
    }
    
    const privateKey = await crypto.subtle.importKey(
      'pkcs8',
      derKey,
      {
        name: 'RSASSA-PKCS1-v1_5',
        hash: 'SHA-256',
      },
      false,
      ['sign']
    )

    const signature = await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      privateKey,
      new TextEncoder().encode(signatureInput)
    )

    // Convert ArrayBuffer to base64url
    const signatureArray = new Uint8Array(signature)
    const signatureBase64 = btoa(String.fromCharCode(...signatureArray))
    const encodedSignature = signatureBase64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
    
    const jwt = `${signatureInput}.${encodedSignature}`
    
    // Get OAuth2 access token
    const response = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt,
      }),
    })

    if (!response.ok) {
      throw new Error(`Failed to get access token: ${response.statusText}`)
    }

    const data = await response.json()
    accessToken = data.access_token
    tokenExpiry = Date.now() + (data.expires_in * 1000) - 60000 // 1 minute buffer
    
    console.log('Firebase access token obtained successfully')
    return accessToken
  } catch (error) {
    console.error('Failed to get Firebase access token:', error)
    throw error
  }
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey, x-client-info',
        'Access-Control-Max-Age': '86400',
      },
    })
  }

  try {
    console.log('=== PUSH NOTIFICATION EDGE FUNCTION STARTED ===')
    console.log('Request method:', req.method)
    console.log('Request headers:', Object.fromEntries(req.headers.entries()))
    
    // Get raw body first
    const rawBody = await req.text()
    console.log('Raw request body:', rawBody)
    
    if (!rawBody || rawBody.trim() === '') {
      console.log('Empty request body received')
      return new Response(JSON.stringify({ error: 'Empty request body' }), {
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        status: 400
      })
    }
    
    // Parse webhook payload
    let payload: WebhookPayload
    try {
      payload = JSON.parse(rawBody)
    } catch (parseError) {
      console.log('JSON parse error:', parseError)
      console.log('Raw body that failed to parse:', rawBody)
      return new Response(JSON.stringify({ error: 'Invalid JSON', body: rawBody }), {
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        status: 400
      })
    }
    
    console.log('Webhook payload:', JSON.stringify(payload, null, 2))
    
    // Only handle INSERT events on app_notifications table
    if (payload.type !== 'INSERT' || payload.table !== 'app_notifications') {
      console.log('Ignoring non-INSERT event or wrong table')
      return new Response(JSON.stringify({ message: 'Ignored' }), {
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        status: 200
      })
    }
    
    const notification = payload.record
    console.log('Processing notification:', notification.id)
    
    // Get user's FCM tokens and notification preferences from profiles table
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('fcm_token, fcm_token_web, display_name, notification_prefs')
      .eq('id', notification.user_id)
      .single()
    
    if (profileError) {
      console.log('Error fetching profile for user:', notification.user_id, profileError)
      return new Response(JSON.stringify({ 
        message: 'Error fetching profile',
        user_id: notification.user_id 
      }), {
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        status: 200
      })
    }
    
    // Get all available tokens (web and/or mobile)
    const tokens: string[] = []
    if (profile?.fcm_token) {
      tokens.push(profile.fcm_token)
      console.log('Found mobile FCM token for user:', profile.display_name)
    }
    if (profile?.fcm_token_web) {
      tokens.push(profile.fcm_token_web)
      console.log('Found web FCM token for user:', profile.display_name)
    }
    
    if (tokens.length === 0) {
      console.log('No FCM tokens found for user:', notification.user_id)
      return new Response(JSON.stringify({ 
        message: 'No FCM tokens found',
        user_id: notification.user_id 
      }), {
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        status: 200
      })
    }
    
    // Check user's notification preferences
    const notificationType = notification.notification_type
    const prefs = profile?.notification_prefs as Record<string, boolean> | null
    
    if (prefs && prefs[notificationType] === false) {
      console.log(`Notification ${notification.id}: skipped_preferences (user disabled ${notificationType})`)
      return new Response(JSON.stringify({ 
        message: 'Notification skipped due to user preferences',
        notification_id: notification.id,
        notification_type: notificationType,
        user_id: notification.user_id 
      }), {
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        status: 200
      })
    }
    
    console.log(`Found ${tokens.length} FCM token(s) for user: ${profile.display_name}`)
        
        if (!SERVICE_ACCOUNT_KEY) {
          console.log('Firebase Service Account Key not configured')
          return new Response(JSON.stringify({ 
            message: 'Firebase Service Account Key not configured',
            user_id: notification.user_id 
          }), {
            headers: { 
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*',
            },
            status: 500
          })
        }
        
        console.log('Firebase service account configured, getting access token...')
        
        // Get Firebase access token once for all sends
        const firebaseToken = await getFirebaseAccessToken()
        
        // Send to all tokens (web and/or mobile)
        const fcmResults: any[] = []
        let successCount = 0
        let failureCount = 0
        
        for (const token of tokens) {
          try {
            // Prepare FCM message (Admin SDK format)
            const fcmMessage = {
              token: token,
              notification: {
                title: getNotificationTitle(notification.notification_type),
                body: notification.message
              },
              data: {
                notification_id: notification.id,
                notification_type: notification.notification_type,
                action: getActionFromNotificationType(notification.notification_type), // Map to Flutter action values
                job_id: notification.job_id || '',
                action_data: JSON.stringify(notification.action_data || {}),
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
              },
              android: {
                priority: notification.priority === 'high' ? 'high' : 'normal',
                notification: {
                  sound: 'default',
                  channelId: 'choice_lux_cars_channel'
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
            
            console.log(`Sending FCM message to token: ${token.substring(0, 20)}...`)
            
            const fcmResponse = await fetch('https://fcm.googleapis.com/v1/projects/choice-lux-cars-8d510/messages:send', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${firebaseToken}`
              },
              body: JSON.stringify({
                message: fcmMessage
              })
            })
            
            const responseText = await fcmResponse.text()
            let fcmResult: any
            
            if (responseText.startsWith('<')) {
              // HTML response (error page)
              console.error('FCM returned HTML error page for token:', token.substring(0, 20))
              fcmResult = { 
                error: 'FCM API returned HTML error page',
                status: fcmResponse.status,
                rawResponse: responseText.substring(0, 200) + '...',
                token: token.substring(0, 20) + '...'
              }
              failureCount++
            } else {
              try {
                fcmResult = JSON.parse(responseText)
                
                if (fcmResult.error) {
                  console.error('FCM API error for token:', token.substring(0, 20), fcmResult.error)
                  fcmResult.error = fcmResult.error.message || fcmResult.error
                  failureCount++
                } else {
                  if (fcmResult.name) {
                    fcmResult.success = 1
                    fcmResult.message_id = fcmResult.name.split('/').pop()
                    console.log('FCM notification sent successfully:', fcmResult.message_id)
                    successCount++
                  }
                }
              } catch (parseError) {
                console.error('Failed to parse FCM response:', parseError)
                fcmResult = { 
                  error: 'Invalid JSON response from FCM',
                  rawResponse: responseText,
                  token: token.substring(0, 20) + '...'
                }
                failureCount++
              }
            }
            
            fcmResults.push(fcmResult)
            
            // Log delivery for this token
            try {
              await supabase
                .from('notification_delivery_log')
                .insert({
                  notification_id: notification.id,
                  user_id: notification.user_id,
                  fcm_token: token,
                  fcm_response: fcmResult,
                  sent_at: new Date().toISOString(),
                  success: fcmResult.success === 1
                })
            } catch (logError) {
              console.log('Failed to log delivery (non-critical):', logError)
            }
          } catch (error) {
            console.error('Error sending to token:', token.substring(0, 20), error)
            fcmResults.push({
              error: error instanceof Error ? error.message : 'Unknown error',
              token: token.substring(0, 20) + '...'
            })
            failureCount++
          }
        }
        
        console.log(`=== PUSH NOTIFICATION SENT ===`)
        console.log(`Total tokens: ${tokens.length}, Success: ${successCount}, Failed: ${failureCount}`)
        
        return new Response(JSON.stringify({
          success: successCount > 0,
          notification_id: notification.id,
          tokens_sent: tokens.length,
          success_count: successCount,
          failure_count: failureCount,
          fcm_results: fcmResults
        }), {
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
          status: successCount > 0 ? 200 : 500
        })
    
  } catch (error) {
    console.error('=== PUSH NOTIFICATION ERROR ===')
    console.error('Error:', error)
    
    return new Response(JSON.stringify({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }), {
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
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
    case 'job_cancelled':
      return 'Job Cancelled'
    case 'job_status_change':
      return 'Job Status Updated'
    case 'payment_reminder':
      return 'Payment Reminder'
    case 'system_alert':
      return 'System Alert'
    case 'job_start':
      return 'Job Started'
    case 'step_completion':
      return 'Driver Update'
    case 'job_completion':
      return 'Job Completed'
    case 'job_start_deadline_warning_90min':
      return 'Job Start Warning'
    case 'job_start_deadline_warning_30min':
      return 'Job Start Urgent Warning'
    default:
      return 'New Notification'
  }
}

// Helper function to map notification types to Flutter action values
function getActionFromNotificationType(notificationType: string): string {
  switch (notificationType) {
    case 'job_assignment':
      return 'new_job_assigned'
    case 'job_reassignment':
      return 'job_reassigned'
    case 'job_cancellation':
    case 'job_cancelled':
      return 'job_cancelled'
    case 'job_status_change':
      return 'job_status_changed'
    case 'payment_reminder':
      return 'payment_reminder'
    case 'system_alert':
      return 'system_alert'
    case 'job_start':
    case 'step_completion':
    case 'job_completion':
    case 'job_confirmation':
    case 'job_start_deadline_warning_90min':
    case 'job_start_deadline_warning_30min':
      return 'job_status_changed' // Generic job update action
    default:
      return notificationType // Fallback to notification type
  }
}

// Legacy FCM implementation - no complex JWT generation needed
