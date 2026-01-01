import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/core/services/job_invoice_service.dart';
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';

/// Provider for JobInvoiceService
final jobInvoiceServiceProvider = Provider<JobInvoiceService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return JobInvoiceService(supabase);
});

/// Provider that returns the invoice PDF URL for a specific job
///
/// Takes jobId as a parameter using the family pattern.
/// Returns AsyncValue of String? to handle loading/error states.
final jobInvoicePdfProvider = FutureProvider.family<String?, String>(
  (ref, jobId) async {
    final service = ref.watch(jobInvoiceServiceProvider);
    return await service.getInvoicePdfUrl(jobId);
  },
);

