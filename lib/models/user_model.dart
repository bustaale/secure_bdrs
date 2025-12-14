class UserModel {
  final String id;
  final String username;
  final String email;
  final String role; // Admin, Registrar, Clerk
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final String? createdBy;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.isActive = true,
    this.lastLogin,
    required this.createdAt,
    this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'Clerk',
      isActive: map['isActive'] ?? true,
      lastLogin: map['lastLogin'] != null ? DateTime.parse(map['lastLogin']) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      createdBy: map['createdBy'],
    );
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

