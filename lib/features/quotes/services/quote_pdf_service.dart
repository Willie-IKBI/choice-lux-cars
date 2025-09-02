import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:choice_lux_cars/core/config/env.dart';
import 'package:choice_lux_cars/features/quotes/models/quote.dart';
import 'package:choice_lux_cars/features/quotes/models/quote_transport_detail.dart';

class QuotePdfService {
  static const String _logoUrl =
      'https://hgqrbekphumdlsifuamq.supabase.co/storage/v1/object/public/clc_images/app_images/logo%20-%20512.png';

  // ---- THEME / TOKENS -------------------------------------------------------

  // Palette (grey + gold)
  static const PdfColor _grey800 = PdfColor.fromInt(0xFF323F4B);
  static const PdfColor _grey700 = PdfColor.fromInt(0xFF3E4C59);
  static const PdfColor _grey600 = PdfColor.fromInt(0xFF52606D);
  static const PdfColor _grey300 = PdfColor.fromInt(0xFFCBD2D9);
  static const PdfColor _grey100 = PdfColor.fromInt(0xFFF5F7FA);

  static const PdfColor _gold700 = PdfColor.fromInt(0xFFB38600);
  static const PdfColor _gold400 = PdfColor.fromInt(0xFFD4A800);
  static const PdfColor _gold50  = PdfColor.fromInt(0xFFFFF9E6);

  // Radii & spacing
  static const double _radius = 8;
  static const double _s8 = 8, _s12 = 12, _s16 = 16, _s20 = 20;

  // Label column width for info rows
  static const double _labelW = 110;

  // Fonts (using built-in fonts for better compatibility)
  pw.Font get _fontRegular => pw.Font.helvetica();
  pw.Font get _fontBold => pw.Font.helveticaBold();

  // ---- PUBLIC API -----------------------------------------------------------

  Future<Uint8List> buildQuotePdf({
    required Quote quote,
    required List<QuoteTransportDetail> transportDetails,
    required Map<String, dynamic> clientData,
    required Map<String, dynamic>? agentData,
    required Map<String, dynamic>? vehicleData,
    required Map<String, dynamic>? driverData,
  }) async {
    // Load logo (graceful fallback)
    pw.MemoryImage? logoImage;
    try {
      final response = await http.get(Uri.parse(_logoUrl));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        logoImage = pw.MemoryImage(response.bodyBytes);
      }
    } catch (_) {/* ignore */ }

    final currency = NumberFormat.currency(locale: 'en_ZA', symbol: 'R');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    // Pre-compute table data & totals (single source of truth)
    final validDetails = transportDetails
        .where((d) => (d.pickupLocation).trim().isNotEmpty && (d.dropoffLocation).trim().isNotEmpty)
        .toList();
    final totalFromLegs = validDetails.fold<double>(0.0, (sum, d) => sum + (d.amount));

    final doc = pw.Document();

