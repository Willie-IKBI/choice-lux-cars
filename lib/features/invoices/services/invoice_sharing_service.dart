import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../models/invoice_data.dart';

class InvoiceSharingService {
  Future<void> openInvoiceUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open invoice URL');
      }
    } catch (e) {
      throw Exception('Failed to open invoice: $e');
    }
  }

  Future<void> shareInvoiceViaWhatsApp({
    required String invoiceUrl,
    required InvoiceData invoiceData,
  }) async {
    try {
      final message = _buildWhatsAppMessage(invoiceUrl, invoiceData);
      final encodedMessage = Uri.encodeComponent(message);
      
      String whatsappUrl;
      if (Platform.isAndroid || Platform.isIOS) {
        whatsappUrl = 'https://wa.me/?text=$encodedMessage';
      } else {
        whatsappUrl = 'https://web.whatsapp.com/send?text=$encodedMessage';
      }

      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback to general share
        await Share.share(message, subject: 'Invoice for Job #${invoiceData.jobId}');
      }
    } catch (e) {
      throw Exception('Failed to share via WhatsApp: $e');
    }
  }

  Future<void> shareInvoiceViaEmail({
    required String invoiceUrl,
    required InvoiceData invoiceData,
  }) async {
    try {
      final subject = 'Invoice for Job #${invoiceData.jobId}';
      final body = _buildEmailBody(invoiceUrl, invoiceData);
      
      final emailUrl = 'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
      final uri = Uri.parse(emailUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback to general share
        await Share.share(body, subject: subject);
      }
    } catch (e) {
      throw Exception('Failed to share via email: $e');
    }
  }

  Future<void> copyInvoiceLink({
    required String invoiceUrl,
    required InvoiceData invoiceData,
  }) async {
    try {
      final message = _buildCopyMessage(invoiceUrl, invoiceData);
      await Clipboard.setData(ClipboardData(text: message));
    } catch (e) {
      throw Exception('Failed to copy invoice link: $e');
    }
  }

  String _buildWhatsAppMessage(String url, InvoiceData data) {
    return '''Invoice for Job #${data.jobId}

${data.companyName} has generated an invoice for your booking.

Invoice Number: ${data.invoiceNumber}
Amount: ${data.formattedTotalAmount}
Due Date: ${data.formattedDueDate}

View your invoice: $url

Thank you for choosing ${data.companyName}!''';
  }

  String _buildEmailBody(String url, InvoiceData data) {
    return '''Dear ${data.passengerName},

${data.companyName} has generated an invoice for your booking.

Invoice Details:
- Invoice Number: ${data.invoiceNumber}
- Invoice Date: ${data.formattedInvoiceDate}
- Due Date: ${data.formattedDueDate}
- Amount: ${data.formattedTotalAmount}

You can view and download your invoice at: $url

Payment Details:
${data.bankingDetails.bankName}
Account Name: ${data.bankingDetails.accountName}
Account Number: ${data.bankingDetails.accountNumber}
Branch Code: ${data.bankingDetails.branchCode}
Swift Code: ${data.bankingDetails.swiftCode}
${data.bankingDetails.reference != null ? 'Reference: ${data.bankingDetails.reference}' : ''}

Payment Terms: ${data.paymentTerms}

If you have any questions, please contact us.

Best regards,
${data.agentName}
${data.companyName}''';
  }

  String _buildCopyMessage(String url, InvoiceData data) {
    return '''Invoice for Job #${data.jobId}

Invoice Number: ${data.invoiceNumber}
Amount: ${data.formattedTotalAmount}
Due Date: ${data.formattedDueDate}

View invoice: $url''';
  }
}
