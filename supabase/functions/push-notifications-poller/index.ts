import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

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
    case 'job_start_deadline_warning_60min':
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
    case 'job_start_deadline_warning_60min':
      return 'job_status_changed'
    default:
      return notificationType
  }
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    })
  }

  try {
    // Generate run_id for this invocation
    const runId = crypto.randomUUID()
    console.log(`=== PUSH NOTIFICATIONS POLLER STARTED === run_id: ${runId}`)
    
    // Parse optional request body
    let requestBody: any = {}
    try {
      const bodyText = await req.text()
      if (bodyText && bodyText.trim()) {
        requestBody = JSON.parse(bodyText)
      }
    } catch (parseError) {
      // Ignore parse errors, use empty body (batch mode)
    }

    const notificationId = requestBody.notification_id || null
    const limit = requestBody.limit || 50
    const dryRun = requestBody.dry_run === true

    const mode = notificationId ? 'single' : 'batch'
    console.log(`[${runId}] Mode: ${mode}`)
    if (dryRun) {
      console.log(`[${runId}] DRY RUN MODE: Will not send FCM messages or log success=true`)
    }
    
    // Initialize Supabase client with service role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Acquire advisory lock to prevent concurrent runs
    const lockKey = 1234567890 // Fixed key for this poller
    const { data: lockResult, error: lockError } = await supabase.rpc('pg_advisory_lock', {
      p_lock_key: lockKey
    })

    const lockAcquired = !lockError
    console.log(`[${runId}] Lock acquired: ${lockAcquired ? 'yes' : 'no'}`)

    if (lockError) {
      // If lock cannot be acquired, another instance is running
      console.log(`[${runId}] Advisory lock not acquired, another instance may be running. Exiting.`)
      return new Response(JSON.stringify({
        success: true,
        run_id: runId,
        mode,
        message: 'Lock not acquired, skipping run',
        selected_count: 0,
        processed: 0,
        sent_success: 0,
        sent_failed: 0,
        skipped_max_retries: 0,
        skipped_cooldown: 0,
        skipped_preferences: 0,
        missing_token: 0,
        dry_run: dryRun
      }), {
        headers: { 
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
        status: 200
      })
    }

    try {
      let notificationsToProcess: any[] = []

      if (mode === 'single') {
        // Single notification mode: fetch specific notification
        console.log(`[${runId}] Single notification mode: ${notificationId}`)
        
        // Check if notification exists and is undelivered
        const { data: notification, error: notifError } = await supabase
          .from('app_notifications')
          .select('id, user_id, message, notification_type, priority, job_id, action_data, created_at')
          .eq('id', notificationId)
          .eq('is_hidden', false)
          .single()

        if (notifError || !notification) {
          return new Response(JSON.stringify({
            success: true,
            run_id: runId,
            mode,
            message: `Notification ${notificationId} not found or is hidden`,
            selected_count: 0,
            processed: 0,
            sent_success: 0,
            sent_failed: 0,
            skipped_max_retries: 0,
            skipped_cooldown: 0,
            skipped_preferences: 0,
            missing_token: 0,
            dry_run: dryRun
          }), {
            headers: { 
              'Content-Type': 'application/json',
              ...corsHeaders,
            },
            status: 200
          })
        }

        // Check if already successfully delivered
        const { data: successfulDelivery } = await supabase
          .from('notification_delivery_log')
          .select('id')
          .eq('notification_id', notificationId)
          .eq('success', true)
          .limit(1)
          .maybeSingle()

        if (successfulDelivery) {
          return new Response(JSON.stringify({
            success: true,
            run_id: runId,
            mode,
            message: `Notification ${notificationId} already successfully delivered`,
            selected_count: 0,
            processed: 0,
            sent_success: 0,
            sent_failed: 0,
            skipped_max_retries: 0,
            skipped_cooldown: 0,
            skipped_preferences: 0,
            missing_token: 0,
            dry_run: dryRun
          }), {
            headers: { 
              'Content-Type': 'application/json',
              ...corsHeaders,
            },
            status: 200
          })
        }

        // Get retry info for this notification
        const { data: retryInfo } = await supabase
          .from('notification_delivery_log')
          .select('retry_count, sent_at')
          .eq('notification_id', notificationId)
          .order('sent_at', { ascending: false })
          .limit(1)
          .maybeSingle()

        notificationsToProcess = [{
          ...notification,
          max_retry_count: retryInfo?.retry_count || 0,
          last_attempt_at: retryInfo?.sent_at || null
        }]
      } else {
        // Batch mode: use RPC function
        console.log(`[${runId}] Batch mode: fetching up to ${limit} notifications`)
        const { data: batchNotifications, error: queryError } = await supabase.rpc('get_undelivered_notifications', {
          limit_count: limit
        })

        if (queryError) {
          console.error('Error querying pending notifications:', queryError)
          throw queryError
        }

        if (!batchNotifications || batchNotifications.length === 0) {
          console.log(`[${runId}] No pending notifications found`)
          return new Response(JSON.stringify({
            success: true,
            run_id: runId,
            mode,
            message: 'No pending notifications',
            selected_count: 0,
            processed: 0,
            sent_success: 0,
            sent_failed: 0,
            skipped_max_retries: 0,
            skipped_cooldown: 0,
            skipped_preferences: 0,
            missing_token: 0,
            dry_run: dryRun
          }), {
            headers: { 
              'Content-Type': 'application/json',
              ...corsHeaders,
            },
            status: 200
          })
        }

        notificationsToProcess = batchNotifications
      }

      const selectedCount = notificationsToProcess.length
      const notificationIds = notificationsToProcess.map(n => n.id).join(', ')
      console.log(`[${runId}] Notification IDs selected: ${notificationIds}`)
      console.log(`[${runId}] Processing ${selectedCount} notification(s)`)

      // Get Firebase access token once for all sends
      if (!SERVICE_ACCOUNT_KEY) {
        console.error('Firebase Service Account Key not configured')
        throw new Error('Firebase Service Account Key not configured')
      }

      const firebaseToken = await getFirebaseAccessToken()

      let processedCount = 0
      let sentSuccessCount = 0
      let sentFailedCount = 0
      let skippedMaxRetriesCount = 0
      let skippedCooldownCount = 0
      let skippedPreferencesCount = 0
      let missingTokenCount = 0

      // Process each notification
      for (const notification of notificationsToProcess) {
        try {
          // Re-check if notification was successfully delivered (concurrency safety)
          const { data: recentDelivery, error: checkError } = await supabase
            .from('notification_delivery_log')
            .select('id')
            .eq('notification_id', notification.id)
            .eq('success', true)
            .limit(1)
            .maybeSingle()

          if (checkError) {
            console.error(`[${runId}] Error checking delivery for notification ${notification.id}:`, checkError)
            continue
          }

          if (recentDelivery) {
            console.log(`[${runId}] Notification ${notification.id} already delivered, skipping`)
            continue
          }

          // Check retry controls: skip if max retries reached (>= 5)
          const maxRetryCount = (notification as any).max_retry_count || 0
          if (maxRetryCount >= 5) {
            console.log(`[${runId}] Notification ${notification.id}: skipped_max_retries (${maxRetryCount} attempts)`)
            skippedMaxRetriesCount++
            continue
          }

          // Check cooldown: skip if last attempt was within last 2 minutes
          const lastAttemptAt = (notification as any).last_attempt_at
          if (lastAttemptAt) {
            const lastAttemptTime = new Date(lastAttemptAt).getTime()
            const now = Date.now()
            const twoMinutesAgo = now - (2 * 60 * 1000)
            
            if (lastAttemptTime > twoMinutesAgo) {
              const secondsRemaining = Math.ceil((lastAttemptTime + (2 * 60 * 1000) - now) / 1000)
              console.log(`[${runId}] Notification ${notification.id}: skipped_cooldown (${secondsRemaining}s remaining)`)
              skippedCooldownCount++
              continue
            }
          }

          // Get user's FCM tokens and notification preferences
          const { data: profile, error: profileError } = await supabase
            .from('profiles')
            .select('fcm_token, fcm_token_web, display_name, notification_prefs')
            .eq('id', notification.user_id)
            .single()

          if (profileError) {
            console.error(`[${runId}] Error fetching profile for user ${notification.user_id}:`, profileError)
            
            // Log error to delivery log
            const { data: retryData } = await supabase
              .from('notification_delivery_log')
              .select('retry_count')
              .eq('notification_id', notification.id)
              .order('sent_at', { ascending: false })
              .limit(1)
              .maybeSingle()

            const nextRetryCount = (retryData?.retry_count || 0) + 1

            await supabase
              .from('notification_delivery_log')
              .insert({
                notification_id: notification.id,
                user_id: notification.user_id,
                sent_at: new Date().toISOString(),
                success: false,
                error_message: 'fcm_error',
                fcm_response: {
                  run_id: runId,
                  error: `Error fetching profile: ${profileError.message}`
                },
                retry_count: nextRetryCount
              })

            sentFailedCount++
            processedCount++
            continue
          }

          // Get all available tokens (web and/or mobile)
          const tokens: string[] = []
          if (profile?.fcm_token) {
            tokens.push(profile.fcm_token)
          }
          if (profile?.fcm_token_web) {
            tokens.push(profile.fcm_token_web)
          }

          if (tokens.length === 0) {
            console.log(`[${runId}] Notification ${notification.id}: missing_token`)
            missingTokenCount++
            
            // Log missing token to delivery log (unless dry_run)
            if (!dryRun) {
              const { data: retryData } = await supabase
                .from('notification_delivery_log')
                .select('retry_count')
                .eq('notification_id', notification.id)
                .order('sent_at', { ascending: false })
                .limit(1)
                .maybeSingle()

              const nextRetryCount = (retryData?.retry_count || 0) + 1

              await supabase
                .from('notification_delivery_log')
                .insert({
                  notification_id: notification.id,
                  user_id: notification.user_id,
                  sent_at: new Date().toISOString(),
                  success: false,
                  error_message: 'missing_fcm_token',
                  fcm_response: {
                    run_id: runId
                  },
                  retry_count: nextRetryCount
                })
            } else {
              console.log(`[${runId}] DRY RUN: Would log missing_token for notification ${notification.id}`)
            }

            processedCount++
            continue
          }

          // Check user's notification preferences
          const notificationType = notification.notification_type
          const prefs = profile?.notification_prefs as Record<string, boolean> | null

          if (prefs && prefs[notificationType] === false) {
            console.log(`[${runId}] Notification ${notification.id}: skipped_preferences (user disabled ${notificationType})`)
            skippedPreferencesCount++
            
            // Log preference skip (unless dry_run)
            if (!dryRun) {
              const { data: retryData } = await supabase
                .from('notification_delivery_log')
                .select('retry_count')
                .eq('notification_id', notification.id)
                .order('sent_at', { ascending: false })
                .limit(1)
                .maybeSingle()

              const nextRetryCount = (retryData?.retry_count || 0) + 1

              await supabase
                .from('notification_delivery_log')
                .insert({
                  notification_id: notification.id,
                  user_id: notification.user_id,
                  sent_at: new Date().toISOString(),
                  success: false,
                  error_message: 'skipped_preferences',
                  fcm_response: {
                    run_id: runId,
                    notification_type: notificationType
                  },
                  retry_count: nextRetryCount
                })
            } else {
              console.log(`[${runId}] DRY RUN: Would log skipped_preferences for notification ${notification.id}`)
            }

            processedCount++
            continue
          }

          console.log(`[${runId}] Processing notification ${notification.id} for user ${profile.display_name} (${tokens.length} token(s))`)

          // Send to all tokens (web and/or mobile)
          let notificationSuccess = false
          const fcmResults: any[] = []

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
                  action: getActionFromNotificationType(notification.notification_type),
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
              
              let fcmResult: any
              
              if (dryRun) {
                console.log(`[${runId}] DRY RUN: Would send FCM message to token: ${token.substring(0, 20)}...`)
                // Simulate success in dry run
                fcmResult = {
                  success: 1,
                  message_id: 'dry_run_simulated_id',
                  token: token.substring(0, 20) + '...',
                  run_id: runId
                }
                notificationSuccess = true
              } else {
                console.log(`[${runId}] Sending FCM message to token: ${token.substring(0, 20)}...`)
                
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
                
                if (responseText.startsWith('<')) {
                  // HTML response (error page)
                  console.error('FCM returned HTML error page for token:', token.substring(0, 20))
                  fcmResult = { 
                    error: 'FCM API returned HTML error page',
                    status: fcmResponse.status,
                    rawResponse: responseText.substring(0, 200) + '...',
                    token: token.substring(0, 20) + '...'
                  }
                } else {
                  try {
                    fcmResult = JSON.parse(responseText)
                    
                    if (fcmResult.error) {
                      console.error('FCM API error for token:', token.substring(0, 20), fcmResult.error)
                      fcmResult.error = fcmResult.error.message || fcmResult.error
                    } else {
                    if (fcmResult.name) {
                      fcmResult.success = 1
                      fcmResult.message_id = fcmResult.name.split('/').pop()
                      fcmResult.run_id = runId
                      console.log(`[${runId}] FCM notification sent successfully: ${fcmResult.message_id}`)
                      notificationSuccess = true
                    } else {
                      fcmResult.run_id = runId
                    }
                    }
                  } catch (parseError) {
                    console.error('Failed to parse FCM response:', parseError)
                    fcmResult = { 
                      error: 'Invalid JSON response from FCM',
                      rawResponse: responseText,
                      token: token.substring(0, 20) + '...'
                    }
                  }
                }
              }
              
              fcmResults.push(fcmResult)
            } catch (error) {
              console.error(`[${runId}] Error sending to token:`, token.substring(0, 20), error)
              fcmResults.push({
                error: error instanceof Error ? error.message : 'Unknown error',
                token: token.substring(0, 20) + '...',
                run_id: runId
              })
            }
          }

          // Log delivery attempt (unless dry_run with success - don't log success in dry_run)
          if (!dryRun || !notificationSuccess) {
            const { data: retryData } = await supabase
              .from('notification_delivery_log')
              .select('retry_count')
              .eq('notification_id', notification.id)
              .order('sent_at', { ascending: false })
              .limit(1)
              .maybeSingle()

            const nextRetryCount = (retryData?.retry_count || 0) + 1

            // Log delivery attempt (one row per notification, not per token)
            // Use the first token for fcm_token field if available
            // Add run_id to fcm_response metadata
            const fcmResponseWithMetadata = fcmResults.map(r => ({
              ...r,
              run_id: runId
            }))

            await supabase
              .from('notification_delivery_log')
              .insert({
                notification_id: notification.id,
                user_id: notification.user_id,
                fcm_token: tokens[0] || null,
                fcm_response: fcmResponseWithMetadata,
                sent_at: new Date().toISOString(),
                success: dryRun ? false : notificationSuccess, // Never log success=true in dry_run
                error_message: dryRun ? 'dry_run' : (notificationSuccess ? null : 'fcm_error'),
                retry_count: nextRetryCount
              })
          }

          if (notificationSuccess) {
            console.log(`[${runId}] Notification ${notification.id}: sent_success`)
            sentSuccessCount++
          } else {
            console.log(`[${runId}] Notification ${notification.id}: sent_failed`)
            sentFailedCount++
          }
          processedCount++

        } catch (error) {
          console.error(`[${runId}] Error processing notification ${notification.id}:`, error)
          
          // Log error to delivery log
          const { data: retryData } = await supabase
            .from('notification_delivery_log')
            .select('retry_count')
            .eq('notification_id', notification.id)
            .order('sent_at', { ascending: false })
            .limit(1)
            .maybeSingle()

          const nextRetryCount = (retryData?.retry_count || 0) + 1

          await supabase
            .from('notification_delivery_log')
            .insert({
              notification_id: notification.id,
              user_id: notification.user_id,
              sent_at: new Date().toISOString(),
              success: false,
              error_message: 'fcm_error',
              fcm_response: {
                run_id: runId,
                error: error instanceof Error ? error.message : 'Unknown error'
              },
              retry_count: nextRetryCount
            })

          sentFailedCount++
          processedCount++
        }
      }

      // Summary log line
      console.log(`[${runId}] SUMMARY: run_id=${runId}, mode=${mode}, dry_run=${dryRun}, selected_count=${selectedCount}, processed=${processedCount}, sent_success=${sentSuccessCount}, sent_failed=${sentFailedCount}, skipped_max_retries=${skippedMaxRetriesCount}, skipped_cooldown=${skippedCooldownCount}, skipped_preferences=${skippedPreferencesCount}, missing_token=${missingTokenCount}`)

      return new Response(JSON.stringify({
        success: true,
        run_id: runId,
        mode,
        selected_count: selectedCount,
        processed: processedCount,
        sent_success: sentSuccessCount,
        sent_failed: sentFailedCount,
        skipped_max_retries: skippedMaxRetriesCount,
        skipped_cooldown: skippedCooldownCount,
        skipped_preferences: skippedPreferencesCount,
        missing_token: missingTokenCount,
        dry_run: dryRun
      }), {
        headers: { 
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
        status: 200
      })

    } finally {
      // Release advisory lock
      try {
        await supabase.rpc('pg_advisory_unlock', {
          p_lock_key: lockKey
        })
      } catch (err) {
        console.error('Error releasing lock:', err)
      }
    }

  } catch (error) {
    console.error('=== POLLER ERROR ===')
    console.error('Error:', error)
    
    return new Response(JSON.stringify({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }), {
      headers: { 
        'Content-Type': 'application/json',
        ...corsHeaders,
      },
      status: 500
    })
  }
})

