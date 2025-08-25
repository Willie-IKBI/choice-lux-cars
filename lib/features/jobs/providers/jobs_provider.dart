import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../models/trip.dart';
import '../services/driver_flow_api_service.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/features/notifications/providers/notification_provider.dart';
import 'package:choice_lux_cars/core/constants/notification_constants.dart';
import 'package:uuid/uuid.dart';
import '../services/job_assignment_service.dart';

final jobsProvider = StateNotifierProvider<JobsNotifier, List<Job>>((ref) {
  final currentUser = ref.watch(currentUserProfileProvider);
  final notifier = JobsNotifier(currentUser);
  
  // Watch for user changes and update the notifier
  ref.listen(currentUserProfileProvider, (previous, next) {
    if (previous?.id != next?.id) {
      print('User changed from ${previous?.id} to ${next?.id}, updating jobs provider');
      notifier.updateUser(next);
    }
  });
  
  return notifier;
});

final tripsProvider = StateNotifierProvider<TripsNotifier, List<Trip>>((ref) {
  return TripsNotifier();
});

class JobsNotifier extends StateNotifier<List<Job>> {
  dynamic currentUser;
  
  JobsNotifier(this.currentUser) : super([]) {
    fetchJobs();
  }

  // Update current user and refresh jobs
  void updateUser(dynamic newUser) {
    currentUser = newUser;
    fetchJobs();
  }

  // Fetch jobs based on user role
  Future<void> fetchJobs() async {
    try {
      print('=== FETCHING JOBS ===');
      print('Current user: ${currentUser?.id} (${currentUser?.role})');
      
      List<Map<String, dynamic>> jobMaps;
      
      if (currentUser == null) {
        print('No current user, setting empty state');
        state = [];
        return;
      }

      final userRole = currentUser.role?.toLowerCase();
      final userId = currentUser.id;

      if (userRole == 'administrator' || userRole == 'manager') {
        // Admins and managers see all jobs
        print('Fetching all jobs for admin/manager');
        jobMaps = await SupabaseService.instance.getJobs();
      } else if (userRole == 'driver_manager') {
        // Driver managers see jobs they created or are assigned to them
        print('Fetching jobs for driver manager: $userId');
        jobMaps = await SupabaseService.instance.getJobsByDriverManager(userId);
      } else if (userRole == 'driver') {
        // Drivers see only jobs assigned to them
        print('Fetching jobs for driver: $userId');
        jobMaps = await SupabaseService.instance.getJobsByDriver(userId);
      } else {
        // Other roles see no jobs
        print('Unknown role: $userRole, setting empty state');
        if (!mounted) return;
        state = [];
        return;
      }

      print('Fetched ${jobMaps.length} jobs');
      if (jobMaps.isNotEmpty) {
        print('Sample job: ${jobMaps.first}');
      }

      if (!mounted) return;
      state = jobMaps.map((map) => Job.fromMap(map)).toList();
      print('State updated with ${state.length} jobs');
    } catch (error) {
      print('Error fetching jobs: $error');
      if (!mounted) return;
      state = [];
    }
  }

  // Get open jobs only
  List<Job> get openJobs => state.where((job) => job.isOpen).toList();

  // Get closed jobs only
  List<Job> get closedJobs => state.where((job) => job.isClosed).toList();

  // Get in-progress jobs only
  List<Job> get inProgressJobs => state.where((job) => job.isInProgress).toList();

  // Check if current user can create jobs
  bool get canCreateJobs {
    if (currentUser == null) return false;
    final userRole = currentUser.role?.toLowerCase();
    return userRole == 'administrator' || 
           userRole == 'admin' ||
           userRole == 'manager' ||
           userRole == 'driver_manager' ||
           userRole == 'drivermanager';
  }

  // Get jobs by status
  List<Job> getJobsByStatus(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return openJobs;
      case 'in_progress':
        return inProgressJobs;
      case 'completed':
        return closedJobs;
      case 'all':
        return state;
      default:
        return state;
    }
  }

  // Create new job
  Future<Map<String, dynamic>> createJob(Job job) async {
    try {
      print('=== CREATING JOB ===');
      print('Job data: ${job.toMap()}');
      
      final createdJob = await SupabaseService.instance.createJob(job.toMap());
      print('Job created successfully: $createdJob');
      
      // If job has a driver assigned, create notification automatically
      if (job.driverId != null && job.driverId!.isNotEmpty) {
        try {
          print('Job has driver assigned, creating notification...');
          await JobAssignmentService.assignJobToDriver(
            jobId: createdJob['id'] as int,
            driverId: job.driverId!,
            isReassignment: false,
          );
          print('Notification created for job assignment');
        } catch (notificationError) {
          print('Warning: ${NotificationConstants.errorNotificationCreationFailed}: $notificationError');
          // Don't fail the job creation if notification fails
          // In production, this should be logged to monitoring system
        }
      }
      
      if (mounted) {
        print('Refreshing jobs list...');
        await fetchJobs();
        print('Jobs list refreshed. Current state has ${state.length} jobs');
      } else {
        print('Provider not mounted, skipping refresh');
      }
      
      return createdJob;
    } catch (error) {
      print('Error creating job: $error');
      rethrow;
    }
  }

  // Update job
  Future<void> updateJob(Job job) async {
    try {
      await SupabaseService.instance.updateJob(jobId: job.id, data: job.toMap());
      if (mounted) {
        await fetchJobs();
      }
    } catch (error) {
      print('Error updating job: $error');
      rethrow;
    }
  }

  // Update job status
  Future<void> updateJobStatus(String jobId, String newStatus) async {
    try {
      await SupabaseService.instance.updateJob(
        jobId: jobId, 
        data: {
          'job_status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        }
      );
      if (mounted) {
        await fetchJobs();
      }
    } catch (error) {
      print('Error updating job status: $error');
      rethrow;
    }
  }

  // Refresh a specific job (useful after confirmation)
  Future<void> refreshJob(String jobId) async {
    try {
      // Fetch the specific job to get updated data
      final jobData = await SupabaseService.instance.getJob(jobId);
      if (jobData != null) {
        final updatedJob = Job.fromMap(jobData);
        
        // Update the job in the state
        final updatedJobs = state.map((job) {
          if (job.id == jobId) {
            return updatedJob;
          }
          return job;
        }).toList();
        
        if (mounted) {
          state = updatedJobs;
        }
      }
    } catch (error) {
      print('Error refreshing job: $error');
      // Fallback to full refresh
      await fetchJobs();
    }
  }

  // Update job payment amount
  Future<void> updateJobPaymentAmount(String jobId, double amount) async {
    try {
      await SupabaseService.instance.updateJob(
        jobId: jobId, 
        data: {
          'amount': amount,
          'updated_at': DateTime.now().toIso8601String(),
        }
      );
      if (mounted) {
        await fetchJobs();
      }
    } catch (error) {
      print('Error updating job payment amount: $error');
      rethrow;
    }
  }

  // Delete job
  Future<void> deleteJob(String jobId) async {
    try {
      await SupabaseService.instance.deleteJob(jobId);
      if (mounted) {
        await fetchJobs();
      }
    } catch (error) {
      print('Error deleting job: $error');
      rethrow;
    }
  }

  // Confirm job assignment
  Future<void> confirmJob(String jobId, {required WidgetRef ref}) async {
    print('=== JOBS PROVIDER: confirmJob() called ===');
    print('Job ID: $jobId');
    print('Current User: ${currentUser?.id}');
    print('Current User Role: ${currentUser?.role}');
    
    try {
      print('Updating job in database...');
      await SupabaseService.instance.updateJob(
        jobId: jobId,
        data: {
          'is_confirmed': true,
          'driver_confirm_ind': true, // Add this for backward compatibility
          'confirmed_at': DateTime.now().toIso8601String(),
          'confirmed_by': currentUser?.id,
          'updated_at': DateTime.now().toIso8601String(),
        }
      );
      
      print('Job confirmation updated in database successfully');
      
      // Hide all notifications for this job (soft delete)
      try {
        print('Hiding job notifications...');
        await ref.read(notificationProvider.notifier).hideJobNotifications(jobId);
        print('Job notifications hidden successfully');
      } catch (e) {
        print('Warning: Could not hide notifications: $e');
      }
      
      // Update the local state to reflect the confirmation
      if (mounted) {
        print('Updating local state...');
        final updatedJobs = state.map((job) {
          if (job.id == jobId) {
            print('Found job to update: ${job.id}');
            return job.copyWith(
              isConfirmed: true,
              driverConfirmation: true,
              confirmedAt: DateTime.now(),
              confirmedBy: currentUser?.id,
            );
          }
          return job;
        }).toList();
        
        state = updatedJobs;
        print('Local state updated after confirmation');
      } else {
        print('Provider not mounted, skipping local state update');
      }
      
      print('=== JOB CONFIRMATION COMPLETED SUCCESSFULLY ===');
    } catch (error) {
      print('Error confirming job: $error');
      rethrow;
    }
  }

  // Get jobs that need confirmation (for current driver)
  List<Job> get jobsNeedingConfirmation {
    if (currentUser == null) return [];
    
    return state.where((job) => 
      job.driverId == currentUser!.id && 
      job.driverConfirmation != true
    ).toList();
  }

  // Get confirmation status for a specific job
  bool isJobConfirmed(String jobId) {
    try {
      final job = state.firstWhere((j) => j.id == jobId);
      return job.isConfirmed == true || job.driverConfirmation == true;
    } catch (e) {
      return false;
    }
  }

  // Fetch a single job by ID
  Future<Job?> fetchJobById(String jobId) async {
    try {
      final jobMap = await SupabaseService.instance.getJob(jobId);
      if (jobMap != null) {
        return Job.fromMap(jobMap);
      }
      return null;
    } catch (error) {
      print('Error fetching job by ID: $error');
      return null;
    }
  }

  // Public method to refresh jobs list (useful for external components)
  Future<void> refreshJobs() async {
    if (mounted) {
      await fetchJobs();
    }
  }

  // Handle job starting - updates job status and refreshes list
  Future<void> startJob(String jobId, {
    required double odoStartReading,
    required String pdpStartImage,
    required double gpsLat,
    required double gpsLng,
    double? gpsAccuracy,
  }) async {
    try {
      // Call the driver flow API to start the job
      await DriverFlowApiService.startJob(
        int.parse(jobId),
        odoStartReading: odoStartReading,
        pdpStartImage: pdpStartImage,
        gpsLat: gpsLat,
        gpsLng: gpsLng,
        gpsAccuracy: gpsAccuracy,
      );
      
      // Refresh jobs list after job is started
      if (mounted) {
        fetchJobs();
      }
    } catch (error) {
      print('Error starting job: $error');
      rethrow;
    }
  }

  // Manually trigger job assignment notification (for testing)
  Future<void> triggerJobAssignmentNotification(int jobId, String driverId) async {
    try {
      print('=== MANUALLY TRIGGERING JOB ASSIGNMENT NOTIFICATION ===');
      print('Job ID: $jobId');
      print('Driver ID: $driverId');
      
      await JobAssignmentService.assignJobToDriver(
        jobId: jobId,
        driverId: driverId,
        isReassignment: false,
      );
      
      print('Job assignment notification triggered successfully');
    } catch (error) {
      print('Error triggering job assignment notification: $error');
      rethrow;
    }
  }
}

