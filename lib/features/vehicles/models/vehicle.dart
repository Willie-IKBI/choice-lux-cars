// Vehicle model for Supabase integration
class Vehicle {
  final int? id;
  final String make;
  final String model;
  final String regPlate;
  final DateTime regDate;
  final String fuelType;
  final String? vehicleImage;
  final String status;
  final DateTime licenseExpiryDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Vehicle({
    this.id,
    required this.make,
    required this.model,
    required this.regPlate,
    required this.regDate,
    required this.fuelType,
    this.vehicleImage,
    required this.status,
    required this.licenseExpiryDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'] as int?,
    make: json['make'] as String? ?? '',
    model: json['model'] as String? ?? '',
    regPlate: json['reg_plate'] as String? ?? '',
    regDate: json['reg_date'] != null
        ? DateTime.parse(json['reg_date'])
        : DateTime(2000, 1, 1),
    fuelType: json['fuel_type'] as String? ?? '',
    vehicleImage: json['vehicle_image'] as String?,
    status: json['status'] as String? ?? 'Active',
    licenseExpiryDate: json['license_expiry_date'] != null
        ? DateTime.parse(json['license_expiry_date'])
        : DateTime(2000, 1, 1),
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'make': make,
    'model': model,
    'reg_plate': regPlate,
    'reg_date': regDate.toIso8601String(),
    'fuel_type': fuelType,
    'vehicle_image': vehicleImage,
    'status': status,
    'license_expiry_date': licenseExpiryDate.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
