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
      if (gMapPlaceId != null && gMapPlaceId!.isNotEmpty)
        'gMapPlaceId': gMapPlaceId,
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
      latitude != null &&
      latitude!.isNotEmpty &&
      longitude != null &&
      longitude!.isNotEmpty;

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
    return {'primary': primary, 'alternate': alternate, 'whatsapp': whatsapp};
  }

  BranchPhones copyWith({
    String? primary,
    String? alternate,
    String? whatsapp,
  }) {
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

  const BranchContact({this.phones = const BranchPhones(), this.email = ''});

  factory BranchContact.fromJson(Map<String, dynamic> json) {
    return BranchContact(
      phones: json['phones'] is Map<String, dynamic>
          ? BranchPhones.fromJson(json['phones'] as Map<String, dynamic>)
          : const BranchPhones(),
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'phones': phones.toJson(), 'email': email};
  }

  BranchContact copyWith({BranchPhones? phones, String? email}) {
    return BranchContact(
      phones: phones ?? this.phones,
      email: email ?? this.email,
    );
  }
}

/// Billing configuration for a branch.
class BranchBillingSettings {
  final int billResetDays;
  final int kotResetDays;
  final String billPrefix;

  const BranchBillingSettings({
    this.billResetDays = 0,
    this.kotResetDays = 0,
    this.billPrefix = '',
  });

  factory BranchBillingSettings.fromJson(Map<String, dynamic> json) {
    return BranchBillingSettings(
      billResetDays: json['billResetDays'] is int
          ? json['billResetDays'] as int
          : int.tryParse(json['billResetDays']?.toString() ?? '') ?? 0,
      kotResetDays: json['kotResetDays'] is int
          ? json['kotResetDays'] as int
          : int.tryParse(json['kotResetDays']?.toString() ?? '') ?? 0,
      billPrefix: json['billPrefix']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'billResetDays': billResetDays,
      'kotResetDays': kotResetDays,
      'billPrefix': billPrefix,
    };
  }

  BranchBillingSettings copyWith({
    int? billResetDays,
    int? kotResetDays,
    String? billPrefix,
  }) {
    return BranchBillingSettings(
      billResetDays: billResetDays ?? this.billResetDays,
      kotResetDays: kotResetDays ?? this.kotResetDays,
      billPrefix: billPrefix ?? this.billPrefix,
    );
  }
}

/// Invoice display configuration for a branch.
class BranchInvoiceSettings {
  final bool showGstBreakup;
  final bool showFssaiNo;
  final String footerText;

  const BranchInvoiceSettings({
    this.showGstBreakup = false,
    this.showFssaiNo = false,
    this.footerText = '',
  });

  factory BranchInvoiceSettings.fromJson(Map<String, dynamic> json) {
    return BranchInvoiceSettings(
      showGstBreakup: json['showGstBreakup'] == true,
      showFssaiNo: json['showFssaiNo'] == true,
      footerText: json['footerText']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showGstBreakup': showGstBreakup,
      'showFssaiNo': showFssaiNo,
      'footerText': footerText,
    };
  }

  BranchInvoiceSettings copyWith({
    bool? showGstBreakup,
    bool? showFssaiNo,
    String? footerText,
  }) {
    return BranchInvoiceSettings(
      showGstBreakup: showGstBreakup ?? this.showGstBreakup,
      showFssaiNo: showFssaiNo ?? this.showFssaiNo,
      footerText: footerText ?? this.footerText,
    );
  }
}

/// Full settings block for a branch (matches the API `settings` object).
class BranchSettings {
  final bool isMasterBranch;
  final String open;
  final String close;
  final String currency;
  final String timezone;
  final String theme;
  final BranchBillingSettings billing;
  final BranchInvoiceSettings invoice;

  const BranchSettings({
    this.isMasterBranch = false,
    this.open = '',
    this.close = '',
    this.currency = '',
    this.timezone = '',
    this.theme = '',
    this.billing = const BranchBillingSettings(),
    this.invoice = const BranchInvoiceSettings(),
  });

