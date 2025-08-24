import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/voucher_data.dart';

class VoucherPdfService {
  // ---- THEME / TOKENS -------------------------------------------------------

  // Palette (grey + gold)
  static const PdfColor _grey800 = PdfColor.fromInt(0xFF323F4B);
  static const PdfColor _grey700 = PdfColor.fromInt(0xFF3E4C59);
  static const PdfColor _grey600 = PdfColor.fromInt(0xFF52606D);
  static const PdfColor _grey300 = PdfColor.fromInt(0xFFCBD2D9);
  static const PdfColor _grey100 = PdfColor.fromInt(0xFFF5F7FA);



  // Radii & spacing
  static const double _radius = 8;
  static const double _s8 = 8, _s12 = 12, _s16 = 16, _s20 = 20;

  // Label column width for info rows
  static const double _labelW = 110;

  // Fonts (using built-in fonts for better compatibility)
  pw.Font get _fontRegular => pw.Font.helvetica();
  pw.Font get _fontBold => pw.Font.helveticaBold();

  // ---- PUBLIC API -----------------------------------------------------------

  Future<Uint8List> buildVoucherPdf(VoucherData data) async {
    // Load client logo (graceful fallback)
    pw.MemoryImage? logoImage;
    if (data.hasLogo) {
      try {
        final response = await http.get(Uri.parse(data.companyLogo!));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {/* ignore */ }
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    final doc = pw.Document();

    final pageTheme = pw.PageTheme(
      margin: const pw.EdgeInsets.all(25),
      theme: pw.ThemeData.withFont(base: _fontRegular, bold: _fontBold),
      buildBackground: (context) => _buildWatermark(), // "VOUCHER" watermark
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (context) => context.pageNumber == 1
            ? _buildHeroHeader(data, logoImage) // page 1
            : _buildCompactHeader(data, logoImage, 'VN#${data.jobId}'), // page 2+
        footer: (context) => _buildFooter('www.choiceluxcars.com | bookings@choiceluxcars.com'),
        build: (context) => [
          _sectionVoucherSummary(data, dateFormat),
          pw.SizedBox(height: _s20),

          _sectionAgentPassenger(data),
          pw.SizedBox(height: _s20),

          _sectionDriverVehicle(data),
          pw.SizedBox(height: _s20),

          if (data.hasTransportDetails) _sectionTransportDetails(data, dateFormat, timeFormat),
          if (data.hasTransportDetails) pw.SizedBox(height: _s20),

          if (data.hasNotes) _sectionNotes(data),
          if (data.hasNotes) pw.SizedBox(height: _s20),

          _sectionTermsAndConditions(),
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
                  'VOUCHER',
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

  pw.Widget _buildHeroHeader(VoucherData data, pw.MemoryImage? logo) {
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
                  data.companyName,
                  style: pw.TextStyle(
                    font: _fontBold,
                    fontSize: 28,
                    color: _grey800,
                  ),
                ),
              pw.SizedBox(width: _s12),
              pw.Expanded(
                child: pw.Text(
                  data.companyName,
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
              _contactRow(['Agent: ${data.agentName}', 'Contact: ${data.agentContact}']),
              pw.SizedBox(height: 4),
              _contactRow(['Company: ${data.companyName}', '']),
            ],
          ),
        ),
        pw.SizedBox(height: _s16),
      ],
    );
  }

  pw.Widget _buildCompactHeader(VoucherData data, pw.MemoryImage? logo, String voucherNumber) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Container(height: 26, width: 60, child: pw.Image(logo, fit: pw.BoxFit.contain))
          else
            pw.Text(data.companyName.substring(0, 3).toUpperCase(), style: pw.TextStyle(font: _fontBold, fontSize: 16, color: _grey800)),
          pw.SizedBox(width: _s8),
          pw.Text(
            'Voucher $voucherNumber',
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

  // ---- SECTION CARDS --------------------------------------------------------

  pw.Widget _sectionCard({
    required String title,
    required pw.Widget child,
    pw.Widget? footer,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(_radius),
        color: _grey100,
      ),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                font: _fontBold,
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
                bottomLeft: pw.Radius.circular(_radius - 1),
                bottomRight: pw.Radius.circular(_radius - 1),
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

  pw.Widget _sectionVoucherSummary(VoucherData data, DateFormat dateFormat) {
    return _sectionCard(
      title: 'VOUCHER SUMMARY',
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Confirmation Voucher',
                  style: pw.TextStyle(font: _fontBold, fontSize: 14, color: _grey700),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'This voucher confirms your booking and related services.',
                  style: pw.TextStyle(fontSize: 11, color: _grey700, lineSpacing: 2),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: _s20),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _kv('Voucher Number', 'VN#${data.jobId}'),
              if (data.quoteNo != null) _kv('Quote Number', data.quoteNo!),
              _kv('Date', data.formattedQuoteDate),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionAgentPassenger(VoucherData data) {
    return _sectionCard(
      title: 'AGENT & PASSENGER INFORMATION',
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Agent
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: _innerBox(),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _subTitle('Agent Information'),
                  pw.SizedBox(height: 12),
                  _infoRow('Name', data.agentName),
                  _infoRow('Contact', data.agentContact),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: _s16),
          // Passenger
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: _innerBox(),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _subTitle('Passenger Information'),
                  pw.SizedBox(height: 12),
                  _infoRow('Name', data.passengerName),
                  _infoRow('Contact', data.passengerContact),
                  _infoRow('Passengers', data.numberPassengers.toString()),
                  _infoRow('Luggage', data.luggage),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionDriverVehicle(VoucherData data) {
    return _sectionCard(
      title: 'DRIVER & VEHICLE INFORMATION',
      child: pw.Column(
        children: [
          _infoRow('Driver Name', data.driverName),
          _infoRow('Driver Contact', data.driverContact),
          _infoRow('Vehicle Type', data.vehicleType),
        ],
      ),
    );
  }

  pw.Widget _sectionTransportDetails(VoucherData data, DateFormat dateFormat, DateFormat timeFormat) {
    final table = pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _grey300, width: 0.5),
      headerStyle: pw.TextStyle(font: _fontBold, fontSize: 11, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: _grey700),
      cellStyle: pw.TextStyle(fontSize: 10, color: _grey800),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      headers: ['Date', 'Time', 'Pick-Up Location', 'Drop-Off Location'],
      data: data.transport.map((item) {
        return [
          item.formattedPickupDate,
          item.formattedPickupTime,
          item.pickupLocation,
          item.dropoffLocation,
        ];
      }).toList(),
      columnWidths: {
        0: const pw.FixedColumnWidth(85),
        1: const pw.FixedColumnWidth(50),
        2: const pw.FlexColumnWidth(),
        3: const pw.FlexColumnWidth(),
      },
    );

    return _sectionCard(
      title: 'TRANSPORT DETAILS',
      child: table,
    );
  }

  pw.Widget _sectionNotes(VoucherData data) {
    return _sectionCard(
      title: 'NOTES',
      child: pw.Row(
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
              data.notes,
              style: pw.TextStyle(fontSize: 11, color: _grey700, lineSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTermsAndConditions() {
    return _sectionCard(
      title: 'TERMS & CONDITIONS',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _numberedTerm(1, 'This voucher confirms your booking and related services.'),
          _numberedTerm(2, 'Any changes must be made at least 24 hours in advance.'),
          _numberedTerm(3, 'Errors in details are the responsibility of the client.'),
          _numberedTerm(4, 'This document is subject to the operator\'s standard conditions.'),
        ],
      ),
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
}
