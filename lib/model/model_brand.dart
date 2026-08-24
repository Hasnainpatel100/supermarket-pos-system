import 'dart:convert';

/// Represents the localized brand name.
class BrandName {
  final String en;
  final String? ar;
  final String? hi;

  const BrandName({
    required this.en,
    this.ar,
    this.hi,
  });

  factory BrandName.fromJson(Map<String, dynamic> json) {
    return BrandName(
      en: json['en']?.toString() ?? '',
      ar: json['ar']?.toString(),
      hi: json['hi']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'en': en,
    };
    if (ar != null && ar!.isNotEmpty) map['ar'] = ar;
    if (hi != null && hi!.isNotEmpty) map['hi'] = hi;
    return map;
  }

  BrandName copyWith({
    String? en,
    String? ar,
    String? hi,
  }) {
    return BrandName(
      en: en ?? this.en,
      ar: ar ?? this.ar,
      hi: hi ?? this.hi,
    );
  }
}

/// Registration and compliance data for a Brand.
class BrandRegistration {
  final String gstNo;
  final String gstType;
  final String gstRegistrationDate;
  final String fssaiNo;
  final String fssaiExpiryDate;
  final String cin;

  const BrandRegistration({
    this.gstNo = '',
    this.gstType = 'VAT',
    this.gstRegistrationDate = '',
    this.fssaiNo = '',
    this.fssaiExpiryDate = '',
    this.cin = '',
  });

  factory BrandRegistration.fromJson(Map<String, dynamic> json) {
    return BrandRegistration(
      gstNo: json['gstNo']?.toString() ?? '',
      gstType: json['gstType']?.toString() ?? 'VAT',
      gstRegistrationDate: json['gstRegistrationDate']?.toString() ?? '',
      fssaiNo: json['fssaiNo']?.toString() ?? '',
      fssaiExpiryDate: json['fssaiExpiryDate']?.toString() ?? '',
      cin: json['cin']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gstNo': gstNo,
      'gstType': gstType,
      'gstRegistrationDate': gstRegistrationDate,
      'fssaiNo': fssaiNo,
      'fssaiExpiryDate': fssaiExpiryDate,
      'cin': cin,
    };
  }

  BrandRegistration copyWith({
    String? gstNo,
    String? gstType,
    String? gstRegistrationDate,
    String? fssaiNo,
    String? fssaiExpiryDate,
    String? cin,
  }) {
    return BrandRegistration(
      gstNo: gstNo ?? this.gstNo,
      gstType: gstType ?? this.gstType,
      gstRegistrationDate: gstRegistrationDate ?? this.gstRegistrationDate,
      fssaiNo: fssaiNo ?? this.fssaiNo,
      fssaiExpiryDate: fssaiExpiryDate ?? this.fssaiExpiryDate,
      cin: cin ?? this.cin,
    );
  }
}

/// Phone numbers associated with a Brand.
class BrandPhones {
  final String primary;
  final String alternate;
  final String whatsapp;

  const BrandPhones({
    this.primary = '',
    this.alternate = '',
    this.whatsapp = '',
  });

