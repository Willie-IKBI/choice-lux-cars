import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:choice_lux_cars/features/vouchers/models/voucher_data.dart';
import 'package:choice_lux_cars/features/pdf/pdf_theme.dart';

class VoucherPdfService {
  // ---- THEME / TOKENS -------------------------------------------------------
  // Using shared PdfTheme for consistent styling across all PDF services

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
      } catch (_) {
        /* ignore */
      }
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    final doc = pw.Document();

    final pageTheme = PdfTheme.buildPageTheme(
      watermarkBuilder: (context) => PdfTheme.buildVoucherWatermark(),
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (context) => context.pageNumber == 1
            ? PdfTheme.buildHeroHeader(
                logo: logoImage,
                companyName: data.companyName,
              ) // page 1
            : PdfTheme.buildCompactHeader(
                logo: logoImage,
                documentNumber: 'VN#${data.jobId}',
              ), // page 2+
        footer: (context) => PdfTheme.buildFooter(
          'www.choiceluxcars.com | bookings@choiceluxcars.com',
        ),
        build: (context) => [
          _sectionVoucherSummary(data, dateFormat),
          pw.SizedBox(height: PdfTheme.spacing20),

          _sectionAgentPassenger(data),
          pw.SizedBox(height: PdfTheme.spacing20),

          _sectionDriverVehicle(data),
          pw.SizedBox(height: PdfTheme.spacing20),

          if (data.hasTransportDetails)
            _sectionTransportDetails(data, dateFormat, timeFormat),
          if (data.hasTransportDetails) pw.SizedBox(height: PdfTheme.spacing20),

          if (data.hasNotes) _sectionNotes(data),
          if (data.hasNotes) pw.SizedBox(height: PdfTheme.spacing20),

          _sectionTermsAndConditions(),
        ],
      ),
    );

    return doc.save();
  }

  // ---- SECTIONS -------------------------------------------------------------

  // ---- SECTIONS -------------------------------------------------------------

  // Simple section header for long sections
  pw.Widget _sectionHeader(String title) {
    return PdfTheme.buildSectionHeader(title);
  }

  pw.Widget _sectionVoucherSummary(VoucherData data, DateFormat dateFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('VOUCHER SUMMARY'),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Confirmation Voucher', style: PdfTheme.titleSmall),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'This voucher confirms your booking and related services.',
                    style: PdfTheme.bodyText.copyWith(lineSpacing: 2),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: PdfTheme.spacing20),
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
      ],
    );
  }

  pw.Widget _sectionAgentPassenger(VoucherData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('AGENT & PASSENGER INFORMATION'),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Agent
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(PdfTheme.spacing12),
                decoration: _innerBox(),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _subTitle('Agent Information'),
                    pw.SizedBox(height: PdfTheme.spacing12),
                    _infoRow('Name', data.agentName),
                    _infoRow('Contact', data.agentContact),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: PdfTheme.spacing16),
            // Passenger
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(PdfTheme.spacing12),
                decoration: _innerBox(),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _subTitle('Passenger Information'),
                    pw.SizedBox(height: PdfTheme.spacing12),
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
      ],
    );
  }

  pw.Widget _sectionDriverVehicle(VoucherData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('DRIVER & VEHICLE INFORMATION'),
        pw.Column(
          children: [
            _infoRow('Driver Name', data.driverName),
            _infoRow('Driver Contact', data.driverContact),
            _infoRow('Vehicle Type', data.vehicleType),
          ],
        ),
      ],
    );
  }

  pw.Widget _sectionTransportDetails(
    VoucherData data,
    DateFormat dateFormat,
    DateFormat timeFormat,
  ) {
    final table = pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfTheme.grey300, width: 0.5),
      headerStyle: PdfTheme.labelText.copyWith(color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
      cellStyle: PdfTheme.bodyText.copyWith(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: pw.EdgeInsets.symmetric(
        horizontal: PdfTheme.spacing12,
        vertical: PdfTheme.spacing8,
      ),
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

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [_sectionHeader('TRANSPORT DETAILS'), table],
    );
  }

  pw.Widget _sectionNotes(VoucherData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader('NOTES'),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 4, right: 8),
              width: 4,
              height: 4,
              decoration: pw.BoxDecoration(
                color: PdfTheme.grey600,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                data.notes,
                style: PdfTheme.bodyText.copyWith(lineSpacing: 2),
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
            _numberedTerm(
              1,
              'This voucher confirms your booking and related services.',
            ),
            _numberedTerm(
              2,
              'Any changes must be made at least 24 hours in advance.',
            ),
            _numberedTerm(
              3,
              'Errors in details are the responsibility of the client.',
            ),
            _numberedTerm(
              4,
              'This document is subject to the operator\'s standard conditions.',
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

  pw.Widget _subTitle(String text) => pw.Text(text, style: PdfTheme.titleSmall);

  pw.Widget _kv(String k, String v) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$k: ',
          style: PdfTheme.labelText.copyWith(color: PdfTheme.grey600),
        ),
        pw.Text(v, style: PdfTheme.bodyText.copyWith(color: PdfTheme.grey800)),
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
                style: PdfTheme.captionText.copyWith(
                  font: PdfTheme.fontBold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: PdfTheme.captionText.copyWith(lineSpacing: 1.2),
              softWrap: true,
              overflow: pw.TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}
