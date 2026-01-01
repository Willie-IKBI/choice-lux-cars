import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:choice_lux_cars/features/vouchers/models/voucher_data.dart';
import 'package:choice_lux_cars/features/vouchers/services/voucher_repository.dart';
import 'package:choice_lux_cars/features/vouchers/services/voucher_pdf_service.dart';
import 'package:choice_lux_cars/features/jobs/jobs.dart';

// Provider for VoucherRepository
final voucherRepositoryProvider = Provider<VoucherRepository>((ref) {
  final supabase = Supabase.instance.client;
  return VoucherRepository(supabase);
});

// Provider for VoucherPdfService
final voucherPdfServiceProvider = Provider<VoucherPdfService>((ref) {
  return VoucherPdfService();
});

// State for voucher creation process
enum VoucherState { idle, fetching, generating, uploading, success, error }

class VoucherControllerState {
  final VoucherState state;
  final String? errorMessage;
  final String? voucherUrl;
  final VoucherData? voucherData;

  const VoucherControllerState({
    this.state = VoucherState.idle,
    this.errorMessage,
    this.voucherUrl,
    this.voucherData,
  });

  VoucherControllerState copyWith({
    VoucherState? state,
    String? errorMessage,
    String? voucherUrl,
    VoucherData? voucherData,
  }) {
    return VoucherControllerState(
      state: state ?? this.state,
      errorMessage: errorMessage,
      voucherUrl: voucherUrl ?? this.voucherUrl,
      voucherData: voucherData ?? this.voucherData,
    );
  }

  bool get isIdle => state == VoucherState.idle;
  bool get isLoading =>
      state == VoucherState.fetching ||
      state == VoucherState.generating ||
      state == VoucherState.uploading;
  bool get isSuccess => state == VoucherState.success;
  bool get hasError => state == VoucherState.error;

  String get loadingMessage {
    switch (state) {
      case VoucherState.fetching:
        return 'Fetching voucher data...';
      case VoucherState.generating:
        return 'Generating PDF...';
      case VoucherState.uploading:
        return 'Uploading voucher...';
      default:
        return 'Processing...';
    }
  }
}

// VoucherController
class VoucherController extends StateNotifier<VoucherControllerState> {
  final VoucherRepository _repository;
  final VoucherPdfService _pdfService;
  final Ref? _ref;

  VoucherController(this._repository, this._pdfService, [this._ref])
    : super(const VoucherControllerState());

  /// Create voucher for a job
  Future<void> createVoucher({required String jobId}) async {
    try {
      // Check if user has permission to create vouchers
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch user profile to check role
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      final userRole = profile['role'] as String?;
      if (!_canCreateVoucher(userRole)) {
        throw Exception('Insufficient permissions to create vouchers');
      }

      // Step 1: Fetch voucher data
      state = state.copyWith(state: VoucherState.fetching);
      final voucherData = await _repository.fetchVoucherData(
        jobId: int.parse(jobId),
      );
      state = state.copyWith(voucherData: voucherData);

      // Step 2: Generate PDF
      state = state.copyWith(state: VoucherState.generating);
      final pdfBytes = await _pdfService.buildVoucherPdf(voucherData);

      // Step 3: Upload and link
      state = state.copyWith(state: VoucherState.uploading);
      final voucherUrl = await _repository.uploadAndLinkVoucher(
        jobId: int.parse(jobId),
        bytes: pdfBytes,
      );

      // Success
      state = state.copyWith(
        state: VoucherState.success,
        voucherUrl: voucherUrl,
      );

      // Refresh jobs list to update the UI
      if (_ref != null && mounted) {
        final jobsNotifier = _ref.read(jobsProvider.notifier);
        await jobsNotifier.refreshJobs();
      }
    } catch (e) {
      state = state.copyWith(
        state: VoucherState.error,
        errorMessage: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  /// Regenerate voucher for a job
  Future<void> regenerateVoucher({required String jobId}) async {
    try {
      // Clear existing voucher first
      await _repository.clearVoucherUrl(jobId: int.parse(jobId));
      await _repository.deleteVoucherFile(jobId: int.parse(jobId));

      // Create new voucher
      await createVoucher(jobId: jobId);

      // Refresh jobs list to update the UI
      if (_ref != null && mounted) {
        final jobsNotifier = _ref.read(jobsProvider.notifier);
        await jobsNotifier.refreshJobs();
      }
    } catch (e) {
      state = state.copyWith(
        state: VoucherState.error,
        errorMessage: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  /// Reset state to idle
  void reset() {
    state = const VoucherControllerState();
  }

  /// Check if user can create vouchers based on role
  bool _canCreateVoucher(String? userRole) {
    if (userRole == null) return false;

    // Handle both role variations (admin/administrator, driver_manager/driverManager)
    const allowedRoles = [
      'admin',
      'administrator',
      'super_admin',
      'manager',
      'driver_manager',
      'drivermanager',
    ];
    return allowedRoles.contains(userRole.toLowerCase());
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is PostgrestException) {
      return 'Database error: ${error.message}';
    } else if (error is StorageException) {
      return 'Storage error: ${error.message}';
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    } else {
      return 'An unexpected error occurred';
    }
  }

  /// Get loading message based on current state
  String get loadingMessage {
    switch (state.state) {
      case VoucherState.fetching:
        return 'Fetching voucher data...';
      case VoucherState.generating:
        return 'Generating voucher PDF...';
      case VoucherState.uploading:
        return 'Uploading voucher...';
      default:
        return '';
    }
  }
}

// Provider for VoucherController
final voucherControllerProvider =
    StateNotifierProvider<VoucherController, VoucherControllerState>((ref) {
      final repository = ref.watch(voucherRepositoryProvider);
      final pdfService = ref.watch(voucherPdfServiceProvider);
      return VoucherController(repository, pdfService, ref);
    });

// Provider for checking if user can create vouchers
final canCreateVoucherProvider = FutureProvider<bool>((ref) async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    final userRole = profile['role'] as String?;
    // Handle both role variations (admin/administrator, driver_manager/driverManager)
    const allowedRoles = [
      'admin',
      'administrator',
      'super_admin',
      'manager',
      'driver_manager',
      'drivermanager',
    ];
    return allowedRoles.contains(userRole?.toLowerCase());
  } catch (e) {
    return false;
  }
});
