import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Service to periodically check job start deadlines
/// This is a workaround until Supabase cron job permissions are fixed
class JobDeadlineCheckService {
  static JobDeadlineCheckService? _instance;
  static JobDeadlineCheckService get instance =>
      _instance ??= JobDeadlineCheckService._();

  JobDeadlineCheckService._();

  Timer? _timer;
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isRunning = false;

  /// Start the periodic check (every 10 minutes)
  /// Only runs for admin, manager, or driver_manager roles
  void start({String? userRole}) {
    // Only run for roles that should receive these notifications
    final allowedRoles = ['administrator', 'manager', 'driver_manager'];
    if (userRole == null || !allowedRoles.contains(userRole.toLowerCase())) {
      Log.d('JobDeadlineCheckService: Skipping start - user role: $userRole');
      return;
    }

    if (_isRunning) {
      Log.d('JobDeadlineCheckService: Already running');
      return;
    }

    Log.d('JobDeadlineCheckService: Starting periodic checks (every 10 minutes)');
    _isRunning = true;

    // Run immediately on start
    _checkDeadlines();

    // Then run every 10 minutes
    _timer = Timer.periodic(const Duration(minutes: 10), (_) {
      _checkDeadlines();
    });
  }

  /// Stop the periodic check
  void stop() {
    if (!_isRunning) {
      return;
    }

    Log.d('JobDeadlineCheckService: Stopping periodic checks');
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// Check if the service is currently running
  bool get isRunning => _isRunning;

  /// Manually trigger a deadline check
  Future<void> checkDeadlinesNow() async {
    await _checkDeadlines();
  }

  /// Internal method to call the Edge Function
  Future<void> _checkDeadlines() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        Log.d('JobDeadlineCheckService: No authenticated user, stopping');
        stop();
        return;
      }

      Log.d('JobDeadlineCheckService: Checking job start deadlines...');

      final response = await _supabase.functions.invoke(
        'check-job-start-deadlines',
        body: {},
      );

      Log.d('JobDeadlineCheckService: Edge Function response: $response');
      Log.d('JobDeadlineCheckService: Deadline check completed successfully');
    } catch (error) {
      Log.e('JobDeadlineCheckService: Error checking deadlines: $error');
      // Don't stop the service on error - keep trying
    }
  }

  /// Dispose resources
  void dispose() {
    stop();
  }
}



