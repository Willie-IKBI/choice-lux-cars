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
  final int? branchId; // Branch allocation: NULL = Admin/National (can see all branches), non-null = specific branch assignment

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
      this.branchId,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      displayName: map['display_name'] as String? ?? '',
      userEmail: map['user_email'] as String? ?? '',
      role: map['role'] as String?,
      driverLicence: map['driver_licence'] as String?,
      driverLicExp: map['driver_lic_exp'] != null
          ? DateTime.tryParse(map['driver_lic_exp'])
          : null,
      pdp: map['pdp'] as String?,
      pdpExp: map['pdp_exp'] != null ? DateTime.tryParse(map['pdp_exp']) : null,
      profileImage: map['profile_image'] as String?,
      address: map['address'] as String?,
      number: map['number'] as String?,
      kin: map['kin'] as String?,
      kinNumber: map['kin_number'] as String?,
      status: map['status'] as String?,
      branchId: map['branch_id'] != null
          ? int.tryParse(map['branch_id'].toString())
          : null,
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
      'branch_id': branchId, // Always include, even if null
    };
  }

  Map<String, dynamic> toJson() => toMap();

  User copyWith({
    String? id,
    String? displayName,
    String? role,
    String? driverLicence,
    DateTime? driverLicExp,
    String? pdp,
    DateTime? pdpExp,
    String? profileImage,
    String? address,
    String? number,
    String? kin,
    String? kinNumber,
    String? userEmail,
    String? status,
    int? branchId,
  }) {
    return User(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      driverLicence: driverLicence ?? this.driverLicence,
      driverLicExp: driverLicExp ?? this.driverLicExp,
      pdp: pdp ?? this.pdp,
      pdpExp: pdpExp ?? this.pdpExp,
      profileImage: profileImage ?? this.profileImage,
      address: address ?? this.address,
      number: number ?? this.number,
      kin: kin ?? this.kin,
      kinNumber: kinNumber ?? this.kinNumber,
      userEmail: userEmail ?? this.userEmail,
      status: status ?? this.status,
      branchId: branchId ?? this.branchId,
    );
  }

  /// Check if user is an administrator (includes both administrator and super_admin)
  bool get isAdmin {
    final roleLower = role?.toLowerCase();
    return roleLower == 'administrator' || roleLower == 'super_admin';
  }

  /// Check if user is a super administrator
  bool get isSuperAdmin {
    return role?.toLowerCase() == 'super_admin';
  }

  /// Check if user is a manager
  bool get isManager {
    return role?.toLowerCase() == 'manager';
  }

  /// Check if user is a driver manager
  bool get isDriverManager {
    return role?.toLowerCase() == 'driver_manager';
  }

  /// Check if user is a driver
  bool get isDriver {
    return role?.toLowerCase() == 'driver';
  }

  /// Check if user has national access (admin or super_admin with no branch assignment)
  bool get hasNationalAccess {
    return isAdmin && branchId == null;
  }
}
