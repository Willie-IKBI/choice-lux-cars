import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:choice_lux_cars/features/invoices/models/invoice_data.dart';
import 'package:choice_lux_cars/features/pdf/pdf_theme.dart';

class InvoicePdfService {
  static const String logoUrl =
      'https://hgqrbekphumdlsifuamq.supabase.co/storage/v1/object/public/clc_images/app_images/logo%20-%20512.png';

  // ---- THEME / TOKENS -------------------------------------------------------

  // Using shared PdfTheme for consistent styling across all documents

  // ---- PUBLIC API -----------------------------------------------------------

  Future<Uint8List> buildInvoicePdf(InvoiceData data) async {
    try {
      // Load logo (graceful fallback)
      pw.MemoryImage? logoImage;
      try {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {
        /* ignore */
      }

      final currency = NumberFormat.currency(locale: 'en_ZA', symbol: 'R');
      final dateFormat = DateFormat('dd/MM/yyyy');

      final doc = pw.Document();

      final pageTheme = PdfTheme.buildPageTheme(
        watermarkBuilder: (context) => PdfTheme.buildInvoiceWatermark(),
      );

      doc.addPage(
        pw.MultiPage(
          pageTheme: pageTheme,
          header: (context) => context.pageNumber == 1
              ? PdfTheme.buildHeroHeader(
                  logo: logoImage,
                  companyName: 'Choice Lux Cars',
                ) // page 1
              : PdfTheme.buildCompactHeader(
                  logo: logoImage,
                  documentNumber: data.invoiceNumber.replaceFirst('INV-', ''),
                ), // page 2+
          footer: (context) => PdfTheme.buildFooter(
            'www.choiceluxcars.com | bookings@choiceluxcars.com',
          ),
          build: (context) => [
            _sectionInvoiceSummary(data, dateFormat),
            pw.SizedBox(height: PdfTheme.spacing20),

            _sectionEnhancedTwoColumn(data, currency),
            pw.SizedBox(height: PdfTheme.spacing20),

            _sectionTransportDetails(data, dateFormat),
            pw.SizedBox(height: PdfTheme.spacing20),

            _sectionBankingDetails(data),
            pw.SizedBox(height: PdfTheme.spacing20),

            _sectionTermsAndConditions(),
          ],
        ),
      );

      return doc.save();
    } catch (e) {
      throw Exception('Failed to generate invoice PDF: $e');
    }
  }

  // ---- WATERMARK ------------------------------------------------------------

  // Using shared PdfTheme.buildInvoiceWatermark() instead

  // ---- HEADERS / FOOTER -----------------------------------------------------

  // Using shared PdfTheme.buildHeroHeader() and PdfTheme.buildCompactHeader() instead

  // ---- SECTION CARDS --------------------------------------------------------

  pw.Widget _sectionCard({
    required String title,
    required pw.Widget child,
    pw.Widget? footer,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfTheme.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(PdfTheme.radius),
        color: PdfTheme.grey100,
      ),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                font: PdfTheme.fontBold,
                fontSize: 16,
                color: PdfColors.black,
              ),
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(PdfTheme.radius - 1),
                bottomRight: pw.Radius.circular(PdfTheme.radius - 1),
              ),
            ),
            child: child,
          ),
          if (footer != null) footer,
        ],
      ),
    );
  }

  // ---- SECTIONS -------------------------------------------------------------

  // Simple section header for long sections
  pw.Widget _sectionHeader(String title) {
    return PdfTheme.buildSectionHeader(title);
  }

  // Sub-section header for smaller sections
  pw.Widget _sectionSubHeader(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        font: PdfTheme.fontBold,
        fontSize: 12,
        color: PdfTheme.grey700,
      ),
    );
  }

  // Card section for short content (keeps existing design)
  pw.Widget _sectionInvoiceSummary(InvoiceData data, DateFormat dateFormat) {
    return _sectionCard(
      title: 'INVOICE SUMMARY',
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Transport Services',
                  style: pw.TextStyle(
                    font: PdfTheme.fontBold,
                    fontSize: 14,
                    color: PdfTheme.grey700,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Professional chauffeur service for ${data.numberPassengers} passenger(s)',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfTheme.grey700,
                    lineSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: PdfTheme.spacing20),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _kv(
                'Invoice Number',
                data.invoiceNumber.replaceFirst('INV-', ''),
              ),
              _kv('Invoice Date', dateFormat.format(data.invoiceDate)),
              _kv('Due Date', dateFormat.format(data.dueDate)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionEnhancedTwoColumn(InvoiceData data, NumberFormat currency) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('SERVICE DETAILS'),
        
        // Client & Agent Information (top section)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _sectionSubHeader('CLIENT & AGENT INFORMATION'),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Client
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: _innerBox(),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _subTitle('Client'),
                        pw.SizedBox(height: 8),
                        _infoRow('Company', data.companyName),
                        if (data.clientContactPerson != null)
                          _infoRow('Contact Person', data.clientContactPerson!),
                        if (data.clientContactNumber != null)
                          _infoRow('Phone', data.clientContactNumber!),
                        if (data.clientContactEmail != null)
                          _infoRow('Email', data.clientContactEmail!),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                // Agent
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: _innerBox(),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _subTitle('Agent'),
                        pw.SizedBox(height: 8),
                        _infoRow('Agent', data.agentName),
                        _infoRow('Contact', data.agentContact),
                        if (data.agentEmail != null)
                          _infoRow('Email', data.agentEmail!),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        pw.SizedBox(height: PdfTheme.spacing16),
        
        // Service & Payment Information (bottom section, full width)
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _sectionSubHeader('SERVICE & PAYMENT'),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: _innerBox(),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Service Details (left side)
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _subTitle('Service Details'),
                        pw.SizedBox(height: 12),
                        _infoRow('Passenger', data.passengerName),
                        _infoRow('Job Number', data.jobId.toString()),
                        _infoRow('Vehicle', data.vehicleType),
                        _infoRow('Driver', data.driverName),
                        _infoRow('Passengers', '${data.numberPassengers}'),
                        _infoRow('Luggage', data.luggage),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: PdfTheme.spacing20),
                  // Payment Summary (right side)
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _subTitle('Payment Summary'),
                        pw.SizedBox(height: 12),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Total Amount:',
                              style: pw.TextStyle(
                                font: PdfTheme.fontBold,
                                fontSize: 12,
                                color: PdfTheme.grey800,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              data.formattedTotalAmount.replaceAll('ZAR', 'R'),
                              style: pw.TextStyle(
                                font: PdfTheme.fontBold,
                                fontSize: 16,
                                color: PdfTheme.grey800,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 12),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            color: PdfTheme.gold50,
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: PdfTheme.gold400, width: 0.5),
                          ),
                          child: pw.Text(
                            'Payment on Receipt',
                            style: pw.TextStyle(
                              font: PdfTheme.fontBold,
                              fontSize: 12,
                              color: PdfTheme.gold700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }


  pw.Widget _sectionTransportDetails(InvoiceData data, DateFormat dateFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('TRANSPORT DETAILS'),
        if (data.transport.isNotEmpty)
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfTheme.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.TableHelper.fromTextArray(
              context: null,
              headers: ['Date', 'Time', 'Pickup Location', 'Dropoff Location'],
              data: data.transport.map((trip) {
                return [
                  trip.formattedDate,
                  trip.time,
                  trip.pickupLocation,
                  trip.dropoffLocation,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                font: PdfTheme.fontBold,
                fontSize: 11,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfTheme.grey700,
              ),
              cellStyle: pw.TextStyle(
                fontSize: 10,
                color: PdfTheme.grey800,
              ),
              cellDecoration: (int index, dynamic data, int columnIndex) => pw.BoxDecoration(
                border: pw.Border.all(color: PdfTheme.grey300, width: 0.5),
                color: index % 2 == 0 ? PdfColors.white : PdfTheme.grey100,
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(80), // Date
                1: const pw.FixedColumnWidth(60), // Time
                2: const pw.FlexColumnWidth(2),   // Pickup Location
                3: const pw.FlexColumnWidth(2),   // Dropoff Location
              },
            ),
          )
        else
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: _innerBox(),
            child: pw.Center(
              child: pw.Column(
                children: [
                  pw.Icon(
                    pw.IconData(0xe7f2), // transport icon
                    size: 24,
                    color: PdfTheme.grey300,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'No transport details available',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfTheme.grey600,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }


  pw.Widget _sectionBankingDetails(InvoiceData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('BANKING DETAILS'),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Banking Information
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: _innerBox(),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _subTitle('Payment Information'),
                    pw.SizedBox(height: 12),
                    _infoRow('Bank', data.bankingDetails.bankName),
                    _infoRow('Account Name', data.bankingDetails.accountName),
                    _infoRow('Account Number', data.bankingDetails.accountNumber),
                    _infoRow('Branch Code', data.bankingDetails.branchCode),
                    _infoRow('Swift Code', data.bankingDetails.swiftCode),
                    if (data.bankingDetails.reference != null)
                      _infoRow('Reference', data.bankingDetails.reference!),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: PdfTheme.spacing16),
            // Payment Terms
            pw.Expanded(
              flex: 1,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfTheme.gold50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfTheme.gold400, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _subTitle('Payment Terms'),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Payment must be made on receipt of invoice.',
                      style: pw.TextStyle(
                        font: PdfTheme.fontBold,
                        fontSize: 11,
                        color: PdfTheme.gold700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'No service delivery without payment.',
                      style: pw.TextStyle(
                        font: PdfTheme.fontBold,
                        fontSize: 11,
                        color: PdfTheme.gold700,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Divider(color: PdfTheme.gold400, thickness: 0.5),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Please use Invoice Number as payment reference',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfTheme.gold700,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _sectionTermsAndConditions() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('TERMS & CONDITIONS'),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _numberedTerm(1, 'Payment must be made on receipt of invoice.'),
            _numberedTerm(2, 'No service delivery without payment.'),
            _numberedTerm(
              3,
              'All prices include VAT and are quoted in South African Rands (ZAR).',
            ),
            _numberedTerm(
              4,
              'For any queries regarding this invoice, please contact the agent listed.',
            ),
            _numberedTerm(
              5,
              'Thank you for choosing Choice Lux Cars for your transportation needs.',
            ),
          ],
        ),
      ],
    );
  }

  // ---- SMALL HELPERS --------------------------------------------------------

  pw.BoxDecoration _innerBox() => pw.BoxDecoration(
    color: PdfColors.white,
    borderRadius: pw.BorderRadius.circular(6),
    border: pw.Border.all(color: PdfTheme.grey300, width: 0.5),
  );

  pw.Widget _subTitle(String text) => pw.Text(
    text,
    style: pw.TextStyle(
      font: PdfTheme.fontBold,
      fontSize: 14,
      color: PdfTheme.grey800,
    ),
  );

  pw.Widget _kv(String k, String v) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$k: ',
          style: pw.TextStyle(
            font: PdfTheme.fontBold,
            fontSize: 11,
            color: PdfTheme.grey600,
          ),
        ),
        pw.Text(v, style: pw.TextStyle(fontSize: 11, color: PdfTheme.grey800)),
      ],
    ),
  );

  pw.Widget _infoRow(String label, String value) {
    return PdfTheme.buildInfoRow(label, value);
  }

  pw.Widget _numberedTerm(int n, String text) {
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
                '$n',
                style: pw.TextStyle(
                  font: PdfTheme.fontBold,
                  fontSize: 8,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfTheme.grey700,
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
}
