import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice_data.dart';
import '../services/invoice_pdf_service.dart';
import '../services/invoice_repository.dart';

enum InvoiceControllerStatus {
  idle,
  loading,
  success,
  error,
}

class InvoiceControllerState {
  final InvoiceControllerStatus status;
  final String? errorMessage;
  final InvoiceData? invoiceData;

  const InvoiceControllerState({
    this.status = InvoiceControllerStatus.idle,
    this.errorMessage,
    this.invoiceData,
  });

  bool get isLoading => status == InvoiceControllerStatus.loading;
  bool get hasError => status == InvoiceControllerStatus.error;
  bool get isSuccess => status == InvoiceControllerStatus.success;

  InvoiceControllerState copyWith({
    InvoiceControllerStatus? status,
    String? errorMessage,
    InvoiceData? invoiceData,
  }) {
    return InvoiceControllerState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      invoiceData: invoiceData ?? this.invoiceData,
    );
  }
}

class InvoiceController extends StateNotifier<InvoiceControllerState> {
  final InvoiceRepository _repository;
  final InvoicePdfService _pdfService;

  InvoiceController(this._repository, this._pdfService)
      : super(const InvoiceControllerState());

  Future<void> createInvoice({required String jobId}) async {
    try {
      state = state.copyWith(status: InvoiceControllerStatus.loading);

      // Fetch invoice data
      final invoiceData = await _repository.fetchInvoiceData(jobId: jobId);

      // Generate PDF
      final pdfBytes = await _pdfService.buildInvoicePdf(invoiceData);

      // Upload to storage
      final storageUrl = await _repository.uploadInvoiceBytes(
        jobId: jobId,
        bytes: pdfBytes,
      );

      // Link to job
      await _repository.linkInvoiceUrlToJob(
        jobId: jobId,
        url: storageUrl,
      );

      state = state.copyWith(
        status: InvoiceControllerStatus.success,
        invoiceData: invoiceData,
      );
    } catch (e) {
      state = state.copyWith(
        status: InvoiceControllerStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> regenerateInvoice({required String jobId}) async {
    try {
      state = state.copyWith(status: InvoiceControllerStatus.loading);

      // Fetch updated invoice data
      final invoiceData = await _repository.fetchInvoiceData(jobId: jobId);

      // Generate new PDF
      final pdfBytes = await _pdfService.buildInvoicePdf(invoiceData);

      // Upload to storage (overwrite existing)
      final storageUrl = await _repository.uploadInvoiceBytes(
        jobId: jobId,
        bytes: pdfBytes,
      );

      // Update job link
      await _repository.linkInvoiceUrlToJob(
        jobId: jobId,
        url: storageUrl,
      );

      state = state.copyWith(
        status: InvoiceControllerStatus.success,
        invoiceData: invoiceData,
      );
    } catch (e) {
      state = state.copyWith(
        status: InvoiceControllerStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  void reset() {
    state = const InvoiceControllerState();
  }
}

final invoiceControllerProvider =
    StateNotifierProvider<InvoiceController, InvoiceControllerState>((ref) {
  final repository = ref.watch(invoiceRepositoryProvider);
  final pdfService = ref.watch(invoicePdfServiceProvider);
  return InvoiceController(repository, pdfService);
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository();
});

final invoicePdfServiceProvider = Provider<InvoicePdfService>((ref) {
  return InvoicePdfService();
});
