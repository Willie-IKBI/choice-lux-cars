import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/invoice_data.dart';

class InvoicePdfService {
  Future<Uint8List> buildInvoicePdf(InvoiceData data) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader(data),
          pw.SizedBox(height: 20),
          _buildInvoiceDetails(data),
          pw.SizedBox(height: 20),
          _buildClientDetails(data),
          pw.SizedBox(height: 20),
          _buildServiceDetails(data),
          pw.SizedBox(height: 20),
          _buildPaymentDetails(data),
          pw.SizedBox(height: 20),
          _buildBankingDetails(data),
          pw.SizedBox(height: 20),
          _buildFooter(data),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(InvoiceData data) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                data.companyName,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Invoice #${data.invoiceNumber}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Date: ${data.formattedInvoiceDate}'),
            pw.SizedBox(height: 4),
            pw.Text('Due: ${data.formattedDueDate}'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceDetails(InvoiceData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Invoice Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text('Job ID: ${data.jobId}'),
              ),
              pw.Expanded(
                child: pw.Text('Passengers: ${data.numberPassengers}'),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text('Luggage: ${data.luggage}'),
              ),
              pw.Expanded(
                child: pw.Text('Vehicle: ${data.vehicleType}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClientDetails(InvoiceData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Client Information',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Name: ${data.passengerName}'),
          pw.SizedBox(height: 5),
          pw.Text('Contact: ${data.passengerContact}'),
          pw.SizedBox(height: 10),
          pw.Text(
            'Service Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Driver: ${data.driverName}'),
          pw.SizedBox(height: 5),
          pw.Text('Driver Contact: ${data.driverContact}'),
        ],
      ),
    );
  }

  pw.Widget _buildServiceDetails(InvoiceData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Transport Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...data.transport.map((trip) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Date: ${trip.formattedDate} | Time: ${trip.time}'),
                pw.Text('Pickup: ${trip.pickupLocation}'),
                pw.Text('Dropoff: ${trip.dropoffLocation}'),
              ],
            ),
          )),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentDetails(InvoiceData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Payment Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Subtotal:'),
              pw.Text(data.formattedSubtotal),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Tax:'),
              pw.Text(data.formattedTaxAmount),
            ],
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Amount:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.Text(
                data.formattedTotalAmount,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text('Payment Terms: ${data.paymentTerms}'),
        ],
      ),
    );
  }

  pw.Widget _buildBankingDetails(InvoiceData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: pw.BorderRadius.circular(5),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Banking Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Bank: ${data.bankingDetails.bankName}'),
          pw.SizedBox(height: 5),
          pw.Text('Account Name: ${data.bankingDetails.accountName}'),
          pw.SizedBox(height: 5),
          pw.Text('Account Number: ${data.bankingDetails.accountNumber}'),
          pw.SizedBox(height: 5),
          pw.Text('Branch Code: ${data.bankingDetails.branchCode}'),
          pw.SizedBox(height: 5),
          pw.Text('Swift Code: ${data.bankingDetails.swiftCode}'),
          if (data.bankingDetails.reference != null) ...[
            pw.SizedBox(height: 5),
            pw.Text('Reference: ${data.bankingDetails.reference}'),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildFooter(InvoiceData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('For any queries, please contact:'),
          pw.Text('${data.agentName} - ${data.agentContact}'),
          pw.SizedBox(height: 10),
          pw.Text(
            'www.choiceluxcars.com',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}
