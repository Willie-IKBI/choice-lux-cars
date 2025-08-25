import 'package:supabase_flutter/supabase_flutter.dart';

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
      print('=== STARTING JOB - DIRECT DATABASE APPROACH ===');
      print('Job ID: $jobId');
      print('Odometer: $odoStartReading');
      print('Image: $pdpStartImage');
      print('GPS: $gpsLat, $gpsLng, $gpsAccuracy');
      
      // Step 1: Get the driver for this job
      final jobResponse = await _supabase
          .from('jobs')
          .select('driver_id')
          .eq('id', jobId)
          .single();
      
      final driverId = jobResponse['driver_id'];
      if (driverId == null) {
        throw Exception('No driver assigned to job $jobId');
      }
      
      // Step 2: Update job status to started
      await _supabase
          .from('jobs')
          .update({
            'job_status': 'started',
            'job_start_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId);
      
      // Step 3: Create driver_flow record
      await _supabase
          .from('driver_flow')
          .upsert({
            'job_id': jobId,
            'driver_user': driverId,
            'current_step': 'vehicle_collection',
            'job_started_at': DateTime.now().toIso8601String(),
            'odo_start_reading': odoStartReading,
            'pdp_start_image': pdpStartImage,
            'last_activity_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'job_id');
      
      print('=== JOB STARTED SUCCESSFULLY ===');
    } catch (e) {
      print('=== ERROR STARTING JOB ===');
      print('Error: $e');
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
      print('=== COLLECTING VEHICLE - DIRECT DATABASE APPROACH ===');
      print('Job ID: $jobId');
      print('GPS: $gpsLat, $gpsLng, $gpsAccuracy');
      
      // Fix GPS accuracy overflow - round to reasonable value
      double? safeGpsAccuracy;
      if (gpsAccuracy != null) {
        if (gpsAccuracy > 999.99) {
          safeGpsAccuracy = 999.99; // Max value for precision 5, scale 2
          print('GPS accuracy too large ($gpsAccuracy), using max value: $safeGpsAccuracy');
        } else {
          safeGpsAccuracy = double.parse(gpsAccuracy.toStringAsFixed(2));
        }
      }
      
      await _supabase
          .from('driver_flow')
          .update({
            'vehicle_collected': true,
            'vehicle_collected_at': DateTime.now().toIso8601String(),
            'current_step': 'pickup_arrival',
            'last_activity_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId);
      
      print('=== VEHICLE COLLECTION RECORDED ===');
    } catch (e) {
      print('=== ERROR COLLECTING VEHICLE ===');
      print('Error: $e');
      throw Exception('Failed to record vehicle collection: $e');
    }
  }

  /// Record arrival at pickup location for a specific trip
  static Future<void> arriveAtPickup(int jobId, int tripIndex, {
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
  }) async {
    try {
      print('=== ARRIVE AT PICKUP - DIRECT DATABASE APPROACH ===');
      print('Job ID: $jobId, Trip Index: $tripIndex');
      print('GPS: $gpsLat, $gpsLng, $gpsAccuracy');
      
      // Fix GPS accuracy overflow - round to reasonable value
      double? safeGpsAccuracy;
      if (gpsAccuracy != null) {
        if (gpsAccuracy > 999.99) {
          safeGpsAccuracy = 999.99; // Max value for precision 5, scale 2
          print('GPS accuracy too large ($gpsAccuracy), using max value: $safeGpsAccuracy');
        } else {
          safeGpsAccuracy = double.parse(gpsAccuracy.toStringAsFixed(2));
        }
      }
      
      // Step 1: Get the driver for this job
      final jobResponse = await _supabase
          .from('jobs')
          .select('driver_id')
          .eq('id', jobId)
          .single();
      
      final driverId = jobResponse['driver_id'];
      if (driverId == null) {
        throw Exception('No driver assigned to job $jobId');
      }
      
      // Step 2: Ensure trip_progress record exists
      await _supabase
          .from('trip_progress')
          .upsert({
            'job_id': jobId,
            'trip_index': tripIndex,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'job_id,trip_index');
      
      // Step 3: Update trip_progress with pickup arrival
      await _supabase
          .from('trip_progress')
          .update({
            'pickup_arrived_at': DateTime.now().toIso8601String(),
            'pickup_gps_lat': gpsLat,
            'pickup_gps_lng': gpsLng,
            'pickup_gps_accuracy': safeGpsAccuracy,
            'status': 'pickup_arrived',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId)
          .eq('trip_index', tripIndex);
      
      // Step 4: Update driver_flow to next step
      await _supabase
          .from('driver_flow')
          .update({
            'current_step': 'passenger_onboard',
            'last_activity_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId);
      
      print('=== PICKUP ARRIVAL COMPLETED ===');
    } catch (e) {
      print('=== ERROR IN ARRIVE AT PICKUP ===');
      print('Error: $e');
      throw Exception('Failed to record pickup arrival: $e');
    }
  }

  /// Record passenger onboard for a specific trip
  static Future<void> passengerOnboard(int jobId, int tripIndex) async {
    try {
      print('=== PASSENGER ONBOARD - DIRECT DATABASE APPROACH ===');
      print('Job ID: $jobId, Trip Index: $tripIndex');
      
      // Step 1: Update trip_progress with passenger onboard
      await _supabase
          .from('trip_progress')
          .update({
            'passenger_onboard_at': DateTime.now().toIso8601String(),
            'status': 'onboard',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId)
          .eq('trip_index', tripIndex);
      
      // Step 2: Update driver_flow to next step
      await _supabase
          .from('driver_flow')
          .update({
            'current_step': 'dropoff_arrival',
            'last_activity_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId);
      
      print('=== PASSENGER ONBOARD COMPLETED ===');
    } catch (e) {
      print('=== ERROR IN PASSENGER ONBOARD ===');
      print('Error: $e');
      throw Exception('Failed to record passenger onboard: $e');
    }
  }

  /// Record arrival at dropoff location for a specific trip
  static Future<void> arriveAtDropoff(int jobId, int tripIndex, {
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
  }) async {
    try {
      print('=== ARRIVE AT DROPOFF - DIRECT DATABASE APPROACH ===');
      print('Job ID: $jobId, Trip Index: $tripIndex');
      print('GPS: $gpsLat, $gpsLng, $gpsAccuracy');
      
      // Fix GPS accuracy overflow - round to reasonable value
      double? safeGpsAccuracy;
      if (gpsAccuracy != null) {
        if (gpsAccuracy > 999.99) {
          safeGpsAccuracy = 999.99; // Max value for precision 5, scale 2
          print('GPS accuracy too large ($gpsAccuracy), using max value: $safeGpsAccuracy');
        } else {
          safeGpsAccuracy = double.parse(gpsAccuracy.toStringAsFixed(2));
        }
      }
      
      // Step 1: Update trip_progress with dropoff arrival
      await _supabase
          .from('trip_progress')
          .update({
            'dropoff_arrived_at': DateTime.now().toIso8601String(),
            'dropoff_gps_lat': gpsLat,
            'dropoff_gps_lng': gpsLng,
            'dropoff_gps_accuracy': safeGpsAccuracy,
            'status': 'dropoff_arrived',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId)
          .eq('trip_index', tripIndex);
      
      // Step 2: Update driver_flow to next step
      await _supabase
          .from('driver_flow')
          .update({
            'current_step': 'trip_complete',
            'last_activity_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId);
      
      print('=== DROPOFF ARRIVAL COMPLETED ===');
    } catch (e) {
      print('=== ERROR IN ARRIVE AT DROPOFF ===');
      print('Error: $e');
      throw Exception('Failed to record dropoff arrival: $e');
    }
  }

  /// Complete a trip
  static Future<void> completeTrip(int jobId, int tripIndex, {
    String? notes,
  }) async {
    try {
      print('=== COMPLETE TRIP - DIRECT DATABASE APPROACH ===');
      print('Job ID: $jobId, Trip Index: $tripIndex');
      
      // Step 1: Update trip_progress with trip completion
      await _supabase
          .from('trip_progress')
          .update({
            'status': 'completed',
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId)
          .eq('trip_index', tripIndex);
      
      // Step 2: Update driver_flow to next step
      await _supabase
          .from('driver_flow')
          .update({
            'current_step': 'vehicle_return',
            'last_activity_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId);
      
      print('=== TRIP COMPLETED ===');
    } catch (e) {
      print('=== ERROR IN COMPLETE TRIP ===');
      print('Error: $e');
      throw Exception('Failed to complete trip: $e');
    }
  }

  /// Record vehicle return
  static Future<void> returnVehicle(int jobId, {
    required double odoEndReading,
    required String pdpEndImage,
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
  }) async {
    try {
      print('=== RETURN VEHICLE - DIRECT DATABASE APPROACH ===');
      print('Job ID: $jobId');
      print('Odometer: $odoEndReading');
      print('Image: $pdpEndImage');
      print('GPS: $gpsLat, $gpsLng, $gpsAccuracy');
      
      // Fix GPS accuracy overflow - round to reasonable value
      double? safeGpsAccuracy;
      if (gpsAccuracy != null) {
        if (gpsAccuracy > 999.99) {
          safeGpsAccuracy = 999.99; // Max value for precision 5, scale 2
          print('GPS accuracy too large ($gpsAccuracy), using max value: $safeGpsAccuracy');
        } else {
          safeGpsAccuracy = double.parse(gpsAccuracy.toStringAsFixed(2));
        }
      }
      
      // Step 1: Update driver_flow with return details
      await _supabase
          .from('driver_flow')
          .update({
            'job_closed_odo': odoEndReading,
            'job_closed_odo_img': pdpEndImage,
            'job_closed_time': DateTime.now().toIso8601String(),
            'current_step': 'completed',
            'last_activity_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId);
      
      // Step 2: Update job status to completed
      await _supabase
          .from('jobs')
          .update({
            'job_status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId);
      
      print('=== VEHICLE RETURN COMPLETED ===');
    } catch (e) {
      print('=== ERROR IN RETURN VEHICLE ===');
      print('Error: $e');
      throw Exception('Failed to record vehicle return: $e');
    }
  }

  /// Get current job progress
  static Future<Map<String, dynamic>> getJobProgress(int jobId) async {
    try {
      // First, get job info (this should always exist)
      final jobResponse = await _supabase
          .from('jobs')
          .select('job_status, driver_id')
          .eq('id', jobId)
          .single();
      
      // Try to get driver_flow data (may not exist yet)
      final driverFlowResponse = await _supabase
          .from('driver_flow')
          .select('*')
          .eq('job_id', jobId)
          .maybeSingle();
      
      Map<String, dynamic> combinedData;
      
      if (driverFlowResponse != null) {
        // Driver flow record exists - use actual data
        combinedData = {
          'job_id': jobId,
          'job_status': jobResponse['job_status'],
          'driver_id': driverFlowResponse['driver_user'],
          'current_step': driverFlowResponse['current_step'] ?? 'vehicle_collection',
          'current_trip_index': driverFlowResponse['current_trip_index'] ?? 1,
          'progress_percentage': driverFlowResponse['progress_percentage'] ?? 0,
          'last_activity_at': driverFlowResponse['last_activity_at'],
          'job_started_at': driverFlowResponse['job_started_at'],
          'vehicle_collected': driverFlowResponse['vehicle_collected'] ?? false,
          'vehicle_collected_at': driverFlowResponse['vehicle_collected_at'],
          'transport_completed_ind': driverFlowResponse['transport_completed_ind'] ?? false,
          'job_closed_time': driverFlowResponse['job_closed_time'],
          'total_trips': 0,
          'completed_trips': 0,
          'calculated_status': (driverFlowResponse['vehicle_collected'] == true) ? 'in_progress' : 'assigned',
        };
      } else {
        // No driver flow record yet - create default response
        combinedData = {
          'job_id': jobId,
          'job_status': jobResponse['job_status'],
          'driver_id': jobResponse['driver_id'],
          'current_step': 'vehicle_collection',
          'current_trip_index': 1,
          'progress_percentage': 0,
          'last_activity_at': null,
          'job_started_at': null,
          'vehicle_collected': false,
          'vehicle_collected_at': null,
          'transport_completed_ind': false,
          'job_closed_time': null,
          'total_trips': 0,
          'completed_trips': 0,
          'calculated_status': 'assigned',
        };
      }
      
      return combinedData;
    } catch (e) {
      throw Exception('Failed to get job progress: $e');
    }
  }

  /// Get trip progress for a job
  static Future<List<Map<String, dynamic>>> getTripProgress(int jobId) async {
    try {
      final response = await _supabase
          .from('trip_progress')
          .select('*')
          .eq('job_id', jobId)
          .order('trip_index');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get trip progress: $e');
    }
  }

  /// Update current step in driver flow
  static Future<void> updateCurrentStep(int jobId, String step, int tripIndex) async {
    try {
      await _supabase
          .from('driver_flow')
          .update({
            'current_step': step,
            'current_trip_index': tripIndex,
            'last_activity_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId);
    } catch (e) {
      throw Exception('Failed to update current step: $e');
    }
  }

  /// Record payment collection
  static Future<void> recordPaymentCollection(int jobId, bool collected) async {
    try {
      await _supabase
          .from('driver_flow')
          .update({
            'payment_collected_ind': collected,
            'last_activity_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId);
    } catch (e) {
      throw Exception('Failed to record payment collection: $e');
    }
  }

  /// Confirm driver awareness of job
  static Future<bool> confirmDriverAwareness(int jobId) async {
    try {
      print('=== CONFIRMING DRIVER AWARENESS ===');
      print('Job ID: $jobId');
      
      // Step 1: Update job confirmation status
      final response = await _supabase
          .from('jobs')
          .update({
            'driver_confirm_ind': true,
            'is_confirmed': true,
            'confirmed_at': DateTime.now().toIso8601String(),
            'confirmed_by': _supabase.auth.currentUser?.id,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId)
          .select();

      if (response.isEmpty) {
        print('No job found with ID $jobId');
        return false;
      }

      print('Job confirmation updated successfully');

      // Step 2: Mark job assignment notifications as read
      try {
        await _supabase
            .from('notifications')
            .update({
              'is_read': true,
              'read_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('job_id', jobId.toString())
            .or('notification_type.eq.job_assignment,notification_type.eq.job_reassignment')
            .eq('is_read', false);

        print('Job assignment notifications marked as read');
      } catch (e) {
        print('Warning: Could not mark notifications as read: $e');
        // Don't fail the confirmation if notification update fails
      }

      print('=== DRIVER CONFIRMATION COMPLETED ===');
      return true;
    } catch (e) {
      print('=== ERROR CONFIRMING DRIVER AWARENESS ===');
      print('Error: $e');
      return false;
    }
  }

  /// Update job status to completed
  static Future<void> updateJobStatusToCompleted(int jobId) async {
    try {
      print('=== UPDATING JOB STATUS TO COMPLETED ===');
      print('Job ID: $jobId');
      
      await _supabase
          .from('jobs')
          .update({
            'job_status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId);
      
      print('Job status updated to completed');
      print('=== JOB STATUS UPDATE COMPLETED ===');
    } catch (e) {
      print('=== ERROR UPDATING JOB STATUS ===');
      print('Error: $e');
      throw Exception('Failed to update job status: $e');
    }
  }

  /// Close a job
  static Future<void> closeJob(int jobId) async {
    try {
      print('=== CLOSING JOB ===');
      print('Job ID: $jobId');
      
      // Update job status to completed
      await _supabase
          .from('jobs')
          .update({
            'job_status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId);
      
      // Update driver_flow to mark as completed
      await _supabase
          .from('driver_flow')
          .update({
            'current_step': 'completed',
            'last_activity_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId);
      
      print('Job closed successfully');
      print('=== JOB CLOSED ===');
    } catch (e) {
      print('=== ERROR CLOSING JOB ===');
      print('Error: $e');
      throw Exception('Failed to close job: $e');
    }
  }
}
