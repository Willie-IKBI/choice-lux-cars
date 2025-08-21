import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/quote.dart';
import '../models/quote_transport_detail.dart';

class QuotePdfService {
  static const String _logoUrl = 'https://hgqrbekphumdlsifuamq.supabase.co/storage/v1/object/public/clc_images/app_images/logo%20-%20512.png';
  
  /// Generate modern quote PDF with enhanced styling
  Future<Uint8List> buildQuotePdf({
    required Quote quote,
    required List<QuoteTransportDetail> transportDetails,
    required Map<String, dynamic> clientData,
    required Map<String, dynamic>? agentData,
    required Map<String, dynamic>? vehicleData,
    required Map<String, dynamic>? driverData,
  }) async {
    try {
      // Load company logo
      pw.MemoryImage? logoImage;
      try {
        final response = await http.get(Uri.parse(_logoUrl));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print('Logo load error: $e');
      }

      final pdf = pw.Document();
      final currency = NumberFormat.currency(locale: 'en_ZA', symbol: 'R');
      final dateFormat = DateFormat('dd/MM/yyyy');
      final timeFormat = DateFormat('HH:mm');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(25),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 15),
            child: pw.Text(
              'Choice Lux Cars - www.choicelux.co.za',
              style: pw.TextStyle(
                fontSize: 9, 
                color: PdfColors.grey600,
                fontWeight: pw.FontWeight.normal,
              ),
            ),
          ),
          build: (context) => [
            // Modern Header with Gradient Effect
            _buildModernHeader(quote, logoImage, dateFormat),
            pw.SizedBox(height: 20),
            
            // Quote Metadata Card
            _buildMetadataCard(quote, dateFormat),
            pw.SizedBox(height: 20),
            
            // Information Cards Grid
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Column
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      _buildInfoCard(
                        title: 'Client Details',
                        icon: 'C',
                        content: [
                          _buildInfoRow('Company', clientData['company_name'] ?? 'Not specified'),
                          if (agentData != null) _buildInfoRow('Agent', agentData['agent_name'] ?? 'Not specified'),
                        ],
                        color: PdfColors.grey50,
                        borderColor: PdfColors.grey300,
                      ),
                      pw.SizedBox(height: 16),
                      _buildInfoCard(
                        title: 'Passenger Details',
                        icon: 'P',
                        content: [
                          _buildInfoRow('Name', quote.passengerName ?? 'Not specified'),
                          _buildInfoRow('Contact', quote.passengerContact ?? 'Not specified'),
                          _buildInfoRow('Passengers', quote.pasCount.toInt().toString()),
                          _buildInfoRow('Luggage', quote.luggage),
                        ],
                        color: PdfColors.grey50,
                        borderColor: PdfColors.grey300,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                
                // Right Column
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      _buildInfoCard(
                        title: 'Service Details',
                        icon: 'S',
                        content: [
                          _buildInfoRow('Vehicle', vehicleData?['make'] != null && vehicleData?['model'] != null 
                              ? '${vehicleData!['make']} ${vehicleData!['model']}'
                              : quote.vehicleType ?? 'Not specified'),
                          if (driverData != null) _buildInfoRow('Driver', driverData['display_name'] ?? 'Not specified'),
                          _buildInfoRow('Job Date', dateFormat.format(quote.jobDate)),
                          _buildInfoRow('Location', quote.location ?? 'Not specified'),
                        ],
                        color: PdfColors.grey50,
                        borderColor: PdfColors.grey300,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Quote Details Card
            _buildQuoteDetailsCard(quote),
            pw.SizedBox(height: 20),
            
            // Transport Details Card
            _buildTransportDetailsCard(transportDetails, currency, dateFormat, timeFormat),
            
            // Notes Section (if available)
            if (quote.notes?.isNotEmpty == true) ...[
              pw.SizedBox(height: 20),
              _buildNotesCard(quote),
            ],
            
            pw.SizedBox(height: 25),
            
            // Modern Terms & Conditions
            _buildModernTermsAndConditions(),
          ],
        ),
      );

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to generate modern quote PDF: $e');
    }
  }

  // Modern Header with gradient effect
  pw.Widget _buildModernHeader(Quote quote, pw.MemoryImage? logoImage, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.grey100, PdfColors.grey50],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Choice Lux Cars',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                    border: pw.Border.all(color: PdfColors.blue200, width: 1),
                  ),
                  child: pw.Text(
                    'Professional Quote',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Reg: 2024/420673/07',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          if (logoImage != null)
            pw.Container(
              height: 80,
              width: 220,
              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
            ),
        ],
      ),
    );
  }

  // Modern Metadata Card
  pw.Widget _buildMetadataCard(Quote quote, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Quote Date',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  dateFormat.format(quote.quoteDate),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.normal,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),

          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Quote Number',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'QN#${quote.id}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.normal,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),

          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Status',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: pw.BoxDecoration(
                                         color: _getStatusColor(quote.quoteStatus),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Text(
                    quote.statusDisplayName,
                                         style: pw.TextStyle(
                       fontSize: 10,
                       fontWeight: pw.FontWeight.normal,
                       color: _getStatusColor(quote.quoteStatus),
                     ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modern Info Card
  pw.Widget _buildInfoCard({
    required String title,
    required String icon,
    required List<pw.Widget> content,
    required PdfColor color,
    required PdfColor borderColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: borderColor, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: borderColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    icon,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          ...content,
        ],
      ),
    );
  }

  // Info Row Helper
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.normal,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Quote Details Card
  pw.Widget _buildQuoteDetailsCard(Quote quote) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey600,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Q',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Quote Details',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey200, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (quote.quoteTitle?.isNotEmpty == true) ...[
                  pw.Text(
                    quote.quoteTitle!,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                ],
                if (quote.quoteDescription?.isNotEmpty == true) ...[
                  pw.Text(
                    quote.quoteDescription!,
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Transport Details Card
  pw.Widget _buildTransportDetailsCard(
    List<QuoteTransportDetail> transportDetails,
    NumberFormat currency,
    DateFormat dateFormat,
    DateFormat timeFormat,
  ) {
    final totalAmount = transportDetails.fold(0.0, (sum, transport) => sum + transport.amount);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey600,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'T',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Transport Details',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          if (transportDetails.isNotEmpty)
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.purple100, width: 1),
              ),
              child: pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.grey600,
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(6),
                    topRight: pw.Radius.circular(6),
                  ),
                ),
                cellStyle: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                headers: ['Date', 'Time', 'Pick-Up Location', 'Drop-Off Location', 'Amount'],
                data: transportDetails.map((item) {
                  return [
                    dateFormat.format(item.pickupDate),
                    timeFormat.format(item.pickupDate),
                    item.pickupLocation,
                    item.dropoffLocation,
                    currency.format(item.amount),
                  ];
                }).toList(),
                columnWidths: {
                  0: const pw.FixedColumnWidth(70),
                  1: const pw.FixedColumnWidth(45),
                  2: const pw.FlexColumnWidth(),
                  3: const pw.FlexColumnWidth(),
                  4: const pw.FixedColumnWidth(60),
                },
              ),
            )
          else
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.grey200, width: 1),
              ),
              child: pw.Text(
                'No transport details available.',
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          
          if (transportDetails.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.blue200, width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Quote Amount:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    currency.format(totalAmount),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Notes Card
  pw.Widget _buildNotesCard(Quote quote) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey600,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'N',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Additional Notes',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey200, width: 1),
            ),
            child: pw.Text(
              quote.notes!,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modern Terms & Conditions
  pw.Widget _buildModernTermsAndConditions() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey600,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'T',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Terms & Conditions',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.grey200, width: 1),
            ),
            child: pw.Column(
              children: [
                _buildTermItem('All quotes are valid for 24 Hours. Prices are subject to change based on availability.'),
                _buildTermItem('Quotation is subject to vehicle and driver availability at the time of booking confirmation. Final confirmation is only provided upon receipt of payment.'),
                _buildTermItem('Any itinerary amendments may affect the quoted price. Special requests are subject to availability and may incur additional costs.'),
                _buildTermItem('This document is subject to the operator\'s standard conditions.'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.blue200, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Banking Details:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Account Name: Choice Lux Cars JHB',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
                pw.Text(
                  'Bank: First Rand - Acc#: 62808002802 - Branch: 250655',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Term Item Helper
  pw.Widget _buildTermItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4, right: 8),
            width: 4,
            height: 4,
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue600,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get status color
  PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return PdfColors.grey;
      case 'open':
        return PdfColors.blue;
      case 'sent':
        return PdfColors.orange;
      case 'accepted':
        return PdfColors.green;
      case 'rejected':
        return PdfColors.red;
      case 'expired':
        return PdfColors.red;
      case 'closed':
        return PdfColors.grey700;
      default:
        return PdfColors.grey;
    }
  }
}