  factory BrandPhones.fromJson(Map<String, dynamic> json) {
    return BrandPhones(
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

  BrandPhones copyWith({
    String? primary,
    String? alternate,
    String? whatsapp,
  }) {
    return BrandPhones(
      primary: primary ?? this.primary,
      alternate: alternate ?? this.alternate,
      whatsapp: whatsapp ?? this.whatsapp,
    );
  }
}

/// Contact details for a Brand.
class BrandContact {
  final BrandPhones phones;
  final String email;
  final String website;

  const BrandContact({
    this.phones = const BrandPhones(),
    this.email = '',
    this.website = '',
  });

  factory BrandContact.fromJson(Map<String, dynamic> json) {
    return BrandContact(
      phones: json['phones'] is Map<String, dynamic>
          ? BrandPhones.fromJson(json['phones'] as Map<String, dynamic>)
          : const BrandPhones(),
      email: json['email']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phones': phones.toJson(),
      'email': email,
      'website': website,
    };
  }

  BrandContact copyWith({
    BrandPhones? phones,
    String? email,
    String? website,
  }) {
    return BrandContact(
      phones: phones ?? this.phones,
      email: email ?? this.email,
      website: website ?? this.website,
    );
  }
}

/// Core Brand model matching the REST API payload structure.
class ModelBrand {
  final String? id;
  final String? ownerId;
  final String? branchCode;
  final BrandName name;
  final BrandRegistration registration;
  final BrandContact contact;
  final String appType;
  final String status;
  final String? statusReason;
  final String? createdAt;
  final String? createdBy;
  final String? updatedAt;
  final String? updatedBy;

  const ModelBrand({
    this.id,
    this.ownerId,
    this.branchCode,
    required this.name,
    this.registration = const BrandRegistration(),
    this.contact = const BrandContact(),
    this.appType = 'MARKET',
    this.status = 'ACTIVE',
    this.statusReason,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  factory ModelBrand.fromJson(Map<String, dynamic> json) {
    return ModelBrand(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      ownerId: json['ownerId']?.toString(),
      branchCode: json['branchCode']?.toString(),
      name: json['name'] is Map<String, dynamic>
          ? BrandName.fromJson(json['name'] as Map<String, dynamic>)
          : BrandName(en: json['name']?.toString() ?? ''),
      registration: json['registration'] is Map<String, dynamic>
          ? BrandRegistration.fromJson(json['registration'] as Map<String, dynamic>)
          : const BrandRegistration(),
      contact: json['contact'] is Map<String, dynamic>
          ? BrandContact.fromJson(json['contact'] as Map<String, dynamic>)
          : const BrandContact(),
      appType: json['appType']?.toString() ?? 'MARKET',
      status: json['status']?.toString() ?? 'ACTIVE',
      statusReason: json['statusReason']?.toString(),
      createdAt: json['createdAt']?.toString(),
      createdBy: json['createdBy']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
    );
  }

  /// Converts to JSON matching the exact API payload for create / update
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name.toJson(),
      'registration': registration.toJson(),
      'contact': contact.toJson(),
      'appType': appType,
      'status': status,
    };
    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  /// For storage and serialization
  Map<String, dynamic> toMap() {
    final map = toJson();
    if (ownerId != null) map['ownerId'] = ownerId;
    if (branchCode != null) map['branchCode'] = branchCode;
    if (statusReason != null) map['statusReason'] = statusReason;
    if (createdAt != null) map['createdAt'] = createdAt;
    if (createdBy != null) map['createdBy'] = createdBy;
    if (updatedAt != null) map['updatedAt'] = updatedAt;
    if (updatedBy != null) map['updatedBy'] = updatedBy;
    return map;
  }

  factory ModelBrand.fromMap(Map<String, dynamic> map) => ModelBrand.fromJson(map);

  String toJsonString({bool pretty = false}) {
    if (pretty) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(toJson());
    }
    return jsonEncode(toJson());
  }

  ModelBrand copyWith({
    String? id,
    String? ownerId,
    String? branchCode,
    BrandName? name,
    BrandRegistration? registration,
    BrandContact? contact,
    String? appType,
    String? status,
    String? statusReason,
    String? createdAt,
    String? createdBy,
    String? updatedAt,
    String? updatedBy,
  }) {
    return ModelBrand(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      branchCode: branchCode ?? this.branchCode,
      name: name ?? this.name,
      registration: registration ?? this.registration,
      contact: contact ?? this.contact,
      appType: appType ?? this.appType,
      status: status ?? this.status,
      statusReason: statusReason ?? this.statusReason,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isMarket => appType.toUpperCase() == 'MARKET';
  bool get isRestaurant => appType.toUpperCase() == 'RESTAURANT';
}
