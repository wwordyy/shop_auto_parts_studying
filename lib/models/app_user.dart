import '../utils/json_utils.dart';

enum Role {
  buyer,
  manager,
  admin;

  int get level => switch (this) {
        Role.buyer => 1,
        Role.manager => 2,
        Role.admin => 3,
      };

  String get label => switch (this) {
        Role.buyer => 'Покупатель',
        Role.manager => 'Менеджер',
        Role.admin => 'Администратор',
      };

  static Role parse(String? value) {
    return switch (value) {
      'admin' => Role.admin,
      'manager' => Role.manager,
      _ => Role.buyer,
    };
  }

  String get apiName => name;
}

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final Role role;
  final int? customerId;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.customerId,
  });

  String get displayName => fullName.trim().isEmpty ? username : fullName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'fullName': fullName,
        'email': email,
        'role': role.apiName,
        'customerId': customerId,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final rawCustomer = json['customerId'];
    return AppUser(
      id: jsonInt(json, 'id'),
      username: jsonString(json, 'username'),
      fullName: jsonString(json, 'fullName'),
      email: jsonString(json, 'email'),
      role: Role.parse(json['role']?.toString()),
      customerId: rawCustomer == null ? null : jsonInt(json, 'customerId'),
    );
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AppUser user;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return AuthTokens(
      accessToken: jsonString(json, 'accessToken'),
      refreshToken: jsonString(json, 'refreshToken'),
      expiresIn: jsonInt(json, 'expiresIn', 900),
      user: rawUser is Map
          ? AppUser.fromJson(Map<String, dynamic>.from(rawUser))
          : AppUser.fromJson(const {}),
    );
  }
}
