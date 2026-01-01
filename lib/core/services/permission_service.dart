class PermissionService {
  const PermissionService();

  // -----------------------------
  // Status checks
  // -----------------------------

  bool isDeactivated(String? status) {
    return status != null && status.toLowerCase() == 'deactivated';
  }

  bool isUnassigned(String? role) {
    return role == null || role.toLowerCase() == 'unassigned';
  }

  bool isSuspended(String? role) {
    return role != null && role.toLowerCase() == 'suspended';
  }

  // -----------------------------
  // Role helpers
  // -----------------------------

  bool isAdmin(String? role) {
    return role == 'administrator' || role == 'super_admin';
  }

  bool isSuperAdmin(String? role) {
    return role == 'super_admin';
  }

  bool isManager(String? role) {
    return role == 'manager';
  }

  bool isDriverManager(String? role) {
    return role == 'driver_manager';
  }

  bool isDriver(String? role) {
    return role == 'driver';
  }

  // -----------------------------
  // Route access rules
  // -----------------------------

  bool canAccessUsers(String? role) {
    return isAdmin(role) || isManager(role);
  }

  bool canAccessVehicles(String? role) {
    return isAdmin(role);
  }

  bool canAccessClients(String? role) {
    return isAdmin(role);
  }

  bool canAccessInsights(String? role) {
    return isAdmin(role) || isManager(role);
  }

  bool canAccessNotificationSettings(String? role) {
    return isSuperAdmin(role);
  }

  // -----------------------------
  // Branch scoping
  // -----------------------------

  bool requiresBranch(String? role) {
    return isManager(role) || isDriverManager(role) || isDriver(role);
  }

  bool isNational(String? role) {
    return isAdmin(role);
  }
}

