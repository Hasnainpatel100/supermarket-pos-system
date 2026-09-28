import 'dart:convert';

/// Localized branch name.
class BranchName {
  final String en;
  final String? ar;
  final String? hi;

  const BranchName({required this.en, this.ar, this.hi});

  factory BranchName.fromJson(Map<String, dynamic> json) {
    return BranchName(
      en: json['en']?.toString() ?? '',
      ar: json['ar']?.toString(),
      hi: json['hi']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'en': en};
    if (ar != null && ar!.isNotEmpty) map['ar'] = ar;
    if (hi != null && hi!.isNotEmpty) map['hi'] = hi;
    return map;
  }

  BranchName copyWith({String? en, String? ar, String? hi}) {
    return BranchName(en: en ?? this.en, ar: ar ?? this.ar, hi: hi ?? this.hi);
  }
}

/// Physical address of a branch.
class BranchAddress {
  final String full;
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final String? latitude;
  final String? longitude;
  final String? gMapUrl;
  final String? gMapPlaceId;

  const BranchAddress({
    this.full = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.zipCode = '',
    this.latitude,
    this.longitude,
    this.gMapUrl,
    this.gMapPlaceId,
  });

  factory BranchAddress.fromJson(Map<String, dynamic> json) {
    return BranchAddress(
      full: json['full']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      gMapUrl: json['gMapUrl']?.toString(),
      gMapPlaceId: json['gMapPlaceId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final lat = double.tryParse(latitude ?? '');
    final lon = double.tryParse(longitude ?? '');
    return {
      'full': full,
      'city': city,
      'state': state,
      'country': country,
      'zipCode': zipCode,
      'latitude': lat ?? 0.0,
      'longitude': lon ?? 0.0,
      if (gMapUrl != null && gMapUrl!.isNotEmpty) 'gMapUrl': gMapUrl,
      if (gMapPlaceId != null && gMapPlaceId!.isNotEmpty) 'gMapPlaceId': gMapPlaceId,
    };
  }

  BranchAddress copyWith({
    String? full,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    String? latitude,
    String? longitude,
    String? gMapUrl,
    String? gMapPlaceId,
  }) {
    return BranchAddress(
      full: full ?? this.full,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gMapUrl: gMapUrl ?? this.gMapUrl,
      gMapPlaceId: gMapPlaceId ?? this.gMapPlaceId,
    );
  }

  bool get hasCoordinates =>
      latitude != null && latitude!.isNotEmpty && longitude != null && longitude!.isNotEmpty;

  String get displaySummary {
    final parts = [city, state, country].where((s) => s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : full;
  }
}

/// Phone numbers for a branch.
class BranchPhones {
  final String primary;
  final String alternate;
  final String whatsapp;

  const BranchPhones({
    this.primary = '',
    this.alternate = '',
    this.whatsapp = '',
  });

  factory BranchPhones.fromJson(Map<String, dynamic> json) {
    return BranchPhones(
      primary: json['primary']?.toString() ?? '',
      alternate: json['alternate']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary': primary,
      'alternate': alternate,
      'whatsapp': whatsapp,
    };
  }

  BranchPhones copyWith({String? primary, String? alternate, String? whatsapp}) {
    return BranchPhones(
      primary: primary ?? this.primary,
      alternate: alternate ?? this.alternate,
      whatsapp: whatsapp ?? this.whatsapp,
    );
  }
}

/// Contact information for a branch.
class BranchContact {
  final BranchPhones phones;
  final String email;

  const BranchContact({
    this.phones = const BranchPhones(),
    this.email = '',
  });

  factory BranchContact.fromJson(Map<String, dynamic> json) {
    return BranchContact(
      phones: json['phones'] is Map<String, dynamic>
          ? BranchPhones.fromJson(json['phones'] as Map<String, dynamic>)
          : const BranchPhones(),
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phones': phones.toJson(),
      'email': email,
    };
  }

  BranchContact copyWith({BranchPhones? phones, String? email}) {
    return BranchContact(phones: phones ?? this.phones, email: email ?? this.email);
  }
}

/// Settings for a branch.
class BranchSettings {
  final bool isMasterBranch;
  final String open;
  final String close;

  const BranchSettings({
    this.isMasterBranch = false,
    this.open = '',
    this.close = '',
  });

  factory BranchSettings.fromJson(Map<String, dynamic> json) {
    return BranchSettings(
      isMasterBranch: json['isMasterBranch'] == true,
      open: json['open']?.toString() ?? '',
      close: json['close']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isMasterBranch': isMasterBranch,
      'open': open,
      'close': close,
    };
  }
}

/// Plan details for a branch.
class BranchPlanDetails {
  final String note;
  final int maxUsers;
  final int maxPosDevices;
  final dynamic expiryAt;
  final String? assignedBy;
  final dynamic assignedAt;

  const BranchPlanDetails({
    this.note = 'Default',
    this.maxUsers = 5,
    this.maxPosDevices = 2,
    this.expiryAt,
    this.assignedBy,
    this.assignedAt,
  });

  factory BranchPlanDetails.fromJson(Map<String, dynamic> json) {
    return BranchPlanDetails(
      note: json['note']?.toString() ?? 'Default',
      maxUsers: json['maxUsers'] is int ? json['maxUsers'] as int : int.tryParse(json['maxUsers']?.toString() ?? '') ?? 5,
      maxPosDevices: json['maxPosDevices'] is int ? json['maxPosDevices'] as int : int.tryParse(json['maxPosDevices']?.toString() ?? '') ?? 2,
      expiryAt: json['expiryAt'],
      assignedBy: json['assignedBy']?.toString(),
      assignedAt: json['assignedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'note': note,
      'maxUsers': maxUsers,
      'maxPosDevices': maxPosDevices,
    };
    if (expiryAt != null) map['expiryAt'] = expiryAt;
    if (assignedBy != null) map['assignedBy'] = assignedBy;
    if (assignedAt != null) map['assignedAt'] = assignedAt;
    return map;
  }
}

/// Core Branch model matching the REST API payload structure.
class ModelBranch {
  final String? id;
  final String? remoteId;
  final String brandId;
  final String? brandName; // Populated when backend joins brand info
  final String branchCode;
  final BranchName name;
  final BranchAddress address;
  final BranchContact contact;
  final BranchSettings settings;
  final BranchPlanDetails? planDetails;
  final List<String> serviceTypes;
  final String appType;
  final String status;
  final String? createdAt;
  final String? createdBy;
  final String? updatedAt;
  final String? updatedBy;

  static const List<String> allServiceTypes = [
    'QUICK_BILL',
    'DELIVERY',
    'DINE_IN',
    'TAKEAWAY',
    'CURBSIDE',
    'ONLINE',
  ];

  const ModelBranch({
    this.id,
    this.remoteId,
    required this.brandId,
    this.brandName,
    this.branchCode = '',
    required this.name,
    this.address = const BranchAddress(),
    this.contact = const BranchContact(),
    this.settings = const BranchSettings(),
    this.planDetails,
    this.serviceTypes = const [],
    this.appType = 'MARKET',
    this.status = 'ACTIVE',
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  factory ModelBranch.fromJson(Map<String, dynamic> json) {
    // brandId can come as a string or as a nested object {_id: ..., name: {en: ...}}
    String brandId = '';
    String? brandName;
    final rawBrand = json['brandId'];
    if (rawBrand is String) {
      brandId = rawBrand;
    } else if (rawBrand is Map<String, dynamic>) {
      brandId = rawBrand['_id']?.toString() ?? rawBrand['id']?.toString() ?? '';
      final nameObj = rawBrand['name'];
      if (nameObj is Map<String, dynamic>) {
        brandName = nameObj['en']?.toString();
      } else {
        brandName = nameObj?.toString();
      }
    }

    // serviceTypes can be a List or null
    final rawServiceTypes = json['serviceTypes'];
    List<String> serviceTypes = [];
    if (rawServiceTypes is List) {
      serviceTypes = rawServiceTypes.map((e) => e.toString()).toList();
    }

    return ModelBranch(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      remoteId: json['remoteId']?.toString(),
      brandId: brandId,
      brandName: brandName,
      branchCode: json['branchCode']?.toString() ?? '',
      name: json['name'] is Map<String, dynamic>
          ? BranchName.fromJson(json['name'] as Map<String, dynamic>)
          : BranchName(en: json['name']?.toString() ?? ''),
      address: json['address'] is Map<String, dynamic>
          ? BranchAddress.fromJson(json['address'] as Map<String, dynamic>)
          : const BranchAddress(),
      contact: json['contact'] is Map<String, dynamic>
          ? BranchContact.fromJson(json['contact'] as Map<String, dynamic>)
          : const BranchContact(),
      settings: json['settings'] is Map<String, dynamic>
          ? BranchSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : const BranchSettings(),
      planDetails: json['planDetails'] is Map<String, dynamic>
          ? BranchPlanDetails.fromJson(json['planDetails'] as Map<String, dynamic>)
          : null,
      serviceTypes: serviceTypes,
      appType: json['appType']?.toString() ?? 'MARKET',
      status: json['status']?.toString() ?? 'ACTIVE',
      createdAt: json['createdAt']?.toString(),
      createdBy: json['createdBy']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
    );
  }

  /// Converts to JSON for POST /api/branches and PUT /api/branches/:id
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'brandId': brandId,
      'branchCode': branchCode,
      'name': name.toJson(),
      'address': address.toJson(),
      'contact': contact.toJson(),
      'serviceTypes': serviceTypes,
      'appType': appType,
      'status': status,
    };
    if (remoteId != null && remoteId!.isNotEmpty) {
      map['remoteId'] = remoteId;
    }
    return map;
  }

  Map<String, dynamic> toMap() {
    final map = toJson();
    // Cache MUST preserve id (including local_ temp IDs) so it can be identified and deleted
    if (id != null && id!.isNotEmpty) map['id'] = id;
    if (brandName != null) map['brandName'] = brandName;
    if (settings != const BranchSettings()) map['settings'] = settings.toJson();
    if (planDetails != null) map['planDetails'] = planDetails!.toJson();
    if (createdAt != null) map['createdAt'] = createdAt;
    if (createdBy != null) map['createdBy'] = createdBy;
    if (updatedAt != null) map['updatedAt'] = updatedAt;
    if (updatedBy != null) map['updatedBy'] = updatedBy;
    return map;
  }

  factory ModelBranch.fromMap(Map<String, dynamic> map) => ModelBranch.fromJson(map);

  String toJsonString({bool pretty = false}) {
    if (pretty) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(toJson());
    }
    return jsonEncode(toJson());
  }

  ModelBranch copyWith({
    String? id,
    String? remoteId,
    String? brandId,
    String? brandName,
    String? branchCode,
    BranchName? name,
    BranchAddress? address,
    BranchContact? contact,
    BranchSettings? settings,
    BranchPlanDetails? planDetails,
    List<String>? serviceTypes,
    String? appType,
    String? status,
    String? createdAt,
    String? createdBy,
    String? updatedAt,
    String? updatedBy,
  }) {
    return ModelBranch(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      branchCode: branchCode ?? this.branchCode,
      name: name ?? this.name,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      settings: settings ?? this.settings,
      planDetails: planDetails ?? this.planDetails,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      appType: appType ?? this.appType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isMarket => appType.toUpperCase() == 'MARKET';
  bool get hasServices => serviceTypes.isNotEmpty;
  String get displayBrandName => brandName ?? brandId;
}
