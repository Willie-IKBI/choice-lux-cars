class RoleUtils {
  static bool isAdmin(String? role) {
    final r = role?.toLowerCase();
    return r == 'administrator' || r == 'super_admin';
  }

  static bool isSuperAdmin(String? role) {
    return role?.toLowerCase() == 'super_admin';
  }

  static bool isDriver(String? role) {
    return role?.toLowerCase() == 'driver';
  }

  static bool isDriverManager(String? role) {
    return role?.toLowerCase() == 'driver_manager';
  }

  static bool isManager(String? role) {
    return role?.toLowerCase() == 'manager';
  }

  static bool canEditJob(String? role) {
    final r = role?.toLowerCase();
    return r == 'administrator' || r == 'super_admin' || r == 'manager';
  }

  static bool canViewAmounts(String? role) {
    return isAdmin(role);
  }

  static bool canAdminClose(String? role) {
    return isAdmin(role);
  }

  static bool canAssignDriver(String? role) {
    return isAdmin(role) || isManager(role);
  }

  static bool canManageUsers(String? role) {
    return isAdmin(role);
  }
}
