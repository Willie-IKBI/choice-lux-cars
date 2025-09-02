import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/features/notifications/services/notification_service.dart';
import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

class DriverFlowApiService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Start a job - marks the job as started and records the start time
  static Future<void> startJob(int jobId, {
    required double odoStartReading,
    required String pdpStartImage,
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
  }) async {
    try {
      Log.d('=== STARTING JOB ===');
      Log.d('Job ID: $jobId');
      
      // Get the driver for this job
      final jobResponse = await _supabase
          .from('jobs')
          .select('driver_id, client_id')
          .eq('id', jobId)
          .single();
      
      final driverId = jobResponse['driver_id'];
      if (driverId == null) {
        throw Exception('No driver assigned to job $jobId');
      }
      
      // Update job status to started
      await _supabase
          .from('jobs')
          .update({
            'job_status': 'started',
            'job_start_date': SATimeUtils.getCurrentSATimeISO(),
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
          .eq('id', jobId);
      
      // Create driver_flow record
      await _supabase
          .from('driver_flow')
          .upsert({
            'job_id': jobId,
            'driver_user': driverId,
            'current_step': 'pickup_arrival',
            'job_started_at': SATimeUtils.getCurrentSATimeISO(),
            'odo_start_reading': odoStartReading,
            'pdp_start_image': pdpStartImage,
            'vehicle_collected': true,
            'vehicle_collected_at': SATimeUtils.getCurrentSATimeISO(),
            'progress_percentage': 17,
            'last_activity_at': SATimeUtils.getCurrentSATimeISO(),
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
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
          passengerName: jobDetailsResponse['passenger_name'] ?? 'Unknown Passenger',
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
  static Future<void> collectVehicle(int jobId, {
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
  static Future<void> arriveAtPickup(int jobId, int tripIndex, {
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
      
      await _supabase
          .from('driver_flow')
          .update({
            'current_step': 'passenger_pickup',
            'progress_percentage': 33,
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
  static Future<void> passengerOnboard(int jobId, int tripIndex, {
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
      
      await _supabase
          .from('driver_flow')
          .update({
            'current_step': 'en_route',
            'progress_percentage': 50,
            'last_activity_at': SATimeUtils.getCurrentSATimeISO(),
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
          .eq('job_id', jobId);
      
      Log.d('=== PASSENGER ONBOARD RECORDED ===');
      
      // Send notification
      try {
        final driverResponse = await _supabase
            .from('profiles')
            .select('display_name')
            .eq('id', driverId)
            .single();
        
        await NotificationService.sendStepCompletionNotification(
          jobId: jobId,
          stepName: 'passenger_pickup',
          driverName: driverResponse['display_name'] ?? 'Unknown Driver',
          jobNumber: 'JOB-$jobId',
        );
      } catch (e) {
        Log.e('Warning: Could not send step completion notification: $e');
      }
    } catch (e) {
      Log.e('=== ERROR RECORDING PASSENGER ONBOARD ===');
      Log.e('Error: $e');
      throw Exception('Failed to record passenger onboard: $e');
    }
  }

  /// Record arrival at dropoff location
  static Future<void> arriveAtDropoff(int jobId, int tripIndex, {
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
      
      await _supabase
          .from('driver_flow')
          .update({
            'current_step': 'passenger_dropoff',
            'progress_percentage': 67,
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
  static Future<void> completeTrip(int jobId, int tripIndex, {
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
      
      await _supabase
          .from('driver_flow')
          .update({
            'current_step': 'return_vehicle',
            'progress_percentage': 83,
            'last_activity_at': SATimeUtils.getCurrentSATimeISO(),
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
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
          stepName: 'trip_completion',
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
  static Future<void> returnVehicle(int jobId, {
    required double odoEndReading,
    required String pdpEndImage,
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
            'vehicle_returned': true,
            'vehicle_returned_at': SATimeUtils.getCurrentSATimeISO(),
            'current_step': 'completed',
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
      
      // Get the driver for this job
      final jobResponse = await _supabase
          .from('jobs')
          .select('driver_id')
          .eq('id', jobId)
          .single();
      
      final driverId = jobResponse['driver_id'];
      
      // Update job status to completed
      await _supabase
          .from('jobs')
          .update({
            'job_status': 'completed',
            'updated_at': SATimeUtils.getCurrentSATimeISO(),
          })
          .eq('id', jobId);
      
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
          passengerName: jobDetailsResponse['passenger_name'] ?? 'Unknown Passenger',
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

  /// Get job addresses for pickup and dropoff
  static Future<Map<String, String?>> getJobAddresses(int jobId) async {
    try {
      Log.d('=== GETTING JOB ADDRESSES ===');
      Log.d('Job ID: $jobId');
      
      // Get transport details for this job
      final transportResponse = await _supabase
          .from('transport')
          .select('pickup_location, dropoff_location')
          .eq('job_id', jobId)
          .maybeSingle();
      
      String? pickupAddress;
      String? dropoffAddress;
      
      if (transportResponse != null) {
        pickupAddress = transportResponse['pickup_location']?.toString();
        dropoffAddress = transportResponse['dropoff_location']?.toString();
      }
      
      // Fallback to job location if no transport details
      if (pickupAddress == null || pickupAddress.isEmpty) {
        final jobResponse = await _supabase
            .from('jobs')
            .select('location')
            .eq('id', jobId)
            .maybeSingle();
        
        if (jobResponse != null) {
          pickupAddress = jobResponse['location']?.toString();
        }
      }
      
      final addresses = {
        'pickup': pickupAddress,
        'dropoff': dropoffAddress,
      };
      
      Log.d('Job addresses: $addresses');
      return addresses;
    } catch (e) {
      Log.e('=== ERROR GETTING JOB ADDRESSES ===');
      Log.e('Error: $e');
      return {
        'pickup': null,
        'dropoff': null,
      };
    }
  }
}
