import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/features/admin/models/ops_driver_option.dart';
import 'package:choice_lux_cars/features/jobs/services/job_assignment_service.dart';
import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';

/// Admin-only job actions (assign/reassign driver). Respects RLS.
class AdminJobsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Eligible drivers: role == driver, status == active. Minimal fields.
  static Future<List<OpsDriverOption>> getEligibleDrivers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, display_name, number')
          .eq('role', 'driver')
          .eq('status', 'active')
          .order('display_name', ascending: true);
      final list = response as List<dynamic>;
      return list.map((row) {
        final map = row as Map<String, dynamic>;
        return OpsDriverOption(
          id: map['id']?.toString() ?? '',
          displayName: map['display_name']?.toString() ?? '',
          number: map['number']?.toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }


  /// Assign/reassign driver. Success only if BOTH jobs and driver_flow (when present) updates succeed.
  /// [assignedByUserId] for audit. Throws on failure with user-facing message.
  static Future<void> assignDriver(
    int jobId,
    String driverId, {
    required String assignedByUserId,
  }) async {
    try {
      final nowIso = SATimeUtils.getCurrentSATimeISO();

      // 1) Verify job exists and get current driver (RLS: admin can select)
      final jobResponse = await _supabase
          .from('jobs')
          .select('id, driver_id')
          .eq('id', jobId)
          .maybeSingle();

      if (jobResponse == null) {
        throw Exception('Job not found');
      }

      final currentDriverId = jobResponse['driver_id']?.toString();

      // 2) Update jobs.driver_id and updated_at (must succeed)
      await _supabase.from('jobs').update({
        'driver_id': driverId,
        'updated_at': nowIso,
      }).eq('id', jobId);

      // 3) If driver_flow row exists, update driver_user (must succeed; throw if it fails)
      final flowResponse = await _supabase
          .from('driver_flow')
          .select('job_id')
          .eq('job_id', jobId)
          .maybeSingle();

      if (flowResponse != null) {
        await _supabase.from('driver_flow').update({
          'driver_user': driverId,
          'updated_at': nowIso,
        }).eq('job_id', jobId);
      }

      // 4) Only after both succeed: notify driver (non-blocking; do not fail assign on notification failure)
      try {
        await JobAssignmentService.notifyDriverOfReassignment(
          jobId: jobId.toString(),
          newDriverId: driverId,
          previousDriverId: currentDriverId,
        );
      } catch (_) {
        // Notification failure does not fail the assign
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('rls') || msg.contains('policy') || msg.contains('permission') || msg.contains('denied') || msg.contains('row-level')) {
        throw Exception("You don't have permission to assign this job.");
      }
      if (msg.contains('job not found') || msg.contains('not found')) {
        throw Exception('Job not found');
      }
      rethrow;
    }
  }
}
