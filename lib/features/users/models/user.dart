// User model for driver management flow
class User {
  final String id;
  final String displayName;
  final String? role;
  final String? driverLicence;
  final DateTime? driverLicExp;
  final String? pdp;
  final DateTime? pdpExp;
  final String? profileImage;
  final String? address;
  final String? number;
  final String? kin;
  final String? kinNumber;
  final String userEmail;
  final String? status;

  User({
    required this.id,
    required this.displayName,
    required this.userEmail,
    this.role,
    this.driverLicence,
    this.driverLicExp,
    this.pdp,
    this.pdpExp,
    this.profileImage,
    this.address,
    this.number,
    this.kin,
    this.kinNumber,
    this.status,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      displayName: map['display_name'] as String? ?? '',
      userEmail: map['user_email'] as String? ?? '',
      role: map['role'] as String?,
      driverLicence: map['driver_licence'] as String?,
      driverLicExp: map['driver_lic_exp'] != null ? DateTime.tryParse(map['driver_lic_exp']) : null,
      pdp: map['pdp'] as String?,
      pdpExp: map['pdp_exp'] != null ? DateTime.tryParse(map['pdp_exp']) : null,
      profileImage: map['profile_image'] as String?,
      address: map['address'] as String?,
      number: map['number'] as String?,
      kin: map['kin'] as String?,
      kinNumber: map['kin_number'] as String?,
      status: map['status'] as String?,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'user_email': userEmail,
      'role': role,
      'driver_licence': driverLicence,
      'driver_lic_exp': driverLicExp?.toIso8601String(),
      'pdp': pdp,
      'pdp_exp': pdpExp?.toIso8601String(),
      'profile_image': profileImage,
      'address': address,
      'number': number,
      'kin': kin,
      'kin_number': kinNumber,
      'status': status,
    };
  }

  Map<String, dynamic> toJson() => toMap();
} 