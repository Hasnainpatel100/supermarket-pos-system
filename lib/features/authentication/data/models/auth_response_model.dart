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
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    final rawPermissions = data['permissions'];
    List<String> permissionsList = [];
    if (rawPermissions is List) {
      permissionsList = rawPermissions.map((e) => e.toString()).toList();
    }

    return AuthLoginResponse(
      accessToken: data['accessToken']?.toString() ?? '',
      refreshToken: data['refreshToken']?.toString() ?? '',
      expiresIn: data['expiresIn'] is int ? data['expiresIn'] as int : 900,
      userId: data['userId']?.toString() ?? data['id']?.toString(),
      username: data['username']?.toString() ?? '',
      firstName: data['firstName']?.toString() ?? data['first']?.toString(),
      lastName: data['lastName']?.toString() ?? data['last']?.toString(),
      brandId: data['brandId']?.toString(),
      branchId: data['branchId']?.toString(),
      role: data['role']?.toString(),
      userType: data['userType']?.toString(),
      appType: data['appType']?.toString(),
      permissions: permissionsList,
    );
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
