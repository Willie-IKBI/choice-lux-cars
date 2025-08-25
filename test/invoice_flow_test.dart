import 'package:flutter_test/flutter_test.dart';
import 'package:choice_lux_cars/features/invoices/models/invoice_data.dart';
import 'package:choice_lux_cars/features/invoices/services/invoice_config_service.dart';
import 'package:choice_lux_cars/features/invoices/services/invoice_pdf_service.dart';

void main() {
  group('Invoice Flow Tests', () {
    group('InvoiceConfigService', () {
      test('should calculate tax amount correctly', () {
        const totalAmount = 1000.0;
        final taxAmount = InvoiceConfigService.calculateTaxAmount(totalAmount);
        expect(taxAmount, 150.0); // 15% of 1000
      });

      test('should calculate subtotal correctly', () {
        const totalAmount = 1000.0;
        final subtotal = InvoiceConfigService.calculateSubtotal(totalAmount);
        expect(subtotal, 850.0); // 85% of 1000
      });

      test('should generate invoice number correctly', () {
        const jobId = '123';
        final invoiceNumber = InvoiceConfigService.generateInvoiceNumber(jobId);
        expect(invoiceNumber, 'INV-123');
      });

      test('should calculate due date correctly', () {
        final invoiceDate = DateTime(2025, 1, 1);
        final dueDate = InvoiceConfigService.calculateDueDate(invoiceDate);
        expect(dueDate, DateTime(2025, 1, 31)); // 30 days later
      });

      test('should generate storage path correctly', () {
        const jobId = '123';
        const timestamp = 1234567890;
        final storagePath = InvoiceConfigService.getStoragePath(jobId, timestamp);
        expect(storagePath, 'invoices/invoice_123_1234567890.pdf');
      });
    });

    group('InvoiceData Model', () {
      test('should create InvoiceData from JSON correctly', () {
        final json = {
          'job_id': 123,
          'quote_no': 'Q-123',
          'quote_date': '2025-01-01T00:00:00.000Z',
          'company_name': 'Test Company',
          'agent_name': 'Test Agent',
          'agent_contact': '+27123456789',
          'passenger_name': 'John Doe',
          'passenger_contact': '+27123456788',
          'number_passengers': 2,
          'luggage': '2 bags',
          'driver_name': 'Driver Name',
          'driver_contact': '+27123456787',
          'vehicle_type': 'Mercedes S-Class',
          'transport': [
            {
              'date': '2025-01-01T00:00:00.000Z',
              'time': '10:00',
              'pickup_location': 'Airport',
              'dropoff_location': 'Hotel'
            }
          ],
          'notes': 'Test notes',
          'invoice_number': 'INV-123',
          'invoice_date': '2025-01-01T00:00:00.000Z',
          'due_date': '2025-01-31T00:00:00.000Z',
          'subtotal': 850.0,
          'tax_amount': 150.0,
          'total_amount': 1000.0,
          'currency': 'ZAR',
          'payment_terms': 'Payment due within 30 days',
          'banking_details': {
            'bank_name': 'Test Bank',
            'account_name': 'Test Account',
            'account_number': '1234567890',
            'branch_code': '123456',
            'swift_code': 'TESTZAJJ',
            'reference': 'INV-123'
          }
        };

        final invoiceData = InvoiceData.fromJson(json);

        expect(invoiceData.jobId, 123);
        expect(invoiceData.quoteNo, 'Q-123');
        expect(invoiceData.companyName, 'Test Company');
        expect(invoiceData.passengerName, 'John Doe');
        expect(invoiceData.invoiceNumber, 'INV-123');
        expect(invoiceData.totalAmount, 1000.0);
        expect(invoiceData.currency, 'ZAR');
        expect(invoiceData.transport.length, 1);
        expect(invoiceData.bankingDetails.bankName, 'Test Bank');
      });

      test('should handle missing optional fields gracefully', () {
        final json = {
          'job_id': 123,
          'company_name': 'Test Company',
          'agent_name': 'Test Agent',
          'agent_contact': '+27123456789',
          'passenger_name': 'John Doe',
          'passenger_contact': '+27123456788',
          'number_passengers': 2,
          'luggage': '2 bags',
          'driver_name': 'Driver Name',
          'driver_contact': '+27123456787',
          'vehicle_type': 'Mercedes S-Class',
          'transport': [],
          'notes': '',
          'invoice_number': 'INV-123',
          'invoice_date': '2025-01-01T00:00:00.000Z',
          'due_date': '2025-01-31T00:00:00.000Z',
          'subtotal': 850.0,
          'tax_amount': 150.0,
          'total_amount': 1000.0,
          'currency': 'ZAR',
          'payment_terms': 'Payment due within 30 days',
          'banking_details': {
            'bank_name': 'Test Bank',
            'account_name': 'Test Account',
            'account_number': '1234567890',
            'branch_code': '123456',
            'swift_code': 'TESTZAJJ'
          }
        };

        final invoiceData = InvoiceData.fromJson(json);

        expect(invoiceData.quoteNo, isNull);
        expect(invoiceData.quoteDate, isNull);
        expect(invoiceData.companyLogo, isNull);
        expect(invoiceData.bankingDetails.reference, isNull);
      });

      test('should format dates correctly', () {
        final invoiceData = InvoiceData(
          jobId: 123,
          companyName: 'Test Company',
          agentName: 'Test Agent',
          agentContact: '+27123456789',
          passengerName: 'John Doe',
          passengerContact: '+27123456788',
          numberPassengers: 2,
          luggage: '2 bags',
          driverName: 'Driver Name',
          driverContact: '+27123456787',
          vehicleType: 'Mercedes S-Class',
          transport: [],
          notes: '',
          invoiceNumber: 'INV-123',
          invoiceDate: DateTime(2025, 1, 1),
          dueDate: DateTime(2025, 1, 31),
          subtotal: 850.0,
          taxAmount: 150.0,
          totalAmount: 1000.0,
          currency: 'ZAR',
          paymentTerms: 'Payment due within 30 days',
          bankingDetails: InvoiceConfigService.defaultBankingDetails,
        );

        expect(invoiceData.formattedInvoiceDate, '01/01/2025');
        expect(invoiceData.formattedDueDate, '31/01/2025');
        expect(invoiceData.formattedTotalAmount, 'ZAR 1000.00');
        expect(invoiceData.formattedSubtotal, 'ZAR 850.00');
        expect(invoiceData.formattedTaxAmount, 'ZAR 150.00');
      });
    });

    group('InvoicePdfService', () {
      test('should generate PDF without throwing errors', () async {
        final invoiceData = InvoiceData(
          jobId: 123,
          companyName: 'Test Company',
          agentName: 'Test Agent',
          agentContact: '+27123456789',
          passengerName: 'John Doe',
          passengerContact: '+27123456788',
          numberPassengers: 2,
          luggage: '2 bags',
          driverName: 'Driver Name',
          driverContact: '+27123456787',
          vehicleType: 'Mercedes S-Class',
          transport: [
            TransportDetail(
              date: DateTime(2025, 1, 1),
              time: '10:00',
              pickupLocation: 'Airport',
              dropoffLocation: 'Hotel',
            ),
          ],
          notes: 'Test notes',
          invoiceNumber: 'INV-123',
          invoiceDate: DateTime(2025, 1, 1),
          dueDate: DateTime(2025, 1, 31),
          subtotal: 850.0,
          taxAmount: 150.0,
          totalAmount: 1000.0,
          currency: 'ZAR',
          paymentTerms: 'Payment due within 30 days',
          bankingDetails: InvoiceConfigService.defaultBankingDetails,
        );

        final pdfService = InvoicePdfService();
        final pdfBytes = await pdfService.buildInvoicePdf(invoiceData);

        expect(pdfBytes, isNotEmpty);
        expect(pdfBytes.length, greaterThan(0));
      });
    });
  });
}