    final pageTheme = pw.PageTheme(
      margin: const pw.EdgeInsets.all(25),
      theme: pw.ThemeData.withFont(base: _fontRegular, bold: _fontBold),
      buildBackground: (context) => _buildWatermark(), // "QUOTE" watermark
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (context) => context.pageNumber == 1
            ? _buildHeroHeader(logoImage) // page 1
            : _buildCompactHeader(logoImage, 'QN#${quote.id}'), // page 2+
        footer: (context) => _buildFooter('www.choiceluxcars.com | bookings@choiceluxcars.com'),
        build: (context) => [
          _sectionQuoteSummary(quote, dateFormat),
          pw.SizedBox(height: _s20),

          _sectionClientService(quote, clientData, agentData, vehicleData, driverData, dateFormat),
          pw.SizedBox(height: _s20),

          _sectionPassenger(quote),
          if (validDetails.isNotEmpty) pw.SizedBox(height: _s20),

          if (validDetails.isNotEmpty)
            _sectionTransportTable(validDetails, currency, dateFormat, timeFormat, totalFromLegs),
          if (_hasTripNotes(transportDetails)) pw.SizedBox(height: _s20),

          if (_hasTripNotes(transportDetails)) _sectionTripNotes(transportDetails),
          if ((quote.notes ?? '').trim().isNotEmpty) pw.SizedBox(height: _s20),

          if ((quote.notes ?? '').trim().isNotEmpty) _sectionGeneralNotes(quote),
          pw.SizedBox(height: _s20),

          _sectionTermsAndConditions(),
          pw.SizedBox(height: _s20),

          _sectionPaymentInfo(),
        ],
      ),
    );

    return doc.save();
  }

  // ---- WATERMARK ------------------------------------------------------------

  pw.Widget _buildWatermark() {
    return pw.Stack(
      children: [
        pw.Positioned.fill(
          child: pw.Center(
            child: pw.Transform.rotate(
              angle: -0.5, // ~-28.6 degrees
              child: pw.Opacity(
                opacity: 0.06,
                child: pw.Text(
                  'QUOTE',
                  style: pw.TextStyle(
                    font: _fontBold,
                    fontSize: 120,
                    color: _grey300,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- HEADERS / FOOTER -----------------------------------------------------

  pw.Widget _buildHeroHeader(pw.MemoryImage? logo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
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
                pw.Text(
                  'Choice Lux Cars',
                  style: pw.TextStyle(
                    font: _fontBold,
                    fontSize: 28,
                    color: _grey800,
                  ),
                ),
              pw.SizedBox(width: _s12),
              pw.Expanded(
                child: pw.Text(
                  'Choice Lux Cars',
                  style: pw.TextStyle(
                    font: _fontBold,
                    fontSize: 28,
                    color: _grey800,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Contact strip (two rows)
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: pw.BoxDecoration(
            color: _grey100,
            borderRadius: pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(_radius),
              bottomRight: pw.Radius.circular(_radius),
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _contactRow(['Email: bookings@choiceluxcars.com', 'Phone: +27 74 239 2222']),
              pw.SizedBox(height: 4),
              _contactRow(['Web: www.choiceluxcars.com', 'Address: 25 Johnson Road, Bedfordview, Johannesburg']),
            ],
          ),
        ),
        pw.SizedBox(height: _s16),
      ],
    );
  }

  pw.Widget _buildCompactHeader(pw.MemoryImage? logo, String quoteNumber) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Container(height: 26, width: 60, child: pw.Image(logo, fit: pw.BoxFit.contain))
          else
            pw.Text('CLC', style: pw.TextStyle(font: _fontBold, fontSize: 16, color: _grey800)),
          pw.SizedBox(width: _s8),
          pw.Text(
            'Quote $quoteNumber',
            style: pw.TextStyle(font: _fontBold, fontSize: 14, color: _grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(String text) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(height: 0.8, color: _grey300),
        pw.SizedBox(height: 6),
        pw.Text(
          text,
          style: pw.TextStyle(fontSize: 8, color: _grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  pw.Widget _contactRow(List<String> items) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: items
          .map((t) => pw.Padding(
                padding: const pw.EdgeInsets.only(right: 16),
                child: pw.Text(
                  t,
                  style: pw.TextStyle(fontSize: 9, color: _grey700),
                ),
              ))
          .toList(),
    );
  }

  // ---- SECTIONS -------------------------------------------------------------

  // Simple section header for long sections
  pw.Widget _sectionHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: pw.BoxDecoration(
            color: _grey100,
            border: pw.Border.all(color: _grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(_radius),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: 16,
              color: PdfColors.black,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _sectionQuoteSummary(Quote quote, DateFormat dateFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('QUOTE SUMMARY'),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if ((quote.quoteTitle ?? '').trim().isNotEmpty) ...[
                    pw.Text(
                      quote.quoteTitle!.trim(),
                      style: pw.TextStyle(font: _fontBold, fontSize: 14, color: _grey700),
                    ),
                    pw.SizedBox(height: 6),
                  ],
                  if ((quote.quoteDescription ?? '').trim().isNotEmpty)
                    pw.Text(
                      quote.quoteDescription!.trim(),
                      style: pw.TextStyle(fontSize: 11, color: _grey700, lineSpacing: 2),
                    ),
                ],
              ),
            ),
            pw.SizedBox(width: _s20),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _kv('Quote Number', 'QN#${quote.id}'),
                _kv('Date', dateFormat.format(quote.quoteDate)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _sectionClientService(
    Quote quote,
    Map<String, dynamic> client,
    Map<String, dynamic>? agent,
    Map<String, dynamic>? vehicle,
    Map<String, dynamic>? driver,
    DateFormat dateFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('CLIENT & SERVICE INFORMATION'),
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
                    _subTitle('Client Information'),
                    pw.SizedBox(height: 12),
                    _infoRow('Company', (client['company_name'] ?? 'Not specified').toString()),
                    if (agent != null) _infoRow('Contact Person', (agent['agent_name'] ?? 'Not specified').toString()),
                    _infoRow('Contact Number', (quote.passengerContact ?? 'Not specified')),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: _s16),
            // Service
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: _innerBox(),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _subTitle('Service Information'),
                    pw.SizedBox(height: 12),
                    _infoRow(
                      'Vehicle',
                      (vehicle?['make'] != null && vehicle?['model'] != null)
                          ? '${vehicle!['make']} ${vehicle['model']}'
                          : (quote.vehicleType ?? 'Not specified'),
                    ),
                    if (driver != null) _infoRow('Driver', (driver['display_name'] ?? 'Not specified').toString()),
                    _infoRow('Job Date', dateFormat.format(quote.jobDate)),
                    _infoRow('Location', (quote.location ?? 'Not specified')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _sectionPassenger(Quote quote) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('PASSENGER INFORMATION'),
        pw.Column(
          children: [
            _infoRow('Name', quote.passengerName ?? 'Not specified'),
            _infoRow('Passengers', quote.pasCount.toInt().toString()),
            _infoRow('Luggage', quote.luggage),
          ],
        ),
      ],
    );
  }

  pw.Widget _sectionTransportTable(
    List<QuoteTransportDetail> rows,
    NumberFormat currency,
    DateFormat dateFormat,
    DateFormat timeFormat,
    double totalFromLegs,
  ) {
    final table = pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey300, width: 0.5),
      headerStyle: pw.TextStyle(font: _fontBold, fontSize: 11, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: _grey700),
      cellStyle: pw.TextStyle(fontSize: 10, color: _grey800),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      headers: ['Date', 'Time', 'Pick-Up Location', 'Drop-Off Location', 'Amount'],
      data: rows.map((r) {
        return [
          dateFormat.format(r.pickupDate),
          timeFormat.format(r.pickupDate),
          r.pickupLocation,
          r.dropoffLocation,
          currency.format(r.amount),
        ];
      }).toList(),
      columnWidths: {
        0: const pw.FixedColumnWidth(85),
        1: const pw.FixedColumnWidth(50),
        2: const pw.FlexColumnWidth(),
        3: const pw.FlexColumnWidth(),
        4: const pw.FixedColumnWidth(90),
      },
    );

    final totalFooter = pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _grey100,
        borderRadius: pw.BorderRadius.only(
          bottomLeft: pw.Radius.circular(_radius - 1),
          bottomRight: pw.Radius.circular(_radius - 1),
        ),
        border: pw.Border.all(color: _grey300, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Total Quote Amount',
            style: pw.TextStyle(font: _fontBold, fontSize: 14, color: _grey800),
          ),
          pw.Text(
            currency.format(totalFromLegs),
            style: pw.TextStyle(font: _fontBold, fontSize: 16, color: _gold700),
          ),
        ],
      ),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('TRANSPORT DETAILS'),
        table,
        totalFooter,
      ],
    );
  }

  pw.Widget _sectionTripNotes(List<QuoteTransportDetail> details) {
    final items = <pw.Widget>[];
    for (var i = 0; i < details.length; i++) {
      final n = details[i].notes?.trim();
      if (n != null && n.isNotEmpty) {
        items.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 4, right: 8),
                  width: 4,
                  height: 4,
                  decoration: pw.BoxDecoration(color: _gold400, shape: pw.BoxShape.circle),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'Leg ${i + 1}: $n',
                    style: pw.TextStyle(fontSize: 11, color: _grey700, lineSpacing: 2),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('TRIP NOTES'),
        pw.Column(children: items),
      ],
    );
  }

  pw.Widget _sectionGeneralNotes(Quote quote) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('GENERAL NOTES'),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 4, right: 8),
              width: 4,
              height: 4,
              decoration: pw.BoxDecoration(color: _grey600, shape: pw.BoxShape.circle),
            ),
            pw.Expanded(
              child: pw.Text(
                quote.notes!.trim(),
                style: pw.TextStyle(fontSize: 11, color: _grey700, lineSpacing: 2),
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
            _numberedTerm(1, 'Quotes valid for 24 hours. Prices subject to availability.'),
            _numberedTerm(2, 'Confirmation subject to vehicle/driver availability. Payment required for final confirmation.'),
            _numberedTerm(3, 'Itinerary changes may affect pricing. Special requests subject to availability.'),
            _numberedTerm(4, 'Cancellation policy: 24 hours notice required for full refund.'),
            _numberedTerm(5, 'All prices include VAT and are quoted in South African Rands (ZAR).'),
          ],
        ),
      ],
    );
  }

  pw.Widget _sectionPaymentInfo() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('PAYMENT INFORMATION'),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _subTitle('Banking Details'),
            pw.SizedBox(height: _s12),
            _infoRow('Bank', 'First Rand Bank'),
            _infoRow('Account Name', 'Choice Lux Cars JHB'),
            _infoRow('Account Number', '62808002802'),
            _infoRow('Branch Code', '250655'),
            pw.SizedBox(height: _s16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _gold50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: _gold400, width: 0.5),
              ),
              child: pw.Text(
                'Note: Please use Quote Number as payment reference',
                style: pw.TextStyle(font: _fontBold, fontSize: 11, color: _gold700),
              ),
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
        border: pw.Border.all(color: _grey300, width: 0.5),
      );

  pw.Widget _subTitle(String text) => pw.Text(
        text,
        style: pw.TextStyle(font: _fontBold, fontSize: 14, color: _grey800),
      );

  pw.Widget _kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text('$k: ', style: pw.TextStyle(font: _fontBold, fontSize: 11, color: _grey600)),
            pw.Text(v, style: pw.TextStyle(fontSize: 11, color: _grey800)),
          ],
        ),
      );

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: _labelW,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(font: _fontBold, fontSize: 11, color: _grey600),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, color: _grey800),
              softWrap: true,
              overflow: pw.TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
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
              color: _grey700,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(
              child: pw.Text(
                '$n',
                style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(fontSize: 9, color: _grey700, lineSpacing: 1.2),
              softWrap: true,
              overflow: pw.TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasTripNotes(List<QuoteTransportDetail> details) {
    return details.any((t) => (t.notes ?? '').trim().isNotEmpty);
  }
}

