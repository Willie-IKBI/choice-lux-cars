import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';

class QuoteTransportDetail {
  final String id;
  final String quoteId;
  final DateTime pickupDate;
  final String pickupLocation;
  final String dropoffLocation;
  final double amount;
  final String? notes;

  QuoteTransportDetail({
    required this.id,
    required this.quoteId,
    required this.pickupDate,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.amount,
    this.notes,
  });

  factory QuoteTransportDetail.fromMap(Map<String, dynamic> map) {
    return QuoteTransportDetail(
      id: map['id']?.toString() ?? '',
      quoteId: map['quote_id']?.toString() ?? '',
      pickupDate: DateTime.parse(
        map['pickup_date']?.toString() ?? SATimeUtils.getCurrentSATimeISO(),
      ),
      pickupLocation: map['pickup_location']?.toString() ?? '',
      dropoffLocation: map['dropoff_location']?.toString() ?? '',
      amount: (map['amount'] is num)
          ? (map['amount'] as num).toDouble()
          : double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0,
      notes: map['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': int.tryParse(id) ?? id,
      'quote_id': int.tryParse(quoteId) ?? quoteId,
      'pickup_date': pickupDate.toIso8601String(),
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'amount': amount,
      'notes': notes,
    };
  }

  QuoteTransportDetail copyWith({
    String? id,
    String? quoteId,
    DateTime? pickupDate,
    String? pickupLocation,
    String? dropoffLocation,
    double? amount,
    String? notes,
  }) {
    return QuoteTransportDetail(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
    );
  }

  String get formattedPickupTime {
    return '${pickupDate.hour.toString().padLeft(2, '0')}:${pickupDate.minute.toString().padLeft(2, '0')}';
  }

  String get formattedPickupDate {
    return '${pickupDate.day.toString().padLeft(2, '0')} ${_getMonthName(pickupDate.month)} ${pickupDate.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
