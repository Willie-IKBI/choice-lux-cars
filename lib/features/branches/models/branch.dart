// Branch model for Choice Lux Cars company branches
class Branch {
  final int id;
  final String name;
  final String code;

  Branch({
    required this.id,
    required this.name,
    required this.code,
  });

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? '') ?? 0,
      name: map['name'] as String? ?? '',
      code: map['code'] as String? ?? '',
    );
  }

  factory Branch.fromJson(Map<String, dynamic> json) => Branch.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Branch copyWith({
    int? id,
    String? name,
    String? code,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Branch &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          code == other.code;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ code.hashCode;

  @override
  String toString() => 'Branch(id: $id, name: $name, code: $code)';

  // Static constants for known branches
  static const int durbanId = 1;
  static const int capeTownId = 2;
  static const int johannesburgId = 3;

  static const String durbanCode = 'Dbn';
  static const String capeTownCode = 'Cpt';
  static const String johannesburgCode = 'Jhb';

  static const String durbanName = 'Durban';
  static const String capeTownName = 'Cape Town';
  static const String johannesburgName = 'Johannesburg';
}

