import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:choice_lux_cars/features/pdf/pdf_theme.dart';

/// Shared PDF utilities to eliminate code duplication across all PDF services
/// 
/// This class provides common functionality used by:
/// - InvoicePdfService
/// - VoucherPdfService  
/// - QuotePdfService
class PdfUtilities {
  // ---- LOGO LOADING ---------------------------------------------------------

  /// Load logo image from URL with graceful fallback
  /// 
  /// Returns null if logo cannot be loaded (no exception thrown)
  static Future<pw.MemoryImage?> loadLogo(String? logoUrl) async {
    if (logoUrl == null || logoUrl.isEmpty) return null;
    
    try {
      final response = await http.get(Uri.parse(logoUrl));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (_) {
      // Graceful fallback - return null if logo cannot be loaded
    }
    return null;
  }

  // ---- COMMON WIDGETS -------------------------------------------------------

  /// Build a key-value pair row (replaces _kv methods)
  /// 
  /// Used for displaying label: value pairs in PDFs
  static pw.Widget buildKeyValue(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '$key: ',
            style: PdfTheme.labelText.copyWith(color: PdfTheme.grey600),
          ),
          pw.Text(
            value,
            style: PdfTheme.bodyText.copyWith(color: PdfTheme.grey800),
          ),
        ],
      ),
    );
  }

  /// Build a numbered term for terms & conditions (replaces _numberedTerm methods)
  /// 
  /// Used for displaying numbered lists in PDFs
  static pw.Widget buildNumberedTerm(int number, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 1, right: 8),
            width: 16,
            height: 16,
            decoration: pw.BoxDecoration(
              color: PdfTheme.grey700,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(
              child: pw.Text(
                '$number',
                style: PdfTheme.captionText.copyWith(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: PdfTheme.bodyText.copyWith(
                lineSpacing: 1.2,
              ),
              softWrap: true,
              overflow: pw.TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  /// Build an info row for displaying label-value pairs (replaces _infoRow methods)
  /// 
  /// Used for displaying structured information in PDFs
  static pw.Widget buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Container(
        width: double.infinity,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: PdfTheme.labelWidth,
              child: pw.Text(
                '$label:',
                style: PdfTheme.labelText.copyWith(color: PdfTheme.grey600),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: PdfTheme.bodyText.copyWith(color: PdfTheme.grey800),
                softWrap: true,
                overflow: pw.TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- ERROR HANDLING -------------------------------------------------------

  /// Standardized error handling for PDF generation
  /// 
  /// Wraps PDF generation errors with consistent messaging
  static String handlePdfError(dynamic error, String serviceName) {
    final errorMessage = error.toString().replaceAll('Exception: ', '');
    return 'Failed to generate $serviceName PDF: $errorMessage';
  }

  /// Create a standardized PDF generation exception
  static Exception createPdfException(String serviceName, dynamic originalError) {
    return Exception(handlePdfError(originalError, serviceName));
  }
}
