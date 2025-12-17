import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
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
    console.log('=== CHECKING JOB START DEADLINES ===')
    
    // Initialize Supabase client with service role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get current UTC time (database function will convert to SA time internally)
    const now = new Date()
    console.log('Current UTC time:', now.toISOString())

    // Find jobs that need notifications
    // Query: Get jobs with earliest pickup_date from transport table
    // Check if job_started_at is NULL in driver_flow
    // Filter by job_status (exclude cancelled/completed)
    // Check if we're 90 minutes before or 30 minutes before pickup
    
    const { data: jobsNeedingNotifications, error: queryError } = await supabase
      .rpc('get_jobs_needing_start_deadline_notifications', {
        p_current_time: now.toISOString()
      })

    if (queryError) {
      console.error('Error querying jobs:', queryError)
      throw queryError
    }

    if (!jobsNeedingNotifications || jobsNeedingNotifications.length === 0) {
      console.log('No jobs needing deadline notifications')
      return new Response(JSON.stringify({
        success: true,
        message: 'No jobs needing notifications',
        checked: 0,
        notified: 0
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      })
    }

    console.log(`Found ${jobsNeedingNotifications.length} jobs needing notifications`)

    let notifiedCount = 0
    const errors: string[] = []

    for (const job of jobsNeedingNotifications) {
      try {
        const { notification_type, recipient_role, job_id, job_number, driver_name, minutes_before } = job
        
        console.log(`Processing job ${job_id}: ${notification_type} for ${recipient_role} (${minutes_before} min before pickup)`)

        // Check if notification already sent (deduplication)
        const { data: existingNotification, error: checkError } = await supabase
          .from('app_notifications')
          .select('id')
          .eq('job_id', job_id.toString())
          .eq('notification_type', notification_type)
          .maybeSingle()

        if (checkError && checkError.code !== 'PGRST116') { // PGRST116 = no rows found
          console.error(`Error checking existing notification for job ${job_id}:`, checkError)
          errors.push(`Job ${job_id}: ${checkError.message}`)
          continue
        }

        if (existingNotification) {
          console.log(`Notification already sent for job ${job_id} (${notification_type}), skipping`)
          continue
        }

        // Get all users with the target role (including notification preferences)
        // For administrator role, also include super_admin
        const rolesToQuery = recipient_role === 'administrator' 
          ? ['administrator', 'super_admin']
          : [recipient_role]
        
        const { data: recipients, error: recipientsError } = await supabase
          .from('profiles')
          .select('id, role, notification_prefs')
          .in('role', rolesToQuery)
          .eq('status', 'active')

        if (recipientsError) {
          console.error(`Error fetching recipients for job ${job_id}:`, recipientsError)
          errors.push(`Job ${job_id}: ${recipientsError.message}`)
          continue
        }

        if (!recipients || recipients.length === 0) {
          console.log(`No active ${recipient_role} users found for job ${job_id}`)
          continue
        }

        const message = `Warning job# ${job_number} has not started with the driver ${driver_name || 'assigned'}`

        // Create notifications for all recipients
        for (const recipient of recipients) {
          const { data: notification, error: insertError } = await supabase
            .from('app_notifications')
            .insert({
              user_id: recipient.id,
              message: message,
              notification_type: notification_type,
              job_id: job_id.toString(),
              priority: 'high',
              action_data: {
                route: `/jobs/${job_id}/summary`,
                job_id: job_id.toString(),
                job_number: job_number,
                driver_name: driver_name,
                minutes_before_pickup: minutes_before,
              },
              created_at: now.toISOString(),
              updated_at: now.toISOString(),
            })
            .select()
            .single()

          if (insertError) {
            console.error(`Error creating notification for user ${recipient.id}:`, insertError)
            errors.push(`Job ${job_id}, User ${recipient.id}: ${insertError.message}`)
            continue
          }

          // Check user preferences before sending push notification
          const prefs = recipient.notification_prefs as Record<string, boolean> | null
          const pushEnabled = prefs?.[notification_type] !== false // Default to true if not set
          
          if (pushEnabled) {
            // Trigger push notification via webhook (existing push-notifications Edge Function)
            try {
              await supabase.functions.invoke('push-notifications', {
                body: {
                  'type': 'INSERT',
                  'table': 'app_notifications',
                  'record': notification,
                  'schema': 'public',
                  'old_record': null,
                },
              })
              notifiedCount++
            } catch (pushError) {
              console.error(`Error sending push notification for job ${job_id}:`, pushError)
              // Don't fail the whole process if push fails
            }
          } else {
            console.log(`Push notification skipped for user ${recipient.id} - ${notification_type} disabled`)
          }
        }

        console.log(`Successfully notified ${recipients.length} ${recipient_role} users for job ${job_id}`)

      } catch (jobError) {
        console.error(`Error processing job ${job.id}:`, jobError)
        errors.push(`Job ${job.id}: ${jobError instanceof Error ? jobError.message : 'Unknown error'}`)
      }
    }

    console.log('=== DEADLINE CHECK COMPLETE ===')
    console.log(`Jobs checked: ${jobsNeedingNotifications.length}`)
    console.log(`Notifications sent: ${notifiedCount}`)
    if (errors.length > 0) {
      console.error(`Errors: ${errors.length}`, errors)
    }

    return new Response(JSON.stringify({
      success: true,
      checked: jobsNeedingNotifications.length,
      notified: notifiedCount,
      errors: errors.length > 0 ? errors : undefined
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200
    })

  } catch (error) {
    console.error('=== ERROR IN DEADLINE CHECK ===')
    console.error('Error:', error)
    
    return new Response(JSON.stringify({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500
    })
  }
})

