import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/voucher_data.dart';

class VoucherRepository {
  final SupabaseClient _supabase;

  VoucherRepository(this._supabase);

  /// Fetch voucher data for PDF generation
  Future<VoucherData> fetchVoucherData({required int jobId}) async {
    try {
      final response = await _supabase.rpc(
        'get_voucher_data_for_job',
        params: {'p_job_id': jobId},
      );

      if (response == null) {
        throw Exception('No voucher data returned from server');
      }

      return VoucherData.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch voucher data: $e');
    }
  }

  /// Upload voucher PDF bytes to Supabase Storage
  Future<String> uploadVoucherBytes({
    required int jobId,
    required Uint8List bytes,
  }) async {
    try {
      const bucket = 'pdfdocuments';
      final path = 'vouchers/voucher_$jobId.pdf';

      // Upload the PDF file
      await _supabase.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'application/pdf',
          upsert: true,
        ),
      );

      // Get the public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(path);
      
      // Add cache buster to prevent stale caching
      final cacheBustedUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      
      return cacheBustedUrl;
    } on StorageException catch (e) {
      throw Exception('Storage upload error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload voucher PDF: $e');
    }
  }

  /// Link voucher URL to job in database
  Future<void> linkVoucherUrlToJob({
    required int jobId,
    required String url,
  }) async {
    try {
      await _supabase
          .from('jobs')
          .update({'voucher_pdf': url})
          .eq('id', jobId);
    } on PostgrestException catch (e) {
      throw Exception('Database update error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to link voucher URL to job: $e');
    }
  }

  /// Combined method to upload and link voucher
  Future<String> uploadAndLinkVoucher({
    required int jobId,
    required Uint8List bytes,
  }) async {
    try {
      // Upload the PDF
      final url = await uploadVoucherBytes(jobId: jobId, bytes: bytes);
      
      // Link to job
      await linkVoucherUrlToJob(jobId: jobId, url: url);
      
      return url;
    } catch (e) {
      throw Exception('Failed to upload and link voucher: $e');
    }
  }

  /// Get public URL for existing voucher
  Future<String> getPublicUrl({required int jobId}) async {
    try {
      const bucket = 'pdfdocuments';
      final path = 'vouchers/voucher_$jobId.pdf';
      
      return _supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to get voucher URL: $e');
    }
  }

  /// Check if voucher exists for a job
  Future<bool> voucherExists({required int jobId}) async {
    try {
      final response = await _supabase
          .from('jobs')
          .select('voucher_pdf')
          .eq('id', jobId)
          .single();

      return response['voucher_pdf'] != null && 
             response['voucher_pdf'].toString().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Delete voucher file from storage (for regeneration)
  Future<void> deleteVoucherFile({required int jobId}) async {
    try {
      const bucket = 'pdfdocuments';
      final path = 'vouchers/voucher_$jobId.pdf';
      
      await _supabase.storage.from(bucket).remove([path]);
    } on StorageException catch (e) {
      // Ignore if file doesn't exist
      if (!e.message.contains('not found')) {
        throw Exception('Failed to delete voucher file: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to delete voucher file: $e');
    }
  }

  /// Clear voucher URL from job (for regeneration)
  Future<void> clearVoucherUrl({required int jobId}) async {
    try {
      await _supabase
          .from('jobs')
          .update({'voucher_pdf': null})
          .eq('id', jobId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to clear voucher URL: ${e.message}');
    } catch (e) {
      throw Exception('Failed to clear voucher URL: $e');
    }
  }
}
