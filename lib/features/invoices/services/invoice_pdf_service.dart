import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:choice_lux_cars/features/invoices/models/invoice_data.dart';
import 'package:choice_lux_cars/features/pdf/pdf.dart';

class InvoicePdfService {

  // ---- PUBLIC API -----------------------------------------------------------

  Future<Uint8List> buildInvoicePdf(InvoiceData data) async {
    try {
      // Load logo using shared utility
      final logoImage = await PdfUtilities.loadLogo(PdfConfig.defaultLogoUrl);

      final currency = NumberFormat.currency(
        locale: PdfConfig.defaultLocale, 
        symbol: PdfConfig.defaultCurrencySymbol,
      );
      final dateFormat = DateFormat(PdfConfig.defaultDateFormat);

      final doc = pw.Document();

      final pageTheme = PdfTheme.buildPageTheme(
        watermarkBuilder: (context) => PdfTheme.buildInvoiceWatermark(),
      );

      doc.addPage(
        pw.MultiPage(
          pageTheme: pageTheme,
          header: (context) => context.pageNumber == 1
              ? _buildInvoiceHeader(logoImage) // page 1
              : PdfTheme.buildCompactHeader(
                  logo: logoImage,
                  documentNumber: data.invoiceNumber.replaceFirst('INV-', ''),
                ), // page 2+
          footer: (context) => _buildInvoiceFooter(),
          build: (context) => [
            _sectionInvoiceSummary(data, dateFormat),
            PdfTheme.buildProfessionalSpacing(height: PdfTheme.spacing8),

            _sectionClientAgent(data),
            PdfTheme.buildProfessionalSpacing(height: PdfTheme.spacing8),

            _sectionServicePayment(data, currency),
            PdfTheme.buildProfessionalSpacing(height: PdfTheme.spacing8),

            _sectionTransportDetails(data, dateFormat),
            PdfTheme.buildProfessionalSpacing(height: PdfTheme.spacing8),

            _sectionBankingDetails(data),
            PdfTheme.buildProfessionalSpacing(height: PdfTheme.spacing8),

            _sectionTermsAndConditions(),
          ],
        ),
      );

      return await doc.save();
    } catch (e) {
      throw PdfUtilities.createPdfException('invoice', e);
    }
  }

  // ---- SECTIONS (using voucher-style layout patterns) ------------------------