class TripsNotifier extends StateNotifier<List<Trip>> {
  TripsNotifier() : super([]);

  // Fetch trips for a specific job
  Future<void> fetchTripsForJob(String jobId) async {
    try {
      final tripMaps = await SupabaseService.instance.getTripsByJob(jobId);
      if (!mounted) return;
      state = tripMaps.map((map) => Trip.fromMap(map)).toList();
    } catch (error) {
      print('Error fetching trips: $error');
      if (!mounted) return;
      state = [];
    }
  }

  // Add trip to job
  Future<void> addTrip(Trip trip) async {
    try {
      await SupabaseService.instance.createTrip(trip.toMap());
      await fetchTripsForJob(trip.jobId);
    } catch (error) {
      print('Error adding trip: $error');
      rethrow;
    }
  }

  // Update trip
  Future<void> updateTrip(Trip trip) async {
    try {
      await SupabaseService.instance.updateTrip(
        tripId: trip.id, 
        data: trip.toMap()
      );
      await fetchTripsForJob(trip.jobId);
    } catch (error) {
      print('Error updating trip: $error');
      rethrow;
    }
  }

  // Delete trip
  Future<void> deleteTrip(String tripId, String jobId) async {
    try {
      await SupabaseService.instance.deleteTrip(tripId);
      await fetchTripsForJob(jobId);
    } catch (error) {
      print('Error deleting trip: $error');
      rethrow;
    }
  }

  // Clear trips (for new job creation)
  void clearTrips() {
    state = [];
  }

  // Get total amount for all trips
  double get totalAmount => state.fold(0, (sum, trip) => sum + trip.amount);
} 