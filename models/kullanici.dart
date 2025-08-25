class Kullanici {
  final int id;
  final String username;
  final bool isActive;
  final String? role; // ← NULL olabilir

  Kullanici({
    required this.id,
    required this.username,
    required this.isActive,
    this.role, // ← required değil artık
  });

  factory Kullanici.fromJson(Map<String, dynamic> json) {
    return Kullanici(
      id: json['id'],
      username: json['username'],
      isActive: json['is_active'],
      role: json['role']?.toString(), // ← null olabilir, string'e çevrildi
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'is_active': isActive,
      'role': role,
    };
  }
}