  pw.Widget _sectionInvoiceSummary(InvoiceData data, DateFormat dateFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfTheme.buildCleanSectionHeader('INVOICE SUMMARY'),
        pw.Container(
          width: double.infinity,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Transport Services', style: PdfTheme.titleSmall),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Professional chauffeur service for ${data.numberPassengers} passenger(s)',
                      style: PdfTheme.bodyText.copyWith(lineSpacing: 2),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: PdfTheme.spacing20),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  PdfUtilities.buildKeyValue('Invoice Number', data.invoiceNumber.replaceFirst('INV-', '')),
                  PdfUtilities.buildKeyValue('Invoice Date', dateFormat.format(data.invoiceDate)),
                  PdfUtilities.buildKeyValue('Due Date', dateFormat.format(data.dueDate)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionClientAgent(InvoiceData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfTheme.buildCleanSectionHeader('CLIENT & AGENT INFORMATION'),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Client Information Section - Professional Layout
              pw.Text(
                'Bill To:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                data.companyName,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              if (data.clientContactPerson != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  data.clientContactPerson!,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
              if (data.clientContactNumber != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  data.clientContactNumber!,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
              if (data.clientContactEmail != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  data.clientContactEmail!,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
              if (data.clientBillingAddress != null && data.clientBillingAddress!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  data.clientBillingAddress!,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
              if (data.clientCompanyRegistration != null && data.clientCompanyRegistration!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Reg: ${data.clientCompanyRegistration!}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
              if (data.clientVatNumber != null && data.clientVatNumber!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'VAT: ${data.clientVatNumber!}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
              if (data.clientWebsite != null && data.clientWebsite!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Website: ${data.clientWebsite!}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
              
              pw.SizedBox(height: 12),
              
              // Agent Information Section - Professional Layout
              pw.Text(
                'Contact:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                data.agentName,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                data.agentContact,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              if (data.agentEmail != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  data.agentEmail!,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionServicePayment(InvoiceData data, NumberFormat currency) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfTheme.buildCleanSectionHeader('SERVICE & PAYMENT'),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Service Details - Professional Layout
              pw.Text(
                'Service Details:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Passenger: ${data.passengerName}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Job Number: ${data.jobId}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Vehicle: ${data.vehicleType}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Driver: ${data.driverName}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Passengers: ${data.numberPassengers} | Luggage: ${data.luggage}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              
              pw.SizedBox(height: 12),
              
              // Payment Summary - Professional Layout
              pw.Text(
                'Payment Summary:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Amount:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.Text(
                      data.formattedTotalAmount.replaceAll('ZAR', 'R'),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Payment Terms: ${data.paymentTerms}',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionTransportDetails(InvoiceData data, DateFormat dateFormat) {
    if (data.transport.isEmpty) {
      return pw.SizedBox.shrink();
    }

    final table = pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfTheme.grey300, width: 0.5),
      headerStyle: PdfTheme.labelText.copyWith(color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
      cellStyle: PdfTheme.bodyText.copyWith(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(
        horizontal: PdfTheme.spacing12,
        vertical: PdfTheme.spacing8,
      ),
      headers: ['Date', 'Time', 'Pick-Up Location', 'Drop-Off Location'],
      data: data.transport.map((trip) {
        return [
          DateFormat('dd MMM yyyy').format(trip.date),
          trip.time,
          trip.pickupLocation,
          trip.dropoffLocation,
        ];
      }).toList(),
      columnWidths: {
        0: const pw.FixedColumnWidth(85),  // Date column
        1: const pw.FixedColumnWidth(65),  // Time column
        2: const pw.FlexColumnWidth(1.2),  // Pick-Up Location
        3: const pw.FlexColumnWidth(1.2),  // Drop-Off Location
      },
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [PdfTheme.buildCleanSectionHeader('TRANSPORT DETAILS'), table],
    );
  }

  pw.Widget _sectionBankingDetails(InvoiceData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfTheme.buildCleanSectionHeader('BANKING DETAILS'),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Banking Information - Professional Layout
              pw.Text(
                'Payment Information:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Bank: ABSA Bank',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Account Name: CHOICELUX CARS (PTY) LTD',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Account Number: 411 511 5471',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Branch Code: 632005',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Account Type: Current Account',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              if (data.bankingDetails.reference != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Reference: ${data.bankingDetails.reference!}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
              
              pw.SizedBox(height: 12),
              
              // Payment Terms - Professional Layout
              pw.Text(
                'Payment Terms:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                data.paymentTerms,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionTermsAndConditions() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfTheme.buildCleanSectionHeader('TERMS & CONDITIONS'),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfUtilities.buildNumberedTerm(1, 'Payment is due upon receipt of this invoice.'),
            PdfUtilities.buildNumberedTerm(2, 'Late payments may incur additional charges.'),
            PdfUtilities.buildNumberedTerm(3, 'All services are subject to our standard terms and conditions.'),
            PdfUtilities.buildNumberedTerm(4, 'For any queries, please contact us using the details provided.'),
          ],
        ),
      ],
    );
  }

  // ---- CUSTOM HEADER & FOOTER FOR INVOICE -------------------------------------

  /// Build professional invoice header with complete company branding
  pw.Widget _buildInvoiceHeader(pw.MemoryImage? logoImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: PdfTheme.spacing8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo
              if (logoImage != null)
                pw.Container(
                  height: 50,
                  width: 120,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              pw.SizedBox(width: PdfTheme.spacing12),
              // Company name and details
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Choice Lux Cars',
                      style: PdfTheme.titleLarge.copyWith(
                        color: PdfTheme.brandBlack,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: PdfTheme.spacing4),
                    pw.Text(
                      'Professional Chauffeur Services',
                      style: PdfTheme.bodyText.copyWith(
                        color: PdfTheme.grey600,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              // Contact details
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'info@choiceluxcars.com',
                    style: PdfTheme.bodyText.copyWith(
                      color: PdfTheme.brandBlack,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'www.choiceluxcars.com',
                    style: PdfTheme.bodyText.copyWith(
                      color: PdfTheme.grey600,
                    ),
                  ),
                  pw.Text(
                    'Reg: 202442067307',
                    style: PdfTheme.captionText.copyWith(
                      color: PdfTheme.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Contact strip
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: const pw.BoxDecoration(
            color: PdfTheme.grey100,
            borderRadius: pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(PdfTheme.radius),
              bottomRight: pw.Radius.circular(PdfTheme.radius),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Phone: +27 74 239 2222',
                style: PdfTheme.bodyText.copyWith(
                  color: PdfTheme.grey700,
                ),
              ),
              pw.Text(
                'Address: 25 Johnson Road, Bedfordview, Johannesburg',
                style: PdfTheme.bodyText.copyWith(
                  color: PdfTheme.grey700,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: PdfTheme.spacing16),
      ],
    );
  }

  /// Build professional invoice footer with company details
  pw.Widget _buildInvoiceFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: PdfTheme.spacing16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfTheme.grey300, width: 1)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'www.choiceluxcars.com | info@choiceluxcars.com',
            style: PdfTheme.captionText.copyWith(
              color: PdfTheme.grey600,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: PdfTheme.spacing4),
          pw.Text(
            'Company Registration: 202442067307 | VAT Number: 402042067307',
            style: PdfTheme.captionText.copyWith(
              color: PdfTheme.grey600,
              fontSize: 8,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}