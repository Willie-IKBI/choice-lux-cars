import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/features/invoices/models/invoice_data.dart';
import 'invoice_config_service.dart';

class InvoiceRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<InvoiceData> fetchInvoiceData({required String jobId}) async {
    try {
      // Use the dedicated invoice function
      final response = await _supabase.rpc(
        'get_invoice_data_for_pdf',
        params: {'p_job_id': int.parse(jobId)},
      );

      if (response == null) {
        throw Exception('No invoice data found for job $jobId');
      }

      // The RPC function returns properly formatted invoice data
      final invoiceData = response as Map<String, dynamic>;
      return InvoiceData.fromJson(invoiceData);
    } catch (e) {
      if (e.toString().contains('Access denied')) {
        throw Exception(
          'Access denied: You do not have permission to access this job',
        );
      } else if (e.toString().contains('not found')) {
        throw Exception('Job not found or client is inactive');
      } else {
        throw Exception('Failed to fetch invoice data: $e');
      }
    }
  }

  Future<String> uploadInvoiceBytes({
    required String jobId,
    required Uint8List bytes,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = InvoiceConfigService.getStoragePath(jobId, timestamp);

      // Upload to Supabase Storage
      await _supabase.storage
          .from(InvoiceConfigService.storageBucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'application/pdf',
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(InvoiceConfigService.storageBucket)
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      if (e.toString().contains('403')) {
        throw Exception('Permission denied: Cannot upload invoice to storage');
      } else if (e.toString().contains('400')) {
        throw Exception('Invalid request: Check storage path and file format');
      } else {
        throw Exception('Failed to upload invoice: $e');
      }
    }
  }

  Future<void> linkInvoiceUrlToJob({
    required String jobId,
    required String url,
  }) async {
    try {
      await _supabase
          .from('jobs')
          .update({'invoice_pdf': url})
          .eq('id', int.parse(jobId));
    } catch (e) {
      throw Exception('Failed to link invoice URL to job: $e');
    }
  }

  Future<String> getPublicOrSignedUrl({required String storagePath}) async {
    try {
      // For now, return the public URL
      // In production, you might want to generate signed URLs for security
      return _supabase.storage
          .from(InvoiceConfigService.storageBucket)
          .getPublicUrl(storagePath);
    } catch (e) {
      throw Exception('Failed to get invoice URL: $e');
    }
  }
}
