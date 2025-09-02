import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Shared PDF theme and styling for consistent document generation
///
/// This class provides centralized access to:
/// - Brand colors matching AppTokens
/// - Typography and text styles
/// - Spacing and layout constants
/// - Header/footer builders
/// - Watermark helpers
class PdfTheme {
  // ---- BRAND COLORS (matching AppTokens) -----------------------------------

  /// Primary brand gold color
  static const PdfColor brandGold = PdfColor.fromInt(0xFFD4AF37);

  /// Brand black color
  static const PdfColor brandBlack = PdfColor.fromInt(0xFF0A0A0A);

  /// Secondary gold variants
  static const PdfColor gold700 = PdfColor.fromInt(0xFFB38600);
  static const PdfColor gold400 = PdfColor.fromInt(0xFFD4A800);
  static const PdfColor gold50 = PdfColor.fromInt(0xFFFFF9E6);

  /// Grey palette for text and backgrounds
  static const PdfColor grey800 = PdfColor.fromInt(0xFF323F4B);
  static const PdfColor grey700 = PdfColor.fromInt(0xFF3E4C59);
  static const PdfColor grey600 = PdfColor.fromInt(0xFF52606D);
  static const PdfColor grey300 = PdfColor.fromInt(0xFFCBD2D9);
  static const PdfColor grey100 = PdfColor.fromInt(0xFFF5F7FA);

  /// Semantic colors
  static const PdfColor errorColor = PdfColor.fromInt(0xFFDC2626);
  static const PdfColor successColor = PdfColor.fromInt(0xFF059669);
  static const PdfColor warningColor = PdfColor.fromInt(0xFFF59E0B);

  // ---- TYPOGRAPHY & FONTS --------------------------------------------------

  /// Regular font (Helvetica for compatibility)
  static pw.Font get fontRegular => pw.Font.helvetica();

  /// Bold font (Helvetica Bold for compatibility)
  static pw.Font get fontBold => pw.Font.helveticaBold();

  /// Large title style for document headers
  static pw.TextStyle get titleLarge =>
      pw.TextStyle(font: fontBold, fontSize: 28, color: grey800);

  /// Medium title style for section headers
  static pw.TextStyle get titleMedium =>
      pw.TextStyle(font: fontBold, fontSize: 20, color: grey800);

  /// Small title style for subsection headers
  static pw.TextStyle get titleSmall =>
      pw.TextStyle(font: fontBold, fontSize: 16, color: grey800);

  /// Body text style for regular content
  static pw.TextStyle get bodyText =>
      pw.TextStyle(font: fontRegular, fontSize: 12, color: grey700);

  /// Caption text style for small labels
  static pw.TextStyle get captionText =>
      pw.TextStyle(font: fontRegular, fontSize: 10, color: grey600);

  /// Label text style for form fields
  static pw.TextStyle get labelText =>
      pw.TextStyle(font: fontBold, fontSize: 12, color: grey700);

  // ---- SPACING & LAYOUT ----------------------------------------------------

  /// Standard spacing values
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;

  /// Border radius for containers
  static const double radius = 8;

  /// Label column width for info rows
  static const double labelWidth = 110;

  /// Page margins
  static const pw.EdgeInsets pageMargins = pw.EdgeInsets.all(25);

  // ---- HEADER BUILDERS -----------------------------------------------------

  /// Build hero header for page 1 (large logo, company name)
  static pw.Widget buildHeroHeader({
    required pw.MemoryImage? logo,
    required String companyName,
    String? logoUrl,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: spacing8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null)
                pw.Container(
                  height: 50,
                  width: 120,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                )
              else
                pw.Text(companyName, style: titleLarge),
              pw.SizedBox(width: spacing12),
              pw.Expanded(child: pw.Text(companyName, style: titleLarge)),
            ],
          ),
        ),
        // Contact strip
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: pw.BoxDecoration(
            color: grey100,
            borderRadius: pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(radius),
              bottomRight: pw.Radius.circular(radius),
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildContactRow([
                'Email: bookings@choiceluxcars.com',
                'Phone: +27 74 239 2222',
              ]),
              pw.SizedBox(height: spacing4),
              _buildContactRow([
                'Web: www.choiceluxcars.com',
                'Address: 25 Johnson Road, Bedfordview, Johannesburg',
              ]),
            ],
          ),
        ),
        pw.SizedBox(height: spacing16),
      ],
    );
  }

  /// Build compact header for subsequent pages (smaller logo, document number)
  static pw.Widget buildCompactHeader({
    required pw.MemoryImage? logo,
    required String documentNumber,
    String? logoUrl,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: spacing16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Container(
              height: 30,
              width: 80,
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            )
          else
            pw.Text('Choice Lux Cars', style: titleSmall),
          pw.SizedBox(width: spacing12),
          pw.Expanded(
            child: pw.Text(
              documentNumber,
              style: titleMedium,
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ---- FOOTER BUILDER ------------------------------------------------------

  /// Build consistent footer across all documents
  static pw.Widget buildFooter(String contactInfo) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: spacing16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: grey300, width: 1)),
      ),
      child: pw.Text(
        contactInfo,
        style: captionText,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // ---- WATERMARK HELPERS ---------------------------------------------------

  /// Build watermark for document type
  static pw.Widget buildWatermark(String documentType) {
    return pw.Stack(
      children: [
        pw.Positioned.fill(
          child: pw.Center(
            child: pw.Transform.rotate(
              angle: -0.5, // ~-28.6 degrees
              child: pw.Opacity(
                opacity: 0.06,
                child: pw.Text(
                  documentType,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 120,
                    color: grey300,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build watermark for quotes
  static pw.Widget buildQuoteWatermark() => buildWatermark('QUOTE');

  /// Build watermark for invoices
  static pw.Widget buildInvoiceWatermark() => buildWatermark('INVOICE');

  /// Build watermark for vouchers
  static pw.Widget buildVoucherWatermark() => buildWatermark('VOUCHER');

  // ---- HELPER METHODS ------------------------------------------------------

  /// Build contact information row
  static pw.Widget _buildContactRow(List<String> contacts) {
    return pw.Row(
      children: contacts.map((contact) {
        return pw.Expanded(child: pw.Text(contact, style: captionText));
      }).toList(),
    );
  }

  /// Build info row with label and value
  static pw.Widget buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: spacing4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: labelWidth,
            child: pw.Text(label, style: labelText),
          ),
          pw.Expanded(child: pw.Text(value, style: bodyText)),
        ],
      ),
    );
  }

  /// Build section header
  static pw.Widget buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        vertical: spacing12,
        horizontal: spacing16,
      ),
      decoration: pw.BoxDecoration(
        color: gold50,
        borderRadius: pw.BorderRadius.circular(radius),
        border: pw.Border.all(color: gold400, width: 1),
      ),
      child: pw.Text(title, style: titleMedium.copyWith(color: gold700)),
    );
  }

  /// Build page theme with consistent styling
  static pw.PageTheme buildPageTheme({
    required pw.Widget Function(pw.Context) watermarkBuilder,
  }) {
    return pw.PageTheme(
      margin: pageMargins,
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
      buildBackground: watermarkBuilder,
    );
  }
}
