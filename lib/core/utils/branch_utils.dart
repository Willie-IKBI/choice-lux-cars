/// Utility functions for converting between branch IDs and branch codes
/// 
/// The database stores branch_id as bigint (1, 2, 3) referencing branches.id
/// The UI uses branch codes as strings ("Jhb", "Cpt", "Dbn")
class BranchUtils {
  /// Map of branch codes to branch IDs
  static const Map<String, int> _codeToIdMap = {
    'Jhb': 3, // Johannesburg
    'Cpt': 2, // Cape Town
    'Dbn': 1, // Durban
  };

  /// Map of branch IDs to branch codes
  static const Map<int, String> _idToCodeMap = {
    1: 'Dbn', // Durban
    2: 'Cpt', // Cape Town
    3: 'Jhb', // Johannesburg
  };

  /// Convert branch code (String) to branch ID (int)
  /// Returns null if code is invalid
  static int? codeToId(String? code) {
    if (code == null || code.isEmpty) return null;
    return _codeToIdMap[code];
  }

  /// Convert branch ID (int or bigint) to branch code (String)
  /// Returns null if ID is invalid
  static String? idToCode(dynamic id) {
    if (id == null) return null;
    
    // Handle both int and String representations
    int? branchId;
    if (id is int) {
      branchId = id;
    } else if (id is String) {
      branchId = int.tryParse(id);
    } else if (id is num) {
      branchId = id.toInt();
    }
    
    if (branchId == null) return null;
    return _idToCodeMap[branchId];
  }

  /// Check if a branch code is valid
  static bool isValidCode(String? code) {
    if (code == null || code.isEmpty) return false;
    return _codeToIdMap.containsKey(code);
  }

  /// Check if a branch ID is valid
  static bool isValidId(dynamic id) {
    if (id == null) return false;
    
    int? branchId;
    if (id is int) {
      branchId = id;
    } else if (id is String) {
      branchId = int.tryParse(id);
    } else if (id is num) {
      branchId = id.toInt();
    }
    
    if (branchId == null) return false;
    return _idToCodeMap.containsKey(branchId);
  }

  /// Get branch ID from a user's branchId string (code like 'Jhb')
  /// Useful for passing to repository methods that need numeric branch_id
  static int? getBranchIdFromCode(String? branchCode) {
    return codeToId(branchCode);
  }

  /// Get all branch options as a list of maps for dropdowns
  /// Returns list of {id: int, code: String, name: String}
  static List<Map<String, dynamic>> getAllBranches() {
    return [
      {'id': 3, 'code': 'Jhb', 'name': 'Johannesburg'},
      {'id': 2, 'code': 'Cpt', 'name': 'Cape Town'},
      {'id': 1, 'code': 'Dbn', 'name': 'Durban'},
    ];
  }

  /// Get branch full name from code
  static String? getFullName(String? code) {
    if (code == null) return null;
    switch (code) {
      case 'Jhb':
        return 'Johannesburg';
      case 'Cpt':
        return 'Cape Town';
      case 'Dbn':
        return 'Durban';
      default:
        return code;
    }
  }

  /// Get branch full name from ID
  static String? getFullNameFromId(int? id) {
    if (id == null) return null;
    final code = idToCode(id);
    return getFullName(code);
  }
}

