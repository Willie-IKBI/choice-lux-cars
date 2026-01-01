class InvoiceData {
  final int jobId;
  final String? quoteNo;
  final DateTime? quoteDate;
  final String companyName;
  final String? companyLogo;
  final String? clientContactPerson;
  final String? clientContactNumber;
  final String? clientContactEmail;
  final String? clientBillingAddress;
  final String? clientCompanyRegistration;
  final String? clientVatNumber;
  final String? clientWebsite;
  final String agentName;
  final String agentContact;
  final String? agentEmail;
  final String passengerName;
  final String passengerContact;
  final int numberPassengers;
  final String luggage;
  final String driverName;
  final String driverContact;
  final String vehicleType;
  final List<TransportDetail> transport;
  final String notes;

  // Invoice specific fields
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String currency;
  final String paymentTerms;
  final BankingDetails bankingDetails;

  InvoiceData({
    required this.jobId,
    this.quoteNo,
    this.quoteDate,
    required this.companyName,
    this.companyLogo,
    this.clientContactPerson,
    this.clientContactNumber,
    this.clientContactEmail,
    this.clientBillingAddress,
    this.clientCompanyRegistration,
    this.clientVatNumber,
    this.clientWebsite,
    required this.agentName,
    required this.agentContact,
    this.agentEmail,
    required this.passengerName,
    required this.passengerContact,
    required this.numberPassengers,
    required this.luggage,
    required this.driverName,
    required this.driverContact,
    required this.vehicleType,
    required this.transport,
    required this.notes,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.currency,
    required this.paymentTerms,
    required this.bankingDetails,
  });

  factory InvoiceData.fromJson(Map<String, dynamic> json) {
    return InvoiceData(
      jobId: (json['job_id'] as num?)?.toInt() ?? 0,
      quoteNo: json['quote_no'] as String?,
      quoteDate: json['quote_date'] != null
          ? DateTime.parse(json['quote_date'] as String)
          : null,
      companyName: json['company_name'] as String? ?? 'Choice Lux Cars',
      companyLogo: json['company_logo'] as String?,
      clientContactPerson: json['client_contact_person'] as String?,
      clientContactNumber: json['client_contact_number'] as String?,
      clientContactEmail: json['client_contact_email'] as String?,
      clientBillingAddress: json['client_billing_address'] as String?,
      clientCompanyRegistration: json['client_company_registration'] as String?,
      clientVatNumber: json['client_vat_number'] as String?,
      clientWebsite: json['client_website'] as String?,
      agentName: json['agent_name'] as String? ?? 'Not available',
      agentContact: json['agent_contact'] as String? ?? 'Not available',
      agentEmail: json['agent_email'] as String?,
      passengerName: json['passenger_name'] as String? ?? 'Not specified',
      passengerContact: json['passenger_contact'] as String? ?? 'Not specified',
      numberPassengers: (json['number_passengers'] as num?)?.toInt() ?? 0,
      luggage: json['luggage'] as String? ?? 'Not specified',
      driverName: json['driver_name'] as String? ?? 'Not assigned',
      driverContact: json['driver_contact'] as String? ?? 'Not available',
      vehicleType: json['vehicle_type'] as String? ?? 'Not assigned',
      transport:
          (json['transport'] as List<dynamic>?)
              ?.map((e) => TransportDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? 'INV-0',
      invoiceDate: json['invoice_date'] != null
          ? DateTime.parse(json['invoice_date'] as String)
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : DateTime.now().add(const Duration(days: 30)),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'ZAR',
      paymentTerms:
          json['payment_terms'] as String? ?? 'Payment due within 30 days',
      bankingDetails: json['banking_details'] != null
          ? BankingDetails.fromJson(
              json['banking_details'] as Map<String, dynamic>,
            )
          : const BankingDetails(
              bankName: 'Standard Bank',
              accountName: 'Choice Lux Cars (Pty) Ltd',
              accountNumber: '1234567890',
              branchCode: '051001',
              swiftCode: 'SBZAZAJJ',
              reference: 'INV-0',
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'quote_no': quoteNo,
      'quote_date': quoteDate?.toIso8601String(),
      'company_name': companyName,
      'company_logo': companyLogo,
      'client_contact_person': clientContactPerson,
      'client_contact_number': clientContactNumber,
      'client_contact_email': clientContactEmail,
      'client_billing_address': clientBillingAddress,
      'client_company_registration': clientCompanyRegistration,
      'client_vat_number': clientVatNumber,
      'client_website': clientWebsite,
      'agent_name': agentName,
      'agent_contact': agentContact,
      'agent_email': agentEmail,
      'passenger_name': passengerName,
      'passenger_contact': passengerContact,
      'number_passengers': numberPassengers,
      'luggage': luggage,
      'driver_name': driverName,
      'driver_contact': driverContact,
      'vehicle_type': vehicleType,
      'transport': transport.map((e) => e.toJson()).toList(),
      'notes': notes,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'currency': currency,
      'payment_terms': paymentTerms,
      'banking_details': bankingDetails.toJson(),
    };
  }

  String get formattedInvoiceDate {
    return '${invoiceDate.day.toString().padLeft(2, '0')}/${invoiceDate.month.toString().padLeft(2, '0')}/${invoiceDate.year}';
  }

  String get formattedDueDate {
    return '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}';
  }

  String get formattedSubtotal {
    return '$currency ${subtotal.toStringAsFixed(2)}';
  }

  String get formattedTaxAmount {
    return '$currency ${taxAmount.toStringAsFixed(2)}';
  }

  String get formattedTotalAmount {
    return '$currency ${totalAmount.toStringAsFixed(2)}';
  }
}

class TransportDetail {
  final DateTime date;
  final String time;
  final String pickupLocation;
  final String dropoffLocation;

  TransportDetail({
    required this.date,
    required this.time,
    required this.pickupLocation,
    required this.dropoffLocation,
  });

  factory TransportDetail.fromJson(Map<String, dynamic> json) {
    return TransportDetail(
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      time: json['time'] as String? ?? '00:00',
      pickupLocation: json['pickup_location'] as String? ?? 'Not specified',
      dropoffLocation: json['dropoff_location'] as String? ?? 'Not specified',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'time': time,
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
    };
  }

  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class BankingDetails {
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String branchCode;
  final String swiftCode;
  final String? reference;

  const BankingDetails({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.branchCode,
    required this.swiftCode,
    this.reference,
  });

  factory BankingDetails.fromJson(Map<String, dynamic> json) {
    return BankingDetails(
      bankName: json['bank_name'] as String? ?? 'Standard Bank',
      accountName:
          json['account_name'] as String? ?? 'Choice Lux Cars (Pty) Ltd',
      accountNumber: json['account_number'] as String? ?? '1234567890',
      branchCode: json['branch_code'] as String? ?? '051001',
      swiftCode: json['swift_code'] as String? ?? 'SBZAZAJJ',
      reference: json['reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bank_name': bankName,
      'account_name': accountName,
      'account_number': accountNumber,
      'branch_code': branchCode,
      'swift_code': swiftCode,
      'reference': reference,
    };
  }
}
