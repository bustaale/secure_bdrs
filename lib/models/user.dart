class User {
  final String id;
  final String name;
  final String email;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role = "clerk",
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"]?.toString() ?? "0",
        name: json["name"] ?? "Unknown",
        email: json["email"] ?? "",
        role: json["role"] ?? "clerk",
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "email": email,
        "role": role,
      };
}
