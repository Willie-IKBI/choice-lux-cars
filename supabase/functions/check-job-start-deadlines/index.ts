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
    // Check if we're 90 minutes before (manager) or 60 minutes before (administrator) pickup
    
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
        const { notification_type, recipient_role, job_id, job_number, driver_name, manager_id, minutes_before } = job
        
        console.log(`Processing job ${job_id}: notification_type=${notification_type}, recipient_role=${recipient_role}, minutes_before=${minutes_before}`)
        
        // Note: RPC already filters by job_started_at IS NULL, so jobs returned here are guaranteed to be not started
        // If a job has started, it won't be in jobsNeedingNotifications

        // Get recipients based on role
        let recipients: any[] = []
        let recipientsError: any = null

        if (recipient_role === 'manager') {
          // Manager notification: ONLY the assigned manager for this job
          if (!manager_id) {
            console.log(`Job ${job_id}: manager_id is null, skipping manager notification`)
            continue
          }
          
          console.log(`Job ${job_id}: manager scoped recipient: ${manager_id}`)
          
          const { data: managerProfile, error: managerError } = await supabase
            .from('profiles')
            .select('id, role, notification_prefs')
            .eq('id', manager_id)
            .eq('role', 'manager')  // Defense-in-depth: verify role
            .eq('status', 'active')
            .maybeSingle()

          if (managerError) {
            console.error(`Error fetching manager ${manager_id} for job ${job_id}:`, managerError)
            errors.push(`Job ${job_id}: ${managerError.message}`)
            continue
          }

          if (!managerProfile) {
            console.log(`Manager ${manager_id} not found or not active for job ${job_id}`)
            continue
          }

          recipients = [managerProfile]
        } else if (recipient_role === 'administrator') {
          // Administrator escalation: ALL active administrators + super_admins globally
          // No branch_id filtering - global scope for admins
          const { data: adminRecipients, error: adminError } = await supabase
            .from('profiles')
            .select('id, role, notification_prefs')
            .in('role', ['administrator', 'super_admin'])
            .eq('status', 'active')

          recipientsError = adminError
          recipients = adminRecipients || []
          
          // Log recipient counts by role for observability
          if (recipients && recipients.length > 0) {
            const adminCount = recipients.filter(r => r.role === 'administrator').length
            const superAdminCount = recipients.filter(r => r.role === 'super_admin').length
            const totalCount = recipients.length
            console.log(`Job ${job_id}: admin escalation recipients: admins=${adminCount}, super_admins=${superAdminCount}, total=${totalCount}`)
          } else {
            console.log(`Job ${job_id}: No active administrators or super_admins found`)
          }
        } else {
          console.error(`Unknown recipient_role: ${recipient_role} for job ${job_id}`)
          errors.push(`Job ${job_id}: Unknown recipient_role ${recipient_role}`)
          continue
        }

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
        const jobIdString = job_id.toString().trim() // Consistent casting: job_id is bigint, stored as text, normalized

        // Create notifications for all recipients (with per-recipient deduplication)
        for (const recipient of recipients) {
          // Check if notification already sent for this specific recipient (deduplication)
          const { data: existingNotification, error: checkError } = await supabase
            .from('app_notifications')
            .select('id')
            .eq('job_id', jobIdString)
            .eq('notification_type', notification_type)
            .eq('user_id', recipient.id)
            .eq('is_hidden', false)
            .maybeSingle()

          if (checkError && checkError.code !== 'PGRST116') { // PGRST116 = no rows found
            console.error(`Error checking existing notification for job ${job_id}, user ${recipient.id}:`, checkError)
            errors.push(`Job ${job_id}, User ${recipient.id}: ${checkError.message}`)
            continue
          }

          if (existingNotification) {
            console.log(`dedupe hit: job=${job_id} user=${recipient.id} type=${notification_type}`)
            continue
          }

          // Insert notification (unique constraint will catch race conditions)
          const { data: notification, error: insertError } = await supabase
            .from('app_notifications')
            .insert({
              user_id: recipient.id,
              message: message,
              notification_type: notification_type,
              job_id: jobIdString,
              priority: 'high',
              action_data: {
                route: `/jobs/${job_id}/summary`,
                job_id: jobIdString,
                job_number: job_number,
                driver_name: driver_name,
                minutes_before_pickup: minutes_before,
              },
              created_at: now.toISOString(),
              updated_at: now.toISOString(),
            })
            .select('id,user_id,job_id,notification_type,message,priority,action_data,created_at')
            .single()

          if (insertError) {
            // Handle unique constraint violation as "already exists" (race condition)
            if (insertError.code === '23505') { // unique_violation
              console.log(`dedupe hit (unique index): job=${job_id} user=${recipient.id} type=${notification_type}`)
              continue
            }
            
            console.error(`Error creating notification for user ${recipient.id}:`, insertError)
            errors.push(`Job ${job_id}, User ${recipient.id}: ${insertError.message}`)
            continue
          }

          if (!notification) {
            console.error(`Notification insert succeeded but no data returned for job ${job_id}, user ${recipient.id}`)
            errors.push(`Job ${job_id}, User ${recipient.id}: Insert succeeded but no notification data returned`)
            continue
          }

          // Only invoke push notification after successful insert
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

