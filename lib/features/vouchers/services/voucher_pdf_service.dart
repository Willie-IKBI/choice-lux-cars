import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:choice_lux_cars/features/vouchers/models/voucher_data.dart';
import 'package:choice_lux_cars/features/pdf/pdf.dart';

class VoucherPdfService {
  // ---- THEME / TOKENS -------------------------------------------------------
  // Using shared PdfTheme for consistent styling across all PDF services

  // ---- PUBLIC API -----------------------------------------------------------

  Future<Uint8List> buildVoucherPdf(VoucherData data) async {
    try {
      // Load client logo using shared utility
      final logoImage = await PdfUtilities.loadLogo(data.companyLogo);

      final dateFormat = DateFormat(PdfConfig.defaultDateFormat);
      final timeFormat = DateFormat(PdfConfig.defaultTimeFormat);

      final doc = pw.Document();

      final pageTheme = PdfTheme.buildPageTheme(
        watermarkBuilder: (context) => PdfTheme.buildVoucherWatermark(),
      );

      doc.addPage(
        pw.MultiPage(
          pageTheme: pageTheme,
          header: (context) => context.pageNumber == 1
              ? PdfTheme.buildClientBrandedHeader(
                  logo: logoImage,
                  companyName: data.companyName,
                  website: data.clientWebsite,
                  phone: data.clientContactPhone,
                  email: data.clientContactEmail,
                ) // page 1
              : PdfTheme.buildCompactHeader(
                  logo: logoImage,
                  documentNumber: 'VN#${data.jobId}',
                ), // page 2+
          footer: (context) => PdfTheme.buildClientFooter(
            clientWebsite: data.clientWebsite,
            clientEmail: data.clientContactEmail,
          ),
        build: (context) => [
          _sectionVoucherSummary(data, dateFormat),
          PdfTheme.buildProfessionalSpacing(height: PdfTheme.spacing8), // Reduced spacing

          _sectionAgentPassenger(data),
          PdfTheme.buildProfessionalSpacing(height: PdfTheme.spacing8), // Reduced spacing

          _sectionDriverVehicle(data),
          PdfTheme.buildProfessionalSpacing(height: PdfTheme.spacing8), // Reduced spacing

          if (data.hasTransportDetails)
            _sectionTransportDetails(data, dateFormat, timeFormat),
          if (data.hasTransportDetails) PdfTheme.buildProfessionalSpacing(height: PdfTheme.spacing8), // Reduced spacing

          if (data.hasNotes) _sectionNotes(data),
          if (data.hasNotes) PdfTheme.buildProfessionalSpacing(height: PdfTheme.spacing8), // Reduced spacing

          _sectionTermsAndConditions(),
        ],
      ),
      );

      return doc.save();
    } catch (e) {
      throw PdfUtilities.createPdfException('voucher', e);
    }
  }

  // ---- SECTIONS -------------------------------------------------------------

  // ---- SECTIONS -------------------------------------------------------------


  pw.Widget _sectionVoucherSummary(VoucherData data, DateFormat dateFormat) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfTheme.buildCleanSectionHeader('VOUCHER CONFIRMATION'),
        pw.Container(
          width: double.infinity,
          child: pw.Row(
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
                  PdfUtilities.buildKeyValue('Voucher Number', 'VN#${data.jobId}'),
                  if (data.quoteNo != null) PdfUtilities.buildKeyValue('Quote Number', data.quoteNo!),
                  PdfUtilities.buildKeyValue('Date', data.formattedQuoteDate),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionAgentPassenger(VoucherData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfTheme.buildCleanSectionHeader('AGENT & PASSENGER INFORMATION'),
        pw.Container(
          width: double.infinity,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Agent Card - Enhanced with more info for balance
              pw.Expanded(
                child: PdfTheme.buildBalancedCard(
                  title: 'Agent Information',
                  children: [
                    PdfTheme.buildCleanInfoRow('Name', data.agentName),
                    PdfTheme.buildCleanInfoRow('Contact', data.agentContact),
                    PdfTheme.buildCleanInfoRow('Company', data.companyName),
                  ],
                ),
              ),
              pw.SizedBox(width: PdfTheme.spacing8), // Reduced spacing
              // Passenger Card - Compact layout
              pw.Expanded(
                child: PdfTheme.buildBalancedCard(
                  title: 'Passenger Information',
                  children: [
                    PdfTheme.buildCleanInfoRow('Name', data.passengerName),
                    PdfTheme.buildCleanInfoRow('Contact', data.passengerContact),
                    pw.Container(
                      width: double.infinity,
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: PdfTheme.buildCleanInfoRow('Passengers', data.numberPassengers.toString()),
                          ),
                          pw.Expanded(
                            child: PdfTheme.buildCleanInfoRow('Luggage', data.luggage),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionDriverVehicle(VoucherData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfTheme.buildCleanSectionHeader('DRIVER & VEHICLE INFORMATION'),
        pw.Column(
          children: [
            PdfTheme.buildCleanInfoRow('Driver Name', data.driverName),
            PdfTheme.buildCleanInfoRow('Driver Contact', data.driverContact),
            PdfTheme.buildCleanInfoRow('Vehicle Type', data.vehicleType),
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
        0: const pw.FixedColumnWidth(85),  // Date column - good for "04 Sep 2025"
        1: const pw.FixedColumnWidth(65),  // Time column - increased from 50 to fit "Time" header
        2: const pw.FlexColumnWidth(1.2),  // Pick-Up Location - slightly reduced flex weight
        3: const pw.FlexColumnWidth(1.2),  // Drop-Off Location - slightly reduced flex weight
      },
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [PdfTheme.buildCleanSectionHeader('TRANSPORT SCHEDULE'), table],
    );
  }

  pw.Widget _sectionNotes(VoucherData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfTheme.buildCleanSectionHeader('NOTES'),
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
        PdfTheme.buildCleanSectionHeader('TERMS & CONDITIONS'),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfUtilities.buildNumberedTerm(
              1,
              'This voucher confirms your booking and related services.',
            ),
            PdfUtilities.buildNumberedTerm(
              2,
              'Any changes must be made at least 24 hours in advance.',
            ),
            PdfUtilities.buildNumberedTerm(
              3,
              'Errors in details are the responsibility of the client.',
            ),
            PdfUtilities.buildNumberedTerm(
              4,
              'This document is subject to the operator\'s standard conditions.',
            ),
          ],
        ),
      ],
    );
  }

  // ---- SMALL HELPERS --------------------------------------------------------

  // Using shared PdfUtilities methods instead of custom implementations
}
