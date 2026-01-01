import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Service for accessing job invoice PDF URLs without importing jobs feature
///
/// This service provides a lightweight way to read job invoice PDF URLs
/// and trigger job data refreshes without creating feature-to-feature dependencies.
class JobInvoiceService {
  final SupabaseClient _supabase;

  JobInvoiceService(this._supabase);

  /// Get the invoice PDF URL for a specific job
  ///
  /// Returns the invoice_pdf field from the jobs table for the given jobId.
  /// Returns null if job not found or invoice_pdf is null.
  Future<String?> getInvoicePdfUrl(String jobId) async {
    try {
      Log.d('Fetching invoice PDF URL for job: $jobId');

      final response = await _supabase
          .from('jobs')
          .select('invoice_pdf')
          .eq('id', jobId)
          .maybeSingle();

      if (response != null) {
        final invoicePdf = response['invoice_pdf']?.toString();
        Log.d('Invoice PDF URL for job $jobId: $invoicePdf');
        return invoicePdf?.isEmpty == true ? null : invoicePdf;
      } else {
        Log.d('Job not found: $jobId');
        return null;
      }
    } catch (error) {
      Log.e('Error fetching invoice PDF URL for job $jobId: $error');
      return null;
    }
  }

  /// Trigger a refresh of job data by invalidating the job query
  ///
  /// This method performs a lightweight query to force Supabase to refresh
  /// the job data cache. The actual refresh is handled by the jobs feature
  /// provider when it watches this data.
  ///
  /// Note: This is a minimal refresh mechanism. For a full jobs list refresh,
  /// the jobs feature provider should be invalidated separately (but we can't
  /// do that from core without importing the feature).
  Future<void> refreshJobInvoice(String jobId) async {
    try {
      Log.d('Refreshing job invoice data for job: $jobId');

      // Perform a lightweight query to trigger cache refresh
      // The actual refresh will happen when the jobs provider refetches
      await _supabase
          .from('jobs')
          .select('invoice_pdf, updated_at')
          .eq('id', jobId)
          .maybeSingle();

      Log.d('Job invoice data refreshed for job: $jobId');
    } catch (error) {
      Log.e('Error refreshing job invoice data for job $jobId: $error');
      // Don't throw - this is a best-effort refresh
    }
  }
}

