import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job.dart';
import '../models/trip.dart';

class DriverFlowApiService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Start a job - marks the job as started and records the start time
  static Future<void> startJob(int jobId, {
    required double odoStartReading,
    required String pdpStartImage,
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
    Function()? onJobStarted, // Callback to refresh jobs list
  }) async {
    try {
      await _supabase.rpc('start_job', params: {
        'job_id': jobId,
        'odo_start_reading': odoStartReading,
        'pdp_start_image': pdpStartImage,
        'gps_lat': gpsLat,
        'gps_lng': gpsLng,
        'gps_accuracy': gpsAccuracy,
      });
      
      // Call the callback to refresh jobs list if provided
      if (onJobStarted != null) {
        onJobStarted();
      }
    } catch (e) {
      throw Exception('Failed to start job: $e');
    }
  }

  /// Resume a job - continues from where it left off
  static Future<void> resumeJob(int jobId) async {
    try {
      await _supabase.rpc('resume_job', params: {
        'job_id': jobId,
      });
    } catch (e) {
      throw Exception('Failed to resume job: $e');
    }
  }

  /// Record vehicle collection
  static Future<void> collectVehicle(int jobId, {
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
  }) async {
    try {
      await _supabase
          .from('driver_flow')
          .update({
            'vehicle_collected': true,
            'vehicle_time': DateTime.now().toIso8601String(),
            'pickup_loc': 'POINT($gpsLng $gpsLat)',
            'last_activity_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId);
    } catch (e) {
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
      await _supabase.rpc('arrive_at_pickup', params: {
        'job_id': jobId,
        'trip_index': tripIndex,
        'gps_lat': gpsLat,
        'gps_lng': gpsLng,
        'gps_accuracy': gpsAccuracy,
      });
    } catch (e) {
      throw Exception('Failed to record pickup arrival: $e');
    }
  }

  /// Record passenger onboard for a specific trip
  static Future<void> passengerOnboard(int jobId, int tripIndex) async {
    try {
      await _supabase
          .from('trip_progress')
          .update({
            'passenger_onboard_at': DateTime.now().toIso8601String(),
            'status': 'onboard',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId)
          .eq('trip_index', tripIndex);
    } catch (e) {
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
      await _supabase
          .from('trip_progress')
          .update({
            'dropoff_arrived_at': DateTime.now().toIso8601String(),
            'dropoff_gps_lat': gpsLat,
            'dropoff_gps_lng': gpsLng,
            'dropoff_gps_accuracy': gpsAccuracy,
            'status': 'dropoff_arrived',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId)
          .eq('trip_index', tripIndex);
    } catch (e) {
      throw Exception('Failed to record dropoff arrival: $e');
    }
  }

  /// Complete a trip
  static Future<void> completeTrip(int jobId, int tripIndex, {
    String? notes,
  }) async {
    try {
      await _supabase
          .from('trip_progress')
          .update({
            'status': 'completed',
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId)
          .eq('trip_index', tripIndex);
    } catch (e) {
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
      await _supabase
          .from('driver_flow')
          .update({
            'job_closed_odo': odoEndReading,
            'job_closed_odo_img': pdpEndImage,
            'job_closed_time': DateTime.now().toIso8601String(),
            'last_activity_at': DateTime.now().toIso8601String(),
          })
          .eq('job_id', jobId);
    } catch (e) {
      throw Exception('Failed to record vehicle return: $e');
    }
  }

  /// Close a job
  static Future<void> closeJob(int jobId) async {
    try {
      await _supabase.rpc('close_job', params: {
        'job_id': jobId,
      });
    } catch (e) {
      throw Exception('Failed to close job: $e');
    }
  }

  /// Get current job progress
  static Future<Map<String, dynamic>> getJobProgress(int jobId) async {
    try {
      // Read directly from driver_flow table to avoid view caching issues
      final response = await _supabase
          .from('driver_flow')
          .select('*')
          .eq('job_id', jobId)
          .single();
      
      // Add job status from jobs table
      final jobResponse = await _supabase
          .from('jobs')
          .select('job_status')
          .eq('id', jobId)
          .single();
      
      // Combine the data
      final combinedData = {
        'job_id': jobId,
        'job_status': jobResponse['job_status'],
        'driver_id': response['driver_user'],
        'current_step': response['current_step'],
        'current_trip_index': response['current_trip_index'] ?? 1,
        'progress_percentage': response['progress_percentage'] ?? 0,
        'last_activity_at': response['last_activity_at'],
        'job_started_at': response['job_started_at'],
        'vehicle_collected': response['vehicle_collected'],
        'vehicle_collected_at': response['vehicle_collected_at'],
        'transport_completed_ind': response['transport_completed_ind'] ?? false,
        'job_closed_time': response['job_closed_time'],
        'total_trips': 0, // We'll add this later if needed
        'completed_trips': 0, // We'll add this later if needed
        'calculated_status': response['vehicle_collected'] == true ? 'in_progress' : 'started',
      };
      
      return combinedData;
    } catch (e) {
      throw Exception('Failed to get job progress: $e');
    }
  }

  /// Get driver's current job
  static Future<Map<String, dynamic>?> getDriverCurrentJob(String driverId) async {
    try {
      final response = await _supabase.rpc('get_driver_current_job', params: {
        'driver_uuid': driverId,
      });
      
      if (response != null && response.isNotEmpty) {
        return response[0];
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get driver current job: $e');
    }
  }

  /// Get all active jobs for monitoring (admin/manager)
  static Future<List<Map<String, dynamic>>> getActiveJobsForMonitoring() async {
    try {
      final response = await _supabase.rpc('get_active_jobs_for_monitoring');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get active jobs: $e');
    }
  }

  /// Get driver activity summary
  static Future<List<Map<String, dynamic>>> getDriverActivitySummary() async {
    try {
      final response = await _supabase
          .from('driver_activity_summary')
          .select('*')
          .order('last_activity', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get driver activity summary: $e');
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
          })
          .eq('job_id', jobId);
    } catch (e) {
      throw Exception('Failed to record payment collection: $e');
    }
  }

  // Confirm driver awareness of job
  static Future<bool> confirmDriverAwareness(int jobId) async {
    try {
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

      if (response.isNotEmpty) {
        print('Driver confirmation successful for job $jobId');
        return true;
      } else {
        print('No job found with ID $jobId');
        return false;
      }
    } catch (e) {
      print('Error confirming driver awareness: $e');
      return false;
    }
  }
}
