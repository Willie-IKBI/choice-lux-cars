import 'package:choice_lux_cars/features/invoices/models/invoice_data.dart';

class InvoiceConfigService {
  // Tax configuration
  static const double defaultTaxRate = 0.15; // 15% VAT
  static const String defaultCurrency = 'ZAR';

  // Payment terms
  static const int defaultPaymentDays = 30;
  static const String defaultPaymentTerms = 'Payment due within 30 days';

  // Banking details
  static const BankingDetails defaultBankingDetails = BankingDetails(
    bankName: 'Standard Bank',
    accountName: 'Choice Lux Cars (Pty) Ltd',
    accountNumber: '1234567890',
    branchCode: '051001',
    swiftCode: 'SBZAZAJJ',
  );

  // Company details
  static const String defaultCompanyName = 'Choice Lux Cars';
  static const String defaultCompanyWebsite = 'www.choiceluxcars.com';

  // Invoice numbering
  static const String invoiceNumberPrefix = 'INV-';

  // Storage configuration
  static const String storageBucket = 'pdfdocuments';
  static const String storageFolder = 'invoices';

  /// Calculate tax amount based on total
  static double calculateTaxAmount(double totalAmount) {
    return totalAmount * defaultTaxRate;
  }

  /// Calculate subtotal (amount before tax)
  static double calculateSubtotal(double totalAmount) {
    return totalAmount * (1 - defaultTaxRate);
  }

  /// Generate invoice number
  static String generateInvoiceNumber(String jobId) {
    return '$invoiceNumberPrefix$jobId';
  }

  /// Get due date based on invoice date
  static DateTime calculateDueDate(DateTime invoiceDate) {
    return invoiceDate.add(Duration(days: defaultPaymentDays));
  }

  /// Get storage path for invoice
  static String getStoragePath(String jobId, int timestamp) {
    final fileName = 'invoice_${jobId}_$timestamp.pdf';
    return '$storageFolder/$fileName';
  }
}