  factory BranchSettings.fromJson(Map<String, dynamic> json) {
    return BranchSettings(
      isMasterBranch: json['isMasterBranch'] == true,
      open: json['open']?.toString() ?? '',
      close: json['close']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      timezone: json['timezone']?.toString() ?? '',
      theme: json['theme']?.toString() ?? '',
      billing: json['billing'] is Map<String, dynamic>
          ? BranchBillingSettings.fromJson(
              json['billing'] as Map<String, dynamic>,
            )
          : const BranchBillingSettings(),
      invoice: json['invoice'] is Map<String, dynamic>
          ? BranchInvoiceSettings.fromJson(
              json['invoice'] as Map<String, dynamic>,
            )
          : const BranchInvoiceSettings(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isMasterBranch': isMasterBranch,
      'open': open,
      'close': close,
      'currency': currency,
      'timezone': timezone,
      'theme': theme,
      'billing': billing.toJson(),
      'invoice': invoice.toJson(),
    };
  }

  BranchSettings copyWith({
    bool? isMasterBranch,
    String? open,
    String? close,
    String? currency,
    String? timezone,
    String? theme,
    BranchBillingSettings? billing,
    BranchInvoiceSettings? invoice,
  }) {
    return BranchSettings(
      isMasterBranch: isMasterBranch ?? this.isMasterBranch,
      open: open ?? this.open,
      close: close ?? this.close,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      theme: theme ?? this.theme,
      billing: billing ?? this.billing,
      invoice: invoice ?? this.invoice,
    );
  }
}

/// Registration and compliance data for a Branch.
class BranchRegistration {
  final String gstNo;
  final String gstType;
  final String gstRegistrationDate;
  final String fssaiNo;
  final String fssaiExpiryDate;
  final String cin;

  const BranchRegistration({
    this.gstNo = '',
    this.gstType = '',
    this.gstRegistrationDate = '',
    this.fssaiNo = '',
    this.fssaiExpiryDate = '',
    this.cin = '',
  });

