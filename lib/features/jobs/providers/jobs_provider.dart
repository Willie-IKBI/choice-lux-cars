import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../models/trip.dart';
import 'package:choice_lux_cars/core/services/supabase_service.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

final jobsProvider = StateNotifierProvider<JobsNotifier, List<Job>>((ref) {
  final currentUser = ref.watch(currentUserProfileProvider);
  return JobsNotifier(currentUser);
});

final tripsProvider = StateNotifierProvider<TripsNotifier, List<Trip>>((ref) {
  return TripsNotifier();
});

class JobsNotifier extends StateNotifier<List<Job>> {
  final currentUser;
  
  JobsNotifier(this.currentUser) : super([]) {
    fetchJobs();
  }

  // Fetch jobs based on user role
  Future<void> fetchJobs() async {
    try {
      List<Map<String, dynamic>> jobMaps;
      
      if (currentUser == null) {
        state = [];
        return;
      }

      final userRole = currentUser.role?.toLowerCase();
      final userId = currentUser.id;

      if (userRole == 'administrator' || userRole == 'manager') {
        // Admins and managers see all jobs
        jobMaps = await SupabaseService.instance.getJobs();
      } else if (userRole == 'driver_manager') {
        // Driver managers see jobs they created or are assigned to them
        jobMaps = await SupabaseService.instance.getJobsByDriverManager(userId);
      } else if (userRole == 'driver') {
        // Drivers see only jobs assigned to them
        jobMaps = await SupabaseService.instance.getJobsByDriver(userId);
      } else {
        // Other roles see no jobs
        state = [];
        return;
      }

              state = jobMaps.map((map) => Job.fromMap(map)).toList();
    } catch (error) {
      print('Error fetching jobs: $error');
      state = [];
    }
  }

  // Get open jobs only
  List<Job> get openJobs => state.where((job) => job.isOpen).toList();

  // Get closed jobs only
  List<Job> get closedJobs => state.where((job) => job.isClosed).toList();

  // Get in-progress jobs only
  List<Job> get inProgressJobs => state.where((job) => job.isInProgress).toList();

  // Create new job
  Future<Map<String, dynamic>> createJob(Job job) async {
    try {
      final createdJob = await SupabaseService.instance.createJob(job.toMap());
      await fetchJobs();
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
      await fetchJobs();
    } catch (error) {
      print('Error updating job: $error');
      rethrow;
    }
  }

  // Update job status
  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      await SupabaseService.instance.updateJob(
        jobId: jobId, 
        data: {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        }
      );
      await fetchJobs();
    } catch (error) {
      print('Error updating job status: $error');
      rethrow;
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
      await fetchJobs();
    } catch (error) {
      print('Error updating job payment amount: $error');
      rethrow;
    }
  }

  // Delete job
  Future<void> deleteJob(String jobId) async {
    try {
      await SupabaseService.instance.deleteJob(jobId);
      await fetchJobs();
    } catch (error) {
      print('Error deleting job: $error');
      rethrow;
    }
  }

  // Check if user can create jobs
  bool get canCreateJobs {
    if (currentUser == null) return false;
    final userRole = currentUser.role?.toLowerCase();

    return userRole == 'administrator' || 
           userRole == 'manager' || 
           userRole == 'driver_manager';
  }
}

class TripsNotifier extends StateNotifier<List<Trip>> {
  TripsNotifier() : super([]);

  // Fetch trips for a specific job
  Future<void> fetchTripsForJob(String jobId) async {
    try {
      final tripMaps = await SupabaseService.instance.getTripsByJob(jobId);
      state = tripMaps.map((map) => Trip.fromMap(map)).toList();
    } catch (error) {
      print('Error fetching trips: $error');
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