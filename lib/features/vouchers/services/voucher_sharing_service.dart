import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:choice_lux_cars/features/vouchers/models/voucher_data.dart';

class VoucherSharingService {
  /// Open voucher URL in external browser
  Future<void> openVoucherUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open voucher URL');
      }
    } catch (e) {
      throw Exception('Failed to open voucher: $e');
    }
  }

  /// Share voucher via WhatsApp
  Future<void> shareVoucherViaWhatsApp({
    required String voucherUrl,
    required VoucherData voucherData,
    String? customPhoneNumber,
  }) async {
    try {
      final phoneNumber = customPhoneNumber ?? voucherData.preferredPhoneNumber;
      if (phoneNumber.isEmpty) {
        throw Exception('No phone number available for sharing');
      }

      // Clean phone number (remove spaces, dashes, etc.)
      final cleanPhone = _cleanPhoneNumber(phoneNumber);

      // Create share message
      final message = _createShareMessage(voucherData, voucherUrl);

      // Create WhatsApp URL
      final whatsappUrl = _createWhatsAppUrl(cleanPhone, message);

      // Launch WhatsApp
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback to system share sheet
        await _shareViaSystemShareSheet(message, voucherUrl);
      }
    } catch (e) {
      throw Exception('Failed to share voucher via WhatsApp: $e');
    }
  }

  /// Share voucher via system share sheet
  Future<void> shareViaSystemShareSheet({
    required String voucherUrl,
    required VoucherData voucherData,
  }) async {
    try {
      final message = _createShareMessage(voucherData, voucherUrl);
      await _shareViaSystemShareSheet(message, voucherUrl);
    } catch (e) {
      throw Exception('Failed to share voucher: $e');
    }
  }

  /// Share via email
  Future<void> shareViaEmail({
    required String voucherUrl,
    required VoucherData voucherData,
    String? recipientEmail,
  }) async {
    try {
      final email = recipientEmail ?? voucherData.agentContact;
      if (email.isEmpty || !email.contains('@')) {
        throw Exception('Invalid email address');
      }

      final subject = 'Voucher for ${voucherData.passengerName}';
      final body = _createEmailBody(voucherData, voucherUrl);

      final emailUrl =
          'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';

      final uri = Uri.parse(emailUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not open email client');
      }
    } catch (e) {
      throw Exception('Failed to share voucher via email: $e');
    }
  }

  /// Clean phone number for WhatsApp
  String _cleanPhoneNumber(String phone) {
    // Remove all non-digit characters except +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // If it starts with 0, replace with country code (assuming South Africa)
    if (cleaned.startsWith('0')) {
      cleaned = '+27${cleaned.substring(1)}';
    }

    // If it doesn't start with +, add +27 (South Africa)
    if (!cleaned.startsWith('+')) {
      cleaned = '+27$cleaned';
    }

    return cleaned;
  }

  /// Create share message for WhatsApp
  String _createShareMessage(VoucherData voucherData, String voucherUrl) {
    final passengerName = voucherData.passengerName;
    final companyName = voucherData.companyName;
    final voucherNo = voucherData.quoteNo ?? 'N/A';

    return '''Hi! Here's your booking voucher from $companyName.

Passenger: $passengerName
Voucher No: $voucherNo

You can view and download your voucher here: $voucherUrl

Thank you for choosing $companyName!''';
  }

  /// Create email body
  String _createEmailBody(VoucherData voucherData, String voucherUrl) {
    final passengerName = voucherData.passengerName;
    final companyName = voucherData.companyName;
    final voucherNo = voucherData.quoteNo ?? 'N/A';
    final quoteDate = voucherData.formattedQuoteDate;

    return '''Dear $passengerName,

Thank you for your booking with $companyName.

Voucher Details:
- Voucher No: $voucherNo
- Date: $quoteDate
- Company: $companyName

You can view and download your voucher here: $voucherUrl

If you have any questions, please don't hesitate to contact us.

Best regards,
$companyName Team''';
  }

  /// Create WhatsApp URL
  String _createWhatsAppUrl(String phoneNumber, String message) {
    final encodedMessage = Uri.encodeComponent(message);
    return 'https://wa.me/$phoneNumber?text=$encodedMessage';
  }

  /// Share via system share sheet
  Future<void> _shareViaSystemShareSheet(String message, String url) async {
    await Share.share(
      '$message\n\n$url',
      subject: 'Voucher from Choice Lux Cars',
    );
  }

  /// Check if WhatsApp is available
  Future<bool> isWhatsAppAvailable() async {
    try {
      // Try to open WhatsApp with a test URL
      const testUrl = 'https://wa.me/1234567890?text=test';
      final uri = Uri.parse(testUrl);
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  /// Get available sharing options
  List<String> getAvailableSharingOptions() {
    final options = ['System Share Sheet'];

    // Note: We can't reliably detect WhatsApp availability without trying to launch it
    // So we'll include it as an option and handle the fallback in the sharing method
    options.add('WhatsApp');

    return options;
  }
}
