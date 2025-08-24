import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice_data.dart';

class InvoiceRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<InvoiceData> fetchInvoiceData({required String jobId}) async {
    try {
      // Temporarily use the voucher function until we create the invoice function
      final response = await _supabase.rpc(
        'get_voucher_data_for_pdf',
        params: {'p_voucher_id': int.parse(jobId)},
      );

      if (response == null) {
        throw Exception('No invoice data found for job $jobId');
      }

      // Convert voucher data to invoice data format
      final voucherData = response as Map<String, dynamic>;
      
      // Create invoice-specific data with proper null handling
      final invoiceData = {
        'job_id': voucherData['job_id'] ?? 0,
        'quote_no': voucherData['quote_no'] ?? '',
        'quote_date': voucherData['quote_date'] ?? DateTime.now().toIso8601String(),
        'company_name': voucherData['company_name'] ?? 'Choice Lux Cars',
        'company_logo': voucherData['company_logo'] ?? '',
        'agent_name': voucherData['agent_name'] ?? 'Not available',
        'agent_contact': voucherData['agent_contact'] ?? 'Not available',
        'passenger_name': voucherData['passenger_name'] ?? 'Not specified',
        'passenger_contact': voucherData['passenger_contact'] ?? 'Not specified',
        'number_passengers': voucherData['number_passangers'] ?? 0, // Fix field name
        'luggage': voucherData['luggage'] ?? 'Not specified',
        'driver_name': voucherData['driver_name'] ?? 'Not assigned',
        'driver_contact': voucherData['driver_contact'] ?? 'Not available',
        'vehicle_type': voucherData['vehicle_type'] ?? 'Not assigned',
        'transport': voucherData['transport'] ?? [],
        'notes': voucherData['notes'] ?? '',
        'invoice_number': 'INV-${jobId}',
        'invoice_date': DateTime.now().toIso8601String(),
        'due_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'subtotal': (voucherData['amount'] ?? 0) * 0.85, // 85% of total
        'tax_amount': (voucherData['amount'] ?? 0) * 0.15, // 15% VAT
        'total_amount': voucherData['amount'] ?? 0,
        'currency': 'ZAR',
        'payment_terms': 'Payment due within 30 days',
        'banking_details': {
          'bank_name': 'Standard Bank',
          'account_name': 'Choice Lux Cars (Pty) Ltd',
          'account_number': '1234567890',
          'branch_code': '051001',
          'swift_code': 'SBZAZAJJ',
          'reference': 'INV-$jobId'
        }
      };

      return InvoiceData.fromJson(invoiceData);
    } catch (e) {
      throw Exception('Failed to fetch invoice data: $e');
    }
  }

  Future<String> uploadInvoiceBytes({
    required String jobId,
    required Uint8List bytes,
  }) async {
    try {
      final fileName = 'invoice_${jobId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final storagePath = 'pdfdocuments/invoices/$fileName';

      // Upload to Supabase Storage
      await _supabase.storage
          .from('pdfdocuments')
          .uploadBinary(storagePath, bytes, fileOptions: const FileOptions(
            upsert: true,
            contentType: 'application/pdf',
          ));

      // Get public URL
      final publicUrl = _supabase.storage
          .from('pdfdocuments')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload invoice: $e');
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
          .from('pdfdocuments')
          .getPublicUrl(storagePath);
    } catch (e) {
      throw Exception('Failed to get invoice URL: $e');
    }
  }
}
