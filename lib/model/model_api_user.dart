import 'dart:convert';

/// Represents an API User data model for REST API endpoints.
class ModelApiUser {
  final String? id;
  final String brandId;
  final String branchId;
  final String appType;
  final String userType;
  final String role;
  final String firstName;
  final String lastName;
  final String username;
  final String? loginPin;
  final String email;
  final String phoneNumber;
  final List<String> permissions;
  final bool isActive;
  final bool isLocked;
  final int failedLoginAttempts;
  final dynamic lastSeenAt;
  final dynamic createdAt;
  final dynamic updatedAt;

  const ModelApiUser({
    this.id,
    this.brandId = '000000000000000000000000',
    this.branchId = '000000000000000000000000',
    this.appType = 'MARKET',
    this.userType = 'PLATFORM',
    this.role = 'SUPPORT_TEAM',
    required this.firstName,
    required this.lastName,
    required this.username,
    this.loginPin,
    required this.email,
    required this.phoneNumber,
    this.permissions = const [],
    this.isActive = true,
    this.isLocked = false,
    this.failedLoginAttempts = 0,
    this.lastSeenAt,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  int get permissionsCount => permissions.length;

  bool get isPlatform => userType.toUpperCase() == 'PLATFORM';
  bool get isBranch => userType.toUpperCase() == 'BRANCH';
  bool get isBrand => userType.toUpperCase() == 'BRAND';

  factory ModelApiUser.fromJson(Map<String, dynamic> json) {
    List<String> parsedPermissions = [];
    if (json['permissions'] is List) {
      parsedPermissions = (json['permissions'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return ModelApiUser(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      brandId: json['brandId']?.toString() ?? '000000000000000000000000',
      branchId: json['branchId']?.toString() ?? '000000000000000000000000',
      appType: json['appType']?.toString() ?? 'MARKET',
      userType: json['userType']?.toString() ?? 'PLATFORM',
      role: json['role']?.toString() ?? 'SUPPORT_TEAM',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      loginPin: json['loginPin']?.toString(),
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      permissions: parsedPermissions,
      isActive: json['isActive'] == true || json['isActive'] == null,
      isLocked: json['isLocked'] == true,
      failedLoginAttempts: json['failedLoginAttempts'] is int
          ? json['failedLoginAttempts'] as int
          : int.tryParse(json['failedLoginAttempts']?.toString() ?? '0') ?? 0,
      lastSeenAt: json['lastSeenAt'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  /// Converts model to the request JSON payload expected by POST /api/users/create
  Map<String, dynamic> toCreatePayloadJson() {
    final map = <String, dynamic>{
      'brandId': brandId,
      'branchId': branchId,
      'appType': 'MARKET',
      'userType': userType,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      if (loginPin != null && loginPin!.isNotEmpty) 'loginPin': loginPin,
      'email': email,
      'phoneNumber': phoneNumber,
      'permissions': permissions,
    };
    return map;
  }

  /// Converts full model to JSON (including status fields)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'brandId': brandId,
      'branchId': branchId,
      'appType': 'MARKET',
      'userType': userType,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      if (loginPin != null && loginPin!.isNotEmpty) 'loginPin': loginPin,
      'email': email,
      'phoneNumber': phoneNumber,
      'permissions': permissions,
      'isActive': isActive,
      'isLocked': isLocked,
      'failedLoginAttempts': failedLoginAttempts,
      'lastSeenAt': lastSeenAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ModelApiUser copyWith({
    String? id,
    String? brandId,
    String? branchId,
    String? appType,
    String? userType,
    String? role,
    String? firstName,
    String? lastName,
    String? username,
    String? loginPin,
    String? email,
    String? phoneNumber,
    List<String>? permissions,
    bool? isActive,
    bool? isLocked,
    int? failedLoginAttempts,
    dynamic lastSeenAt,
    dynamic createdAt,
    dynamic updatedAt,
  }) {
    return ModelApiUser(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      branchId: branchId ?? this.branchId,
      appType: appType ?? this.appType,
      userType: userType ?? this.userType,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      loginPin: loginPin ?? this.loginPin,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      isLocked: isLocked ?? this.isLocked,
      failedLoginAttempts: failedLoginAttempts ?? this.failedLoginAttempts,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ModelApiUser(id: $id, username: $username, email: $email, role: $role, userType: $userType, appType: $appType)';
  }
}
