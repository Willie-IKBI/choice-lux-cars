import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/features/notifications/services/notification_service.dart';
import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

class DriverFlowApiService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Start a job - marks the job as started and records the start time
  static Future<void> startJob(
    int jobId, {
    required double odoStartReading,
    required String pdpStartImage,
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
    String? vehicleCollectedAtTimestamp, // Optional: Use provided timestamp instead of generating new one
  }) async {
    try {
      Log.d('=== STARTING JOB ===');
      Log.d('Job ID: $jobId');

      // Get the driver and agent for this job to validate before update
      final jobResponse = await _supabase
          .from('jobs')
          .select('driver_id, client_id, agent_id, job_start_date')
          .eq('id', jobId)
          .single();

      final driverId = jobResponse['driver_id'];
      final agentId = jobResponse['agent_id'];
      final existingJobStartDate = jobResponse['job_start_date'];

      if (driverId == null) {
        throw Exception('No driver assigned to job $jobId');
      }

      // Validate agent_id exists (required by database NOT NULL constraint)
      if (agentId == null) {
        final errorMsg = 'Job $jobId cannot be started: Agent ID is missing. Please assign an agent to this job before starting it.';
        Log.e('Validation failed: $errorMsg');
        throw Exception(errorMsg);
      }

      // Prepare update payload - only update job_status if it's not already started
      // Only set job_start_date if it's not already set (immutable once set)
      final updatePayload = <String, dynamic>{
        'job_status': 'started',
        'updated_at': SATimeUtils.getCurrentSATimeISO(),
      };

      // Only update job_start_date if it's not already set
      if (existingJobStartDate == null) {
        updatePayload['job_start_date'] = SATimeUtils.getCurrentSATimeISO();
      }

      // Update job status to started
      await _supabase
          .from('jobs')
          .update(updatePayload)
          .eq('id', jobId);

      // Use provided timestamp or generate new one
      // This ensures timestamp is captured at user action time, not API call time
      final vehicleCollectedTimestamp = vehicleCollectedAtTimestamp ?? SATimeUtils.getCurrentSATimeISO();
      final currentTime = SATimeUtils.getCurrentSATimeISO();

      // Create driver_flow record
      await _supabase.from('driver_flow').upsert({
        'job_id': jobId,
        'driver_user': driverId,
        'current_step': 'pickup_arrival', // Advance to next step immediately
        'job_started_at': currentTime,
        'odo_start_reading': odoStartReading,
        'pdp_start_image': pdpStartImage,
        'vehicle_collected': true,
        'vehicle_collected_at': vehicleCollectedTimestamp, // Use captured timestamp
        'progress_percentage': 17,
        'last_activity_at': currentTime,
        'updated_at': currentTime,
      }, onConflict: 'job_id');

      Log.d('=== JOB STARTED SUCCESSFULLY ===');

      // Send notification
      try {
        final jobDetailsResponse = await _supabase
            .from('jobs')
            .select('passenger_name')
            .eq('id', jobId)
            .single();

        final clientResponse = await _supabase
            .from('clients')
            .select('company_name')
            .eq('id', jobResponse['client_id'])
            .single();

        final driverResponse = await _supabase
            .from('profiles')
            .select('display_name')
            .eq('id', driverId)
            .single();

        await NotificationService.sendJobStartNotification(
          jobId: jobId,
          driverName: driverResponse['display_name'] ?? 'Unknown Driver',
          clientName: clientResponse['company_name'] ?? 'Unknown Client',
          passengerName:
              jobDetailsResponse['passenger_name'] ?? 'Unknown Passenger',
          jobNumber: 'JOB-$jobId',
        );
      } catch (e) {
        Log.e('Warning: Could not send job start notification: $e');
      }
    } catch (e) {
      Log.e('=== ERROR STARTING JOB ===');
      Log.e('Error: $e');
      throw Exception('Failed to start job: $e');
    }
  }

  /// Record vehicle collection
  static Future<void> collectVehicle(
    int jobId, {
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
  }) async {
    try {
      Log.d('=== COLLECTING VEHICLE ===');
      Log.d('Job ID: $jobId');

      final jobResponse = await _supabase
          .from('jobs')
          .select('driver_id')
          .eq('id', jobId)
          .single();

      final driverId = jobResponse['driver_id'];
      if (driverId == null) {
        throw Exception('No driver assigned to job $jobId');
      }

      await _supabase
          .from('driver_flow')
          .update({
            'vehicle_collected': true,
            'vehicle_collected_at': SATimeUtils.getCurrentSATimeISO(),
            'current_step': 'pickup_arrival',
            'progress_percentage': 17,
            'last_activity_at': SATimeUtils.getCurrentSATimeISO(),
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
          .eq('job_id', jobId);

      Log.d('=== VEHICLE COLLECTION RECORDED ===');

      // Send notification
      try {
        final driverResponse = await _supabase
            .from('profiles')
            .select('display_name')
            .eq('id', driverId)
            .single();

        await NotificationService.sendStepCompletionNotification(
          jobId: jobId,
          stepName: 'vehicle_collection',
          driverName: driverResponse['display_name'] ?? 'Unknown Driver',
          jobNumber: 'JOB-$jobId',
        );
      } catch (e) {
        Log.e('Warning: Could not send step completion notification: $e');
      }
    } catch (e) {
      Log.e('=== ERROR COLLECTING VEHICLE ===');
      Log.e('Error: $e');
      throw Exception('Failed to record vehicle collection: $e');
    }
  }

  /// Record arrival at pickup location
  static Future<void> arriveAtPickup(
    int jobId,
    int tripIndex, {
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
  }) async {
    try {
      Log.d('=== ARRIVE AT PICKUP ===');
      Log.d('Job ID: $jobId, Trip Index: $tripIndex');

      final jobResponse = await _supabase
          .from('jobs')
          .select('driver_id')
          .eq('id', jobId)
          .single();

      final driverId = jobResponse['driver_id'];
      if (driverId == null) {
        throw Exception('No driver assigned to job $jobId');
      }

             // Update driver_flow table with all changes in one call
       // Set current_step to 'passenger_pickup' (intermediate step before passenger_onboard)
       // This creates the proper flow: pickup_arrival -> passenger_pickup -> passenger_onboard
       await _supabase
           .from('driver_flow')
           .update({
             'current_step': 'passenger_pickup', // Set to passenger_pickup to show intermediate step
             'progress_percentage': 33,
             'pickup_arrive_time': SATimeUtils.getCurrentSATimeISO(),
             'pickup_arrive_loc': 'GPS: $gpsLat, $gpsLng',
             'last_activity_at': SATimeUtils.getCurrentSATimeISO(),
             'updated_at': SATimeUtils.getCurrentSATimeISO(),
           })
           .eq('job_id', jobId);

      Log.d('=== ARRIVAL AT PICKUP RECORDED ===');

      // Send notification
      try {
        final driverResponse = await _supabase
            .from('profiles')
            .select('display_name')
            .eq('id', driverId)
            .single();

        await NotificationService.sendStepCompletionNotification(
          jobId: jobId,
          stepName: 'pickup_arrival',
          driverName: driverResponse['display_name'] ?? 'Unknown Driver',
          jobNumber: 'JOB-$jobId',
        );
      } catch (e) {
        Log.e('Warning: Could not send step completion notification: $e');
      }
    } catch (e) {
      Log.e('=== ERROR RECORDING PICKUP ARRIVAL ===');
      Log.e('Error: $e');
      throw Exception('Failed to record pickup arrival: $e');
    }
  }

  /// Record passenger onboard
  static Future<void> passengerOnboard(
    int jobId,
    int tripIndex, {
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
  }) async {
    try {
      Log.d('=== PASSENGER ONBOARD ===');
      Log.d('Job ID: $jobId, Trip Index: $tripIndex');

      final jobResponse = await _supabase
          .from('jobs')
          .select('driver_id')
          .eq('id', jobId)
          .single();

      final driverId = jobResponse['driver_id'];
      if (driverId == null) {
        throw Exception('No driver assigned to job $jobId');
      }

                   // Update driver_flow table with step progression and timestamp
      await _supabase
          .from('driver_flow')
          .update({
            'current_step': 'passenger_onboard',
            'progress_percentage': 50,
            'passenger_onboard_at': SATimeUtils.getCurrentSATimeISO(),
            'last_activity_at': SATimeUtils.getCurrentSATimeISO(),
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
          .eq('job_id', jobId);

      Log.d('=== PASSENGER ONBOARD RECORDED ===');
      
      // Force refresh of job progress data
      await getJobProgress(jobId);

      // Send notification - TEMPORARILY DISABLED FOR TESTING
      /*
      try {
        final driverResponse = await _supabase
            .from('profiles')
            .select('display_name')
            .eq('id', driverId)
            .single();

        await NotificationService.sendStepCompletionNotification(
          jobId: jobId,
          stepName: 'passenger_onboard',
          driverName: driverResponse['display_name'] ?? 'Unknown Driver',
          jobNumber: 'JOB-$jobId',
        );
      } catch (e) {
        Log.e('Warning: Could not send step completion notification: $e');
      }
      */
    } catch (e) {
      Log.e('=== ERROR RECORDING PASSENGER ONBOARD ===');
      Log.e('Error: $e');
      throw Exception('Failed to record passenger onboard: $e');
    }
  }

  /// Mark passenger as no-show
  static Future<void> markPassengerNoShow(
    int jobId,
    int tripIndex, {
    required String comment,
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
  }) async {
    try {
      Log.d('=== MARK PASSENGER NO-SHOW ===');
      Log.d('Job ID: $jobId, Trip Index: $tripIndex');
      Log.d('Comment: $comment');

      // Validate comment is not empty
      if (comment.trim().isEmpty) {
        throw Exception('Comment is required when marking passenger as no-show');
      }

      final jobResponse = await _supabase
          .from('jobs')
          .select('driver_id')
          .eq('id', jobId)
          .single();

      final driverId = jobResponse['driver_id'];
      if (driverId == null) {
        throw Exception('No driver assigned to job $jobId');
      }

      // Validate pickup arrival is completed (driver must have arrived first)
      final driverFlowResponse = await _supabase
          .from('driver_flow')
          .select('pickup_arrive_time')
          .eq('job_id', jobId)
          .maybeSingle();

      if (driverFlowResponse == null || driverFlowResponse['pickup_arrive_time'] == null) {
        throw Exception('Cannot mark no-show: Driver must arrive at pickup location first');
      }

      // Update trip_progress table to mark this trip as completed
      // This ensures the database trigger validates trips correctly
      await _supabase
          .from('trip_progress')
          .update({
            'status': 'completed',
            'completed_at': SATimeUtils.getCurrentSATimeISO(),
            'notes': comment,
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
          .eq('job_id', jobId)
          .eq('trip_index', tripIndex);

      Log.d('Trip $tripIndex marked as completed (no-show) in trip_progress');

      // Check if all trips are now completed
      final allTripsResponse = await _supabase
          .from('trip_progress')
          .select('status')
          .eq('job_id', jobId);

      final allTrips = allTripsResponse as List<dynamic>;
      final allTripsCompleted = allTrips.isNotEmpty && 
          allTrips.every((trip) => trip['status'] == 'completed');
      Log.d('Total trips: ${allTrips.length}, All trips completed: $allTripsCompleted');

      // Determine next step and prepare update payload (consistent with completeTrip logic)
      String nextStep;
      int progressPercentage;
      Map<String, dynamic> updatePayload = {
        'passenger_no_show_ind': true,
        'passenger_no_show_comment': comment.trim(),
        'passenger_no_show_at': SATimeUtils.getCurrentSATimeISO(),
        'transport_completed_ind': allTripsCompleted,
        'trip_complete_at': SATimeUtils.getCurrentSATimeISO(),
        'last_activity_at': SATimeUtils.getCurrentSATimeISO(),
        'updated_at': SATimeUtils.getCurrentSATimeISO(),
      };

      if (allTripsCompleted) {
        // All trips completed - advance to vehicle_return
        nextStep = 'vehicle_return';
        progressPercentage = 100;
        updatePayload['current_step'] = nextStep;
        updatePayload['progress_percentage'] = progressPercentage;
        Log.d('All trips completed (no-show), advancing to vehicle_return');
      } else {
        // More trips exist - reset flow to pickup_arrival for next trip (consistent with completeTrip)
        // Find next incomplete trip
        final nextIncompleteTrip = allTrips.firstWhere(
          (trip) => trip['status'] != 'completed',
          orElse: () => allTrips.last,
        );
        final nextTripIndex = nextIncompleteTrip['trip_index'] as int;
        
        nextStep = 'pickup_arrival';
        progressPercentage = 17; // Reset to pickup_arrival progress
        updatePayload['current_step'] = nextStep;
        updatePayload['progress_percentage'] = progressPercentage;
        // Clear trip-specific fields for the next trip (they'll be set when driver arrives at pickup)
        updatePayload['pickup_arrive_time'] = null;
        updatePayload['pickup_arrive_loc'] = null;
        updatePayload['passenger_onboard_at'] = null;
        updatePayload['dropoff_arrive_at'] = null;
        // Keep vehicle_collected = true (don't reset this)
        // Keep trip_complete_at (historical record)
        Log.d('More trips exist (no-show), resetting to pickup_arrival for trip $nextTripIndex');
      }

      // Update driver_flow table with all changes in one call
      await _supabase
          .from('driver_flow')
          .update(updatePayload)
          .eq('job_id', jobId);

      Log.d('=== PASSENGER NO-SHOW RECORDED ===');
      Log.d('Next step: $nextStep');
      Log.d('All trips completed: $allTripsCompleted');
      
      // Force refresh of job progress data
      await getJobProgress(jobId);
    } catch (e) {
      Log.e('=== ERROR MARKING PASSENGER NO-SHOW ===');
      Log.e('Error: $e');
      throw Exception('Failed to mark passenger as no-show: $e');
    }
  }

  /// Record arrival at dropoff location
  static Future<void> arriveAtDropoff(
    int jobId,
    int tripIndex, {
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
  }) async {
    try {
      Log.d('=== ARRIVE AT DROPOFF ===');
      Log.d('Job ID: $jobId, Trip Index: $tripIndex');

      final jobResponse = await _supabase
          .from('jobs')
          .select('driver_id')
          .eq('id', jobId)
          .single();

      final driverId = jobResponse['driver_id'];
      if (driverId == null) {
        throw Exception('No driver assigned to job $jobId');
      }

             // Update driver_flow table with all changes in one call
       await _supabase
           .from('driver_flow')
           .update({
             'current_step': 'trip_complete', // Advance to next step (trip_complete)
             'progress_percentage': 67,
             // Note: transport_completed_ind is set in completeTrip(), not here
             'dropoff_arrive_at': SATimeUtils.getCurrentSATimeISO(),
             'last_activity_at': SATimeUtils.getCurrentSATimeISO(),
             'updated_at': SATimeUtils.getCurrentSATimeISO(),
           })
           .eq('job_id', jobId);

      Log.d('=== ARRIVAL AT DROPOFF RECORDED ===');

      // Send notification
      try {
        final driverResponse = await _supabase
            .from('profiles')
            .select('display_name')
            .eq('id', driverId)
            .single();

        await NotificationService.sendStepCompletionNotification(
          jobId: jobId,
          stepName: 'dropoff_arrival',
          driverName: driverResponse['display_name'] ?? 'Unknown Driver',
          jobNumber: 'JOB-$jobId',
        );
      } catch (e) {
        Log.e('Warning: Could not send step completion notification: $e');
      }
    } catch (e) {
      Log.e('=== ERROR RECORDING DROPOFF ARRIVAL ===');
      Log.e('Error: $e');
      throw Exception('Failed to record dropoff arrival: $e');
    }
  }

  /// Complete a trip
  static Future<void> completeTrip(
    int jobId,
    int tripIndex, {
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
  }) async {
    try {
      Log.d('=== COMPLETE TRIP ===');
      Log.d('Job ID: $jobId, Trip Index: $tripIndex');

      final jobResponse = await _supabase
          .from('jobs')
          .select('driver_id')
          .eq('id', jobId)
          .single();

      final driverId = jobResponse['driver_id'];
      if (driverId == null) {
        throw Exception('No driver assigned to job $jobId');
      }

      // Update trip_progress table to mark this specific trip as completed
      // This is required for the database trigger that validates all trips are completed before closing job
      final updateResponse = await _supabase
          .from('trip_progress')
          .update({
            'status': 'completed',
            'completed_at': SATimeUtils.getCurrentSATimeISO(),
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
          .eq('job_id', jobId)
          .eq('trip_index', tripIndex)
          .select();

      if (updateResponse.isEmpty) {
        Log.e('Error: trip_progress record not found for job $jobId, trip $tripIndex');
        throw Exception('Trip progress record not found for trip $tripIndex. Cannot complete trip.');
      }

      Log.d('Trip $tripIndex marked as completed in trip_progress (${updateResponse.length} record(s) updated)');

      // Check if all trips are now completed
      final allTripsResponse = await _supabase
          .from('trip_progress')
          .select('status, trip_index')
          .eq('job_id', jobId)
          .order('trip_index', ascending: true);

      final allTrips = allTripsResponse as List<dynamic>;
      final allTripsCompleted = allTrips.isNotEmpty && 
          allTrips.every((trip) => trip['status'] == 'completed');
      Log.d('Total trips: ${allTrips.length}, All trips completed: $allTripsCompleted');

      // Determine next step and prepare update payload
      String nextStep;
      int progressPercentage;
      Map<String, dynamic> updatePayload = {
        'transport_completed_ind': allTripsCompleted, // Only set to true if all trips are completed
        'trip_complete_at': SATimeUtils.getCurrentSATimeISO(),
        'last_activity_at': SATimeUtils.getCurrentSATimeISO(),
        'updated_at': SATimeUtils.getCurrentSATimeISO(),
      };

      if (allTripsCompleted) {
        // All trips completed - advance to vehicle_return
        nextStep = 'vehicle_return';
        progressPercentage = 100;
        updatePayload['current_step'] = nextStep;
        updatePayload['progress_percentage'] = progressPercentage;
        Log.d('All trips completed, advancing to vehicle_return');
      } else {
        // More trips exist - reset flow to pickup_arrival for next trip
        // Find next incomplete trip
        final nextIncompleteTrip = allTrips.firstWhere(
          (trip) => trip['status'] != 'completed',
          orElse: () => allTrips.last,
        );
        final nextTripIndex = nextIncompleteTrip['trip_index'] as int;
        
        nextStep = 'pickup_arrival';
        progressPercentage = 17; // Reset to pickup_arrival progress
        updatePayload['current_step'] = nextStep;
        updatePayload['progress_percentage'] = progressPercentage;
        // Clear trip-specific fields for the next trip (they'll be set when driver arrives at pickup)
        updatePayload['pickup_arrive_time'] = null;
        updatePayload['pickup_arrive_loc'] = null;
        updatePayload['passenger_onboard_at'] = null;
        updatePayload['dropoff_arrive_at'] = null;
        // Keep vehicle_collected = true (don't reset this)
        // Keep trip_complete_at (historical record)
        Log.d('More trips exist, resetting to pickup_arrival for trip $nextTripIndex');
      }

      // Update driver_flow table with all changes in one call
      await _supabase
          .from('driver_flow')
          .update(updatePayload)
          .eq('job_id', jobId);

      Log.d('=== TRIP COMPLETED ===');

      // Send notification
      try {
        final driverResponse = await _supabase
            .from('profiles')
            .select('display_name')
            .eq('id', driverId)
            .single();

        await NotificationService.sendStepCompletionNotification(
          jobId: jobId,
          stepName: 'trip_complete',
          driverName: driverResponse['display_name'] ?? 'Unknown Driver',
          jobNumber: 'JOB-$jobId',
        );
      } catch (e) {
        Log.e('Warning: Could not send step completion notification: $e');
      }
    } catch (e) {
      Log.e('=== ERROR COMPLETING TRIP ===');
      Log.e('Error: $e');
      throw Exception('Failed to complete trip: $e');
    }
  }

  /// Return vehicle
  static Future<void> returnVehicle(
    int jobId, {
    required double odoEndReading,
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
  }) async {
    try {
      Log.d('=== RETURN VEHICLE ===');
      Log.d('Job ID: $jobId');

      final jobResponse = await _supabase
          .from('jobs')
          .select('driver_id')
          .eq('id', jobId)
          .single();

      final driverId = jobResponse['driver_id'];
      if (driverId == null) {
        throw Exception('No driver assigned to job $jobId');
      }

             await _supabase
           .from('driver_flow')
           .update({
             'job_closed_time': SATimeUtils.getCurrentSATimeISO(),
             'job_closed_odo': odoEndReading,
             'current_step': 'vehicle_return',
             'progress_percentage': 100,
             'last_activity_at': SATimeUtils.getCurrentSATimeISO(),
             'updated_at': SATimeUtils.getCurrentSATimeISO(),
           })
           .eq('job_id', jobId);

      Log.d('=== VEHICLE RETURNED ===');

      // Send notification
      try {
        final driverResponse = await _supabase
            .from('profiles')
            .select('display_name')
            .eq('id', driverId)
            .single();

        await NotificationService.sendStepCompletionNotification(
          jobId: jobId,
          stepName: 'vehicle_return',
          driverName: driverResponse['display_name'] ?? 'Unknown Driver',
          jobNumber: 'JOB-$jobId',
        );
      } catch (e) {
        Log.e('Warning: Could not send step completion notification: $e');
      }
    } catch (e) {
      Log.e('=== ERROR RETURNING VEHICLE ===');
      Log.e('Error: $e');
      throw Exception('Failed to return vehicle: $e');
    }
  }

  /// Update job status to completed
  static Future<void> updateJobStatusToCompleted(int jobId) async {
    try {
      Log.d('=== UPDATING JOB STATUS TO COMPLETED ===');
      Log.d('Job ID: $jobId');

      await _supabase
          .from('jobs')
          .update({
            'job_status': 'completed',
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
          .eq('id', jobId);

      Log.d('Job status updated to completed');
      Log.d('=== JOB STATUS UPDATE COMPLETED ===');
    } catch (e) {
      Log.e('=== ERROR UPDATING JOB STATUS ===');
      Log.e('Error: $e');
      throw Exception('Failed to update job status: $e');
    }
  }

  /// Close a job
  static Future<void> closeJob(int jobId) async {
    try {
      Log.d('=== CLOSING JOB ===');
      Log.d('Job ID: $jobId');

      // Get the driver and agent for this job to validate before update
      final jobResponse = await _supabase
          .from('jobs')
          .select('driver_id, agent_id, job_status')
          .eq('id', jobId)
          .single();

      final driverId = jobResponse['driver_id'];
      final agentId = jobResponse['agent_id'];
      final currentStatus = jobResponse['job_status'];

      Log.d('Current job status: $currentStatus');
      Log.d('Agent ID: $agentId');
      Log.d('Driver ID: $driverId');

      // Validate agent_id exists (required by database NOT NULL constraint)
      if (agentId == null) {
        final errorMsg = 'Job $jobId cannot be closed: Agent ID is missing. Please assign an agent to this job before closing it.';
        Log.e('Validation failed: $errorMsg');
        throw Exception(errorMsg);
      }

      // Validate vehicle has been returned (job_closed_odo should be set)
      final driverFlowResponse = await _supabase
          .from('driver_flow')
          .select('job_closed_odo, transport_completed_ind')
          .eq('job_id', jobId)
          .maybeSingle();

      if (driverFlowResponse == null) {
        final errorMsg = 'Job $jobId cannot be closed: Driver flow record not found. Please return the vehicle first.';
        Log.e('Validation failed: $errorMsg');
        throw Exception(errorMsg);
      }

      final jobClosedOdo = driverFlowResponse['job_closed_odo'];
      if (jobClosedOdo == null) {
        final errorMsg = 'Job $jobId cannot be closed: Vehicle has not been returned. Please return the vehicle first.';
        Log.e('Validation failed: $errorMsg');
        throw Exception(errorMsg);
      }

      // Validate all trips are completed
      final tripProgressResponse = await _supabase
          .from('trip_progress')
          .select('status')
          .eq('job_id', jobId);

      final allTrips = tripProgressResponse as List<dynamic>;
      
      if (allTrips.isEmpty) {
        Log.d('Warning: No trip_progress records found for job $jobId. Job may not have any trips.');
      } else {
        final incompleteTrips = allTrips.where((trip) => trip['status'] != 'completed').toList();
        if (incompleteTrips.isNotEmpty) {
          final errorMsg = 'Job $jobId cannot be closed: Not all trips are completed. Please complete all trips before closing the job.';
          Log.e('Validation failed: $errorMsg');
          Log.e('Total trips: ${allTrips.length}, Incomplete trips: ${incompleteTrips.length}');
          throw Exception(errorMsg);
        }
        Log.d('Trip validation passed: All ${allTrips.length} trip(s) are completed');
      }

      // Update job status to completed
      // Only update these two fields to avoid triggering any validation issues
      try {
        await _supabase
            .from('jobs')
            .update({
              'job_status': 'completed',
              'updated_at': SATimeUtils.getCurrentSATimeISO(),
            })
            .eq('id', jobId);
        
        Log.d('Job status updated to completed successfully');
      } catch (updateError) {
        Log.e('Error updating job status: $updateError');
        Log.e('Update payload: {job_status: completed, updated_at: ${SATimeUtils.getCurrentSATimeISO()}}');
        rethrow;
      }

      // Update driver_flow to mark as completed
      await _supabase
          .from('driver_flow')
          .update({
            'current_step': 'completed',
            'progress_percentage': 100,
            'last_activity_at': SATimeUtils.getCurrentSATimeISO(),
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
          .eq('job_id', jobId);

      Log.d('Job closed successfully');
      Log.d('=== JOB CLOSED ===');

      // Send job completion notification
      try {
        final jobDetailsResponse = await _supabase
            .from('jobs')
            .select('passenger_name, job_number, client_id')
            .eq('id', jobId)
            .single();

        final driverResponse = await _supabase
            .from('profiles')
            .select('display_name')
            .eq('id', driverId)
            .single();

        final clientResponse = await _supabase
            .from('clients')
            .select('company_name')
            .eq('id', jobDetailsResponse['client_id'])
            .single();

        await NotificationService.sendJobCompletionNotification(
          jobId: jobId,
          driverName: driverResponse['display_name'] ?? 'Unknown Driver',
          clientName: clientResponse['company_name'] ?? 'Unknown Client',
          passengerName:
              jobDetailsResponse['passenger_name'] ?? 'Unknown Passenger',
          jobNumber: 'JOB-$jobId',
        );
      } catch (e) {
        Log.e('Warning: Could not send job completion notification: $e');
      }
    } catch (e) {
      Log.e('=== ERROR CLOSING JOB ===');
      Log.e('Error: $e');
      throw Exception('Failed to close job: $e');
    }
  }

  /// Get job addresses for pickup and dropoff from trips
  static Future<Map<String, String?>> getJobAddresses(int jobId) async {
    try {
      Log.d('=== GETTING JOB ADDRESSES ===');
      Log.d('Job ID: $jobId');

      // First try to get addresses from trips (most accurate)
      final tripsResponse = await _supabase
          .from('transport')
          .select('pickup_location, dropoff_location')
          .eq('job_id', jobId)
          .limit(1)
          .maybeSingle();

      String? pickupAddress;
      String? dropoffAddress;

      if (tripsResponse != null) {
        // Use actual trip addresses
        pickupAddress = tripsResponse['pickup_location']?.toString();
        dropoffAddress = tripsResponse['dropoff_location']?.toString();
        Log.d('Found trip addresses - Pickup: $pickupAddress, Dropoff: $dropoffAddress');
      } else {
        // Fallback to job location if no trips found
        final jobResponse = await _supabase
            .from('jobs')
            .select('location')
            .eq('id', jobId)
            .maybeSingle();

        if (jobResponse != null) {
          pickupAddress = jobResponse['location']?.toString();
          dropoffAddress = jobResponse['location']?.toString();
          Log.d('Using job location fallback: $pickupAddress');
        }
      }

      final addresses = {'pickup': pickupAddress, 'dropoff': dropoffAddress};

      Log.d('Final job addresses: $addresses');
      return addresses;
    } catch (e) {
      Log.e('=== ERROR GETTING JOB ADDRESSES ===');
      Log.e('Error: $e');
      return {'pickup': null, 'dropoff': null};
    }
  }

  /// Update the current step in the driver_flow table
  static Future<void> updateCurrentStep(int jobId, String currentStep) async {
    try {
      Log.d('Updating current step for job $jobId to: $currentStep');
      
      await _supabase
          .from('driver_flow')
          .update({
            'current_step': currentStep,
            'last_activity_at': SATimeUtils.getCurrentSATimeISO(),
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
          .eq('job_id', jobId);
      
      Log.d('Successfully updated current step for job $jobId');
    } catch (e) {
      Log.e('Error updating current step for job $jobId: $e');
      throw Exception('Failed to update current step: $e');
    }
  }

  /// Static wrapper for job progress
  static Future<Map<String, dynamic>?> getJobProgress(int jobId) async {
    try {
      Log.d('Getting job progress for job ID: $jobId');
      
      // Query driver_flow table for this job - use maybeSingle() since there should be at most one record per job
      final response = await _supabase
          .from('driver_flow')
          .select()
          .eq('job_id', jobId)
          .maybeSingle(); // Returns single row or null if not found
      
      if (response == null) {
        Log.d('No driver flow record found for job $jobId');
        return null;
      }
      
      Log.d('Found job progress: $response');
      return response;
    } catch (e) {
      Log.e('Error getting job progress: $e');
      return null;
    }
  }

  /// Static wrapper for trip progress
  /// Returns all trips from trip_progress table for the given job
  static Future<List<Map<String, dynamic>>> getTripProgress(int jobId) async {
    try {
      Log.d('Getting trip progress for job ID: $jobId');
      
      // Query trip_progress table to get all trips for this job
      final response = await _supabase
          .from('trip_progress')
          .select()
          .eq('job_id', jobId)
          .order('trip_index', ascending: true);
      
      if (response.isEmpty) {
        Log.d('No trip progress records found for job $jobId');
        return [];
      }
      
      Log.d('Found ${response.length} trip(s) for job $jobId');
      for (var trip in response) {
        Log.d('Trip ${trip['trip_index']}: status = ${trip['status']}');
      }
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Log.e('Error getting trip progress: $e');
      return [];
    }
  }

  /// Get active jobs for monitoring
  static Future<List<Map<String, dynamic>>> getActiveJobsForMonitoring() async {
    try {
      Log.d('Getting active jobs for monitoring');
      
      final response = await _supabase
          .from('jobs')
          .select('*')
          .inFilter('status', ['assigned', 'started', 'in_progress'])
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Log.e('Error getting active jobs: $e');
      return [];
    }
  }

  /// Get driver activity summary
  static Future<Map<String, dynamic>> getDriverActivitySummary() async {
    try {
      Log.d('Getting driver activity summary');
      
      // Get total drivers
      final driversResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('role', 'driver');
      
      // Get active drivers (with active jobs)
      final activeJobsResponse = await _supabase
          .from('jobs')
          .select('driver_id')
          .inFilter('status', ['assigned', 'started', 'in_progress']);
      
      final activeDriverIds = activeJobsResponse
          .map((job) => job['driver_id'])
          .toSet()
          .toList();
      
      return {
        'total_drivers': driversResponse.length,
        'active_drivers': activeDriverIds.length,
        'inactive_drivers': driversResponse.length - activeDriverIds.length,
      };
    } catch (e) {
      Log.e('Error getting driver activity summary: $e');
      return {
        'total_drivers': 0,
        'active_drivers': 0,
        'inactive_drivers': 0,
      };
    }
  }
}
