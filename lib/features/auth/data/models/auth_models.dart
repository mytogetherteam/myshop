class LoginRequest {
  final String emailOrUsername;
  final String password;

  LoginRequest({required this.emailOrUsername, required this.password});

  Map<String, dynamic> toJson() => {
    'emailOrUsername': emailOrUsername,
    'password': password,
  };
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String fullName;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'password': password,
    'fullName': fullName,
  };
}

class AuthResponse {
  final bool success;
  final String? message;
  final String? details;
  final String? token;
  final String? refreshToken;
  final UserInfo? userInfo;

  AuthResponse({
    required this.success,
    this.message,
    this.details,
    this.token,
    this.refreshToken,
    this.userInfo,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      details: json['details'],
      token: data != null ? data['token'] : null,
      refreshToken: data != null ? data['refreshToken'] : null,
      userInfo: data != null ? UserInfo.fromJson(data) : null,
    );
  }
}

class UserInfo {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String role;

  UserInfo({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'fullName': fullName,
    'role': role,
  };
}