  factory BranchRegistration.fromJson(Map<String, dynamic> json) {
    return BranchRegistration(
      gstNo: json['gstNo']?.toString() ?? '',
      gstType: json['gstType']?.toString() ?? '',
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
}

/// UPI payment details for a Branch.
class BranchUpi {
  final String upiId;
  final String qrImage;

  const BranchUpi({this.upiId = '', this.qrImage = ''});

  factory BranchUpi.fromJson(Map<String, dynamic> json) {
    return BranchUpi(
      upiId: json['upiId']?.toString() ?? '',
      qrImage: json['qrImage']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'upiId': upiId, 'qrImage': qrImage};
}

/// Bank payment details for a Branch.
class BranchBank {
  final String bankName;
  final String branchName;
  final String ifsc;
  final String accountNumber;
  final String beneficiaryName;

  const BranchBank({
    this.bankName = '',
    this.branchName = '',
    this.ifsc = '',
    this.accountNumber = '',
    this.beneficiaryName = '',
  });

  factory BranchBank.fromJson(Map<String, dynamic> json) {
    return BranchBank(
      bankName: json['bankName']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      ifsc: json['ifsc']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      beneficiaryName: json['beneficiaryName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'bankName': bankName,
    'branchName': branchName,
    'ifsc': ifsc,
    'accountNumber': accountNumber,
    'beneficiaryName': beneficiaryName,
  };
}

/// Payment configurations for a Branch.
class BranchPayment {
  final List<String> supportedPaymentModes;
  final BranchUpi upi;
  final BranchBank bank;
  final String pan;

  const BranchPayment({
    this.supportedPaymentModes = const [],
    this.upi = const BranchUpi(),
    this.bank = const BranchBank(),
    this.pan = '',
  });

  factory BranchPayment.fromJson(Map<String, dynamic> json) {
    final rawModes = json['supportedPaymentModes'];
    List<String> modes = [];
    if (rawModes is List) {
      modes = rawModes.map((e) => e.toString()).toList();
    }
    return BranchPayment(
      supportedPaymentModes: modes,
      upi: json['upi'] is Map<String, dynamic>
          ? BranchUpi.fromJson(json['upi'] as Map<String, dynamic>)
          : const BranchUpi(),
      bank: json['bank'] is Map<String, dynamic>
          ? BranchBank.fromJson(json['bank'] as Map<String, dynamic>)
          : const BranchBank(),
      pan: json['pan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'supportedPaymentModes': supportedPaymentModes,
    'upi': upi.toJson(),
    'bank': bank.toJson(),
    'pan': pan,
  };
}

/// Plan details for a branch.
class BranchPlanDetails {
  final String note;
  final int maxUsers;
  final int maxPosDevices;
  final dynamic expiryAt;
  final int? pushFromLastDays;
  final String? assignedBy;
  final dynamic assignedAt;

  const BranchPlanDetails({
    this.note = 'Default',
    this.maxUsers = 5,
    this.maxPosDevices = 2,
    this.expiryAt,
    this.pushFromLastDays,
    this.assignedBy,
    this.assignedAt,
  });

  factory BranchPlanDetails.fromJson(Map<String, dynamic> json) {
    return BranchPlanDetails(
      note: json['note']?.toString() ?? 'Default',
      maxUsers: json['maxUsers'] is int
          ? json['maxUsers'] as int
          : int.tryParse(json['maxUsers']?.toString() ?? '') ?? 5,
      maxPosDevices: json['maxPosDevices'] is int
          ? json['maxPosDevices'] as int
          : int.tryParse(json['maxPosDevices']?.toString() ?? '') ?? 2,
      expiryAt: json['expiryAt'],
      pushFromLastDays: json['pushFromLastDays'] is int
          ? json['pushFromLastDays'] as int
          : int.tryParse(json['pushFromLastDays']?.toString() ?? ''),
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
    if (pushFromLastDays != null) map['pushFromLastDays'] = pushFromLastDays;
    if (assignedBy != null) map['assignedBy'] = assignedBy;
    if (assignedAt != null) map['assignedAt'] = assignedAt;
    return map;
  }

  /// Parses [expiryAt] to a [DateTime] object regardless of timestamp format (int ms/s, String, ISO).
  /// Always returns a local DateTime so calendar comparisons match the user's timezone.
  DateTime? get expiryDate {
    if (expiryAt == null) return null;
    if (expiryAt is DateTime) return (expiryAt as DateTime).toLocal();
    if (expiryAt is int) {
      final val = expiryAt as int;
      return DateTime.fromMillisecondsSinceEpoch(
        val > 100000000000 ? val : val * 1000,
      ).toLocal();
    }
    if (expiryAt is num) {
      final val = (expiryAt as num).toInt();
      return DateTime.fromMillisecondsSinceEpoch(
        val > 100000000000 ? val : val * 1000,
      ).toLocal();
    }
    final str = expiryAt.toString().trim();
    if (str.isEmpty) return null;
    final parsedInt = int.tryParse(str);
    if (parsedInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        parsedInt > 100000000000 ? parsedInt : parsedInt * 1000,
      ).toLocal();
    }
    return DateTime.tryParse(str)?.toLocal();
  }

  /// Parses [assignedAt] to a [DateTime] object.
  DateTime? get assignedDate {
    if (assignedAt == null) return null;
    if (assignedAt is DateTime) return (assignedAt as DateTime).toLocal();
    if (assignedAt is int) {
      final val = assignedAt as int;
      return DateTime.fromMillisecondsSinceEpoch(
        val > 100000000000 ? val : val * 1000,
      ).toLocal();
    }
    if (assignedAt is num) {
      final val = (assignedAt as num).toInt();
      return DateTime.fromMillisecondsSinceEpoch(
        val > 100000000000 ? val : val * 1000,
      ).toLocal();
    }
    final str = assignedAt.toString().trim();
    if (str.isEmpty) return null;
    final parsedInt = int.tryParse(str);
    if (parsedInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        parsedInt > 100000000000 ? parsedInt : parsedInt * 1000,
      ).toLocal();
    }
    return DateTime.tryParse(str)?.toLocal();
  }

  /// Checks if the plan has already passed its expiry date.
  /// A plan expiring on date X is valid throughout the entire day of date X (until 23:59:59.999),
  /// and is only considered expired starting the next calendar day.
  bool get isExpired {
    final exp = expiryDate;
    if (exp == null) return false;
    final endOfExpiryDay = DateTime(exp.year, exp.month, exp.day, 23, 59, 59, 999);
    return DateTime.now().isAfter(endOfExpiryDay);
  }

  /// Calculates remaining whole calendar days until expiration.
  /// Returns:
  ///   > 0 : Days left (e.g. 1 means expires tomorrow)
  ///   0   : Expires today (plan is still active today)
  ///   < 0 : Expired (e.g. -1 means expired yesterday)
  int? get daysRemaining {
    final exp = expiryDate;
    if (exp == null) return null;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final expDateStart = DateTime(exp.year, exp.month, exp.day);
    return expDateStart.difference(todayStart).inDays;
  }

  /// Whether the plan is expired or will expire within the alert window
  /// (defaulting to 15 days or custom pushFromLastDays).
  bool get isExpiringSoon {
    if (isExpired) return true;
    final days = daysRemaining;
    if (days == null) return false;
    final threshold = (pushFromLastDays != null && pushFromLastDays! > 0)
        ? pushFromLastDays!
        : 15;
    return days <= threshold;
  }

  /// Human-readable date string e.g. "15/10/2026"
  String get formattedExpiry {
    final exp = expiryDate;
    if (exp == null) return 'No Expiry';
    return '${exp.day.toString().padLeft(2, '0')}/${exp.month.toString().padLeft(2, '0')}/${exp.year}';
  }

  /// Human-readable assigned date string e.g. "01/10/2026"
  String get formattedAssignedAt {
    final ass = assignedDate;
    if (ass == null) return 'N/A';
    return '${ass.day.toString().padLeft(2, '0')}/${ass.month.toString().padLeft(2, '0')}/${ass.year}';
  }

  /// Summary badge text e.g. "Expires in 14 days", "Expires Tomorrow", "Expires Today", or "Plan Expired"
  String get expiryStatusText {
    final exp = expiryDate;
    if (exp == null) return 'Active Plan';
    if (isExpired) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final expDateStart = DateTime(exp.year, exp.month, exp.day);
      final daysAgo = todayStart.difference(expDateStart).inDays;
      if (daysAgo <= 1) return 'Expired Yesterday';
      return 'Expired $daysAgo days ago';
    }
    final days = daysRemaining ?? 0;
    if (days == 0) return 'Expires Today';
    if (days == 1) return 'Expires Tomorrow';
    return 'Expires in $days days';
  }
}

/// Represents an archived or historical plan record from GET /api/branches/:id/plan-history
class ModelBranchPlanHistory {
  final String? id;
  final String branchId;
  final String brandId;
  final String note;
  final int maxUsers;
  final int maxPosDevices;
  final dynamic expiryAt;
  final int? pushFromLastDays;
  final String? assignedBy;
  final dynamic assignedAt;

  const ModelBranchPlanHistory({
    this.id,
    required this.branchId,
    this.brandId = '',
    this.note = '',
    this.maxUsers = 5,
    this.maxPosDevices = 2,
    this.expiryAt,
    this.pushFromLastDays,
    this.assignedBy,
    this.assignedAt,
  });

  factory ModelBranchPlanHistory.fromJson(Map<String, dynamic> json) {
    return ModelBranchPlanHistory(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      branchId: json['branchId']?.toString() ?? '',
      brandId: json['brandId']?.toString() ?? '',
      note: json['note']?.toString() ?? 'Plan Record',
      maxUsers: json['maxUsers'] is int
          ? json['maxUsers'] as int
          : int.tryParse(json['maxUsers']?.toString() ?? '') ?? 5,
      maxPosDevices: json['maxPosDevices'] is int
          ? json['maxPosDevices'] as int
          : int.tryParse(json['maxPosDevices']?.toString() ?? '') ?? 2,
      expiryAt: json['expiryAt'],
      pushFromLastDays: json['pushFromLastDays'] is int
          ? json['pushFromLastDays'] as int
          : int.tryParse(json['pushFromLastDays']?.toString() ?? ''),
      assignedBy: json['assignedBy']?.toString(),
      assignedAt: json['assignedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'branchId': branchId,
      'brandId': brandId,
      'note': note,
      'maxUsers': maxUsers,
      'maxPosDevices': maxPosDevices,
      if (expiryAt != null) 'expiryAt': expiryAt,
      if (pushFromLastDays != null) 'pushFromLastDays': pushFromLastDays,
      if (assignedBy != null) 'assignedBy': assignedBy,
      if (assignedAt != null) 'assignedAt': assignedAt,
    };
  }

  DateTime? get expiryDate {
    if (expiryAt == null) return null;
    if (expiryAt is DateTime) return (expiryAt as DateTime).toLocal();
    if (expiryAt is int) {
      final val = expiryAt as int;
      return DateTime.fromMillisecondsSinceEpoch(
        val > 100000000000 ? val : val * 1000,
      ).toLocal();
    }
    if (expiryAt is num) {
      final val = (expiryAt as num).toInt();
      return DateTime.fromMillisecondsSinceEpoch(
        val > 100000000000 ? val : val * 1000,
      ).toLocal();
    }
    final str = expiryAt.toString().trim();
    if (str.isEmpty) return null;
    final parsedInt = int.tryParse(str);
    if (parsedInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        parsedInt > 100000000000 ? parsedInt : parsedInt * 1000,
      ).toLocal();
    }
    return DateTime.tryParse(str)?.toLocal();
  }

  DateTime? get assignedDate {
    if (assignedAt == null) return null;
    if (assignedAt is DateTime) return (assignedAt as DateTime).toLocal();
    if (assignedAt is int) {
      final val = assignedAt as int;
      return DateTime.fromMillisecondsSinceEpoch(
        val > 100000000000 ? val : val * 1000,
      ).toLocal();
    }
    if (assignedAt is num) {
      final val = (assignedAt as num).toInt();
      return DateTime.fromMillisecondsSinceEpoch(
        val > 100000000000 ? val : val * 1000,
      ).toLocal();
    }
    final str = assignedAt.toString().trim();
    if (str.isEmpty) return null;
    final parsedInt = int.tryParse(str);
    if (parsedInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        parsedInt > 100000000000 ? parsedInt : parsedInt * 1000,
      ).toLocal();
    }
    return DateTime.tryParse(str)?.toLocal();
  }

  bool get isExpired {
    final exp = expiryDate;
    if (exp == null) return false;
    final endOfExpiryDay = DateTime(exp.year, exp.month, exp.day, 23, 59, 59, 999);
    return DateTime.now().isAfter(endOfExpiryDay);
  }

  int? get daysRemaining {
    final exp = expiryDate;
    if (exp == null) return null;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final expDateStart = DateTime(exp.year, exp.month, exp.day);
    return expDateStart.difference(todayStart).inDays;
  }

  String get formattedExpiry {
    final exp = expiryDate;
    if (exp == null) return 'No Expiry';
    return '${exp.day.toString().padLeft(2, '0')}/${exp.month.toString().padLeft(2, '0')}/${exp.year}';
  }

  String get formattedAssignedAt {
    final ass = assignedDate;
    if (ass == null) return 'N/A';
    return '${ass.day.toString().padLeft(2, '0')}/${ass.month.toString().padLeft(2, '0')}/${ass.year}';
  }

  String get expiryStatusText {
    final exp = expiryDate;
    if (exp == null) return 'Historic Plan';
    if (isExpired) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final expDateStart = DateTime(exp.year, exp.month, exp.day);
      final daysAgo = todayStart.difference(expDateStart).inDays;
      if (daysAgo <= 1) return 'Expired Yesterday';
      return 'Expired $daysAgo days ago';
    }
    final days = daysRemaining ?? 0;
    if (days == 0) return 'Expires Today';
    if (days == 1) return 'Expires Tomorrow';
    return 'Expires in $days days';
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
  final BranchRegistration registration;
  final BranchSettings settings;
  final BranchPayment payment;
  final BranchPlanDetails? planDetails;
  final List<String> serviceTypes;
  final String appType;
  final String status;
  final String? imageId;
  final String? directOriginalUrl;
  final String? directThumbnailUrl;
  final List<String> carouselImageIds;
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
    this.registration = const BranchRegistration(),
    this.settings = const BranchSettings(),
    this.payment = const BranchPayment(),
    this.planDetails,
    this.serviceTypes = const [],
    this.appType = 'MARKET',
    this.status = 'ACTIVE',
    this.imageId,
    this.directOriginalUrl,
    this.directThumbnailUrl,
    this.carouselImageIds = const [],
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

    final rawCarousel = json['carouselImageIds'];
    List<String> carouselList = [];
    if (rawCarousel is List) {
      carouselList = rawCarousel.map((e) => e.toString()).toList();
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
      registration: json['registration'] is Map<String, dynamic>
          ? BranchRegistration.fromJson(json['registration'] as Map<String, dynamic>)
          : const BranchRegistration(),
      settings: json['settings'] is Map<String, dynamic>
          ? BranchSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : const BranchSettings(),
      payment: json['payment'] is Map<String, dynamic>
          ? BranchPayment.fromJson(json['payment'] as Map<String, dynamic>)
          : const BranchPayment(),
      planDetails: json['planDetails'] is Map<String, dynamic>
          ? BranchPlanDetails.fromJson(
              json['planDetails'] as Map<String, dynamic>,
            )
          : null,
      serviceTypes: serviceTypes,
      appType: json['appType']?.toString() ?? 'MARKET',
      status: json['status']?.toString() ?? 'ACTIVE',
      imageId: json['imageId']?.toString(),
      directOriginalUrl: json['directOriginalUrl']?.toString(),
      directThumbnailUrl: json['directThumbnailUrl']?.toString(),
      carouselImageIds: carouselList,
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
      'registration': registration.toJson(),
      'settings': settings.toJson(),
      'payment': payment.toJson(),
      'serviceTypes': serviceTypes,
      'appType': appType,
      'status': status,
    };
    if (remoteId != null && remoteId!.isNotEmpty) {
      map['remoteId'] = remoteId;
    }
    if (planDetails != null) {
      map['planDetails'] = planDetails!.toJson();
    }
    if (imageId != null) map['imageId'] = imageId;
    if (directOriginalUrl != null) map['directOriginalUrl'] = directOriginalUrl;
    if (directThumbnailUrl != null) map['directThumbnailUrl'] = directThumbnailUrl;
    if (carouselImageIds.isNotEmpty) map['carouselImageIds'] = carouselImageIds;
    return map;
  }

  Map<String, dynamic> toMap() {
    final map = toJson();
    // Cache MUST preserve id (including local_ temp IDs) so it can be identified and deleted
    if (id != null && id!.isNotEmpty) map['id'] = id;
    if (brandName != null) map['brandName'] = brandName;
    if (planDetails != null) map['planDetails'] = planDetails!.toJson();
    if (createdAt != null) map['createdAt'] = createdAt;
    if (createdBy != null) map['createdBy'] = createdBy;
    if (updatedAt != null) map['updatedAt'] = updatedAt;
    if (updatedBy != null) map['updatedBy'] = updatedBy;
    return map;
  }

  factory ModelBranch.fromMap(Map<String, dynamic> map) =>
      ModelBranch.fromJson(map);

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
    BranchRegistration? registration,
    BranchSettings? settings,
    BranchPayment? payment,
    BranchPlanDetails? planDetails,
    List<String>? serviceTypes,
    String? appType,
    String? status,
    String? imageId,
    String? directOriginalUrl,
    String? directThumbnailUrl,
    List<String>? carouselImageIds,
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
      registration: registration ?? this.registration,
      settings: settings ?? this.settings,
      payment: payment ?? this.payment,
      planDetails: planDetails ?? this.planDetails,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      appType: appType ?? this.appType,
      status: status ?? this.status,
      imageId: imageId ?? this.imageId,
      directOriginalUrl: directOriginalUrl ?? this.directOriginalUrl,
      directThumbnailUrl: directThumbnailUrl ?? this.directThumbnailUrl,
      carouselImageIds: carouselImageIds ?? this.carouselImageIds,
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
