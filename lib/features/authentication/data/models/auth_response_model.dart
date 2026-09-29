import 'dart:convert';

/// Model representing the backend authentication response from POST /auth/login
class AuthLoginResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String? userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? brandId;
  final String? branchId;
  final String? role;
  final String? userType;
  final String? appType;
  final List<String> permissions;

  AuthLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn = 900,
    this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.brandId,
    this.branchId,
    this.role,
    this.userType,
    this.appType,
    this.permissions = const [],
  });

  factory AuthLoginResponse.fromJson(Map<String, dynamic> json) {
    // Handle nested 'data' or top-level fields
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final token = data['accessToken']?.toString() ??
        data['token']?.toString() ??
        json['accessToken']?.toString() ??
        json['token']?.toString() ??
        '';

    final jwtClaims = _decodeJwtPayload(token);

    final userMap = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : (json['user'] is Map<String, dynamic>
            ? json['user'] as Map<String, dynamic>
            : null);

    final rawPermissions = data['permissions'] ??
        userMap?['permissions'] ??
        jwtClaims['permissions'];

    List<String> permissionsList = [];
    if (rawPermissions is List) {
      permissionsList = rawPermissions.map((e) => e.toString()).toList();
    }

    final userId = data['userId']?.toString() ??
        data['id']?.toString() ??
        userMap?['id']?.toString() ??
        userMap?['userId']?.toString() ??
        jwtClaims['userId']?.toString() ??
        jwtClaims['id']?.toString();

    final username = data['username']?.toString() ??
        userMap?['username']?.toString() ??
        jwtClaims['username']?.toString() ??
        '';

    final firstName = data['firstName']?.toString() ??
        data['first']?.toString() ??
        userMap?['firstName']?.toString() ??
        userMap?['first']?.toString() ??
        jwtClaims['firstName']?.toString();

    final lastName = data['lastName']?.toString() ??
        data['last']?.toString() ??
        userMap?['lastName']?.toString() ??
        userMap?['last']?.toString() ??
        jwtClaims['lastName']?.toString();

    final brandId = data['brandId']?.toString() ??
        userMap?['brandId']?.toString() ??
        jwtClaims['brandId']?.toString();

    final branchId = data['branchId']?.toString() ??
        userMap?['branchId']?.toString() ??
        jwtClaims['branchId']?.toString();

    final role = data['role']?.toString() ??
        userMap?['role']?.toString() ??
        jwtClaims['role']?.toString();

    final userType = data['userType']?.toString() ??
        userMap?['userType']?.toString() ??
        jwtClaims['userType']?.toString();

    final appType = data['appType']?.toString() ??
        userMap?['appType']?.toString() ??
        jwtClaims['appType']?.toString();

    return AuthLoginResponse(
      accessToken: token,
      refreshToken: data['refreshToken']?.toString() ??
          json['refreshToken']?.toString() ??
          '',
      expiresIn: data['expiresIn'] is int ? data['expiresIn'] as int : 900,
      userId: userId,
      username: username,
      firstName: firstName,
      lastName: lastName,
      brandId: brandId,
      branchId: branchId,
      role: role,
      userType: userType,
      appType: appType,
      permissions: permissionsList,
    );
  }

  static Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final bytes = base64Decode(payload);
      final jsonStr = utf8.decode(bytes);
      final map = jsonDecode(jsonStr);
      if (map is Map<String, dynamic>) {
        return map;
      }
    } catch (_) {}
    return {};
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      if (userId != null) 'userId': userId,
      'username': username,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (brandId != null) 'brandId': brandId,
      if (branchId != null) 'branchId': branchId,
      if (role != null) 'role': role,
      if (userType != null) 'userType': userType,
      if (appType != null) 'appType': appType,
      'permissions': permissions,
    };
  }
}
