import 'package:choice_lux_cars/features/invoices/models/invoice_data.dart';
import 'package:choice_lux_cars/core/constants.dart';

class InvoiceConfigService {
  // Tax configuration
  static const double defaultTaxRate = 0.0; // 0% VAT (no tax)
  static const String defaultCurrency = CurrencyConstants.defaultCurrency;

  // Payment terms
  static const int defaultPaymentDays = 30;
  static const String defaultPaymentTerms = ''; // No payment terms

  // Banking details
  static const BankingDetails defaultBankingDetails = BankingDetails(
    bankName: CurrencyConstants.bankName,
    accountName: CurrencyConstants.accountName,
    accountNumber: CurrencyConstants.accountNumber,
    branchCode: CurrencyConstants.branchCode,
    swiftCode: CurrencyConstants.swiftCode,
  );

  // Company details
  static const String defaultCompanyName = DefaultValues.defaultCompanyName;
  static const String defaultCompanyWebsite = DefaultValues.defaultCompanyWebsite;

  // Invoice numbering
  static const String invoiceNumberPrefix = 'INV-';

  // Storage configuration
  static const String storageBucket = StorageConstants.pdfDocumentsBucket;
  static const String storageFolder = StorageConstants.invoicesFolder;

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
    return invoiceDate.add(const Duration(days: defaultPaymentDays));
  }

  /// Get storage path for invoice
  static String getStoragePath(String jobId, int timestamp) {
    final fileName = 'invoice_${jobId}_$timestamp.pdf';
    return '$storageFolder/$fileName';
  }
}
