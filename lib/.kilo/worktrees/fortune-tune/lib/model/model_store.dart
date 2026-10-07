class ModelStore {
  ModelStore({
    String? id,
    String? code,
    String? name,
    String? status,
    Address? address,
    Contact? contact,
    Business? business,
    Pos? pos,
    Tax? tax,
    Pricing? pricing,
    Inventory? inventory,
    List<PaymentMethods>? paymentMethods,
    Sync? sync,
    num? version,
    String? updatedAt,
  }) {
    _id = id;
    _code = code;
    _name = name;
    _status = status;
    _address = address;
    _contact = contact;
    _business = business;
    _pos = pos;
    _tax = tax;
    _pricing = pricing;
    _inventory = inventory;
    _paymentMethods = paymentMethods;
    _sync = sync;
    _version = version;
    _updatedAt = updatedAt;
  }

  ModelStore.fromJson(dynamic json) {
    _id = json['_id'];
    _code = json['code'];
    _name = json['name'];
    _status = json['status'];
    _address = json['address'] != null
        ? Address.fromJson(json['address'])
        : null;
    _contact = json['contact'] != null
        ? Contact.fromJson(json['contact'])
        : null;
    _business = json['business'] != null
        ? Business.fromJson(json['business'])
        : null;
    _pos = json['pos'] != null ? Pos.fromJson(json['pos']) : null;
    _tax = json['tax'] != null ? Tax.fromJson(json['tax']) : null;
    _pricing = json['pricing'] != null
        ? Pricing.fromJson(json['pricing'])
        : null;
    _inventory = json['inventory'] != null
        ? Inventory.fromJson(json['inventory'])
        : null;
    if (json['paymentMethods'] != null) {
      _paymentMethods = [];
      json['paymentMethods'].forEach((v) {
        _paymentMethods?.add(PaymentMethods.fromJson(v));
      });
    }
    _sync = json['sync'] != null ? Sync.fromJson(json['sync']) : null;
    _version = json['version'];
    _updatedAt = json['updatedAt'];
  }

  String? _id;
  String? _code;
  String? _name;
  String? _status;
  Address? _address;
  Contact? _contact;
  Business? _business;
  Pos? _pos;
  Tax? _tax;
  Pricing? _pricing;
  Inventory? _inventory;
  List<PaymentMethods>? _paymentMethods;
  Sync? _sync;
  num? _version;
  String? _updatedAt;

  ModelStore copyWith({
    String? id,
    String? code,
    String? name,
    String? status,
    Address? address,
    Contact? contact,
    Business? business,
    Pos? pos,
    Tax? tax,
    Pricing? pricing,
    Inventory? inventory,
    List<PaymentMethods>? paymentMethods,
    Sync? sync,
    num? version,
    String? updatedAt,
  }) => ModelStore(
    id: id ?? _id,
    code: code ?? _code,
    name: name ?? _name,
    status: status ?? _status,
    address: address ?? _address,
    contact: contact ?? _contact,
    business: business ?? _business,
    pos: pos ?? _pos,
    tax: tax ?? _tax,
    pricing: pricing ?? _pricing,
    inventory: inventory ?? _inventory,
    paymentMethods: paymentMethods ?? _paymentMethods,
    sync: sync ?? _sync,
    version: version ?? _version,
    updatedAt: updatedAt ?? _updatedAt,
  );

  String? get id => _id;

  String? get code => _code;

  String? get name => _name;

  String? get status => _status;

  Address? get address => _address;

  Contact? get contact => _contact;

  Business? get business => _business;

  Pos? get pos => _pos;

  Tax? get tax => _tax;

  Pricing? get pricing => _pricing;

  Inventory? get inventory => _inventory;

  List<PaymentMethods>? get paymentMethods => _paymentMethods;

  Sync? get sync => _sync;

  num? get version => _version;

  String? get updatedAt => _updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['_id'] = _id;
    map['code'] = _code;
    map['name'] = _name;
    map['status'] = _status;
    if (_address != null) {
      map['address'] = _address?.toJson();
    }
    if (_contact != null) {
      map['contact'] = _contact?.toJson();
    }
    if (_business != null) {
      map['business'] = _business?.toJson();
    }
    if (_pos != null) {
      map['pos'] = _pos?.toJson();
    }
    if (_tax != null) {
      map['tax'] = _tax?.toJson();
    }
    if (_pricing != null) {
      map['pricing'] = _pricing?.toJson();
    }
    if (_inventory != null) {
      map['inventory'] = _inventory?.toJson();
    }
    if (_paymentMethods != null) {
      map['paymentMethods'] = _paymentMethods?.map((v) => v.toJson()).toList();
    }
    if (_sync != null) {
      map['sync'] = _sync?.toJson();
    }
    map['version'] = _version;
    map['updatedAt'] = _updatedAt;
    return map;
  }
}

/// mode : "HYBRID"
/// syncIntervalMinutes : 10
/// lastSyncedAt : "2025-12-25T08:45:00Z"

class Sync {
  Sync({String? mode, num? syncIntervalMinutes, String? lastSyncedAt}) {
    _mode = mode;
    _syncIntervalMinutes = syncIntervalMinutes;
    _lastSyncedAt = lastSyncedAt;
  }

  Sync.fromJson(dynamic json) {
    _mode = json['mode'];
    _syncIntervalMinutes = json['syncIntervalMinutes'];
    _lastSyncedAt = json['lastSyncedAt'];
  }

  String? _mode;
  num? _syncIntervalMinutes;
  String? _lastSyncedAt;

  Sync copyWith({
    String? mode,
    num? syncIntervalMinutes,
    String? lastSyncedAt,
  }) => Sync(
    mode: mode ?? _mode,
    syncIntervalMinutes: syncIntervalMinutes ?? _syncIntervalMinutes,
    lastSyncedAt: lastSyncedAt ?? _lastSyncedAt,
  );

  String? get mode => _mode;

  num? get syncIntervalMinutes => _syncIntervalMinutes;

  String? get lastSyncedAt => _lastSyncedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['mode'] = _mode;
    map['syncIntervalMinutes'] = _syncIntervalMinutes;
    map['lastSyncedAt'] = _lastSyncedAt;
    return map;
  }
}

/// code : "CASH"
/// enabled : true

class PaymentMethods {
  PaymentMethods({String? code, bool? enabled}) {
    _code = code;
    _enabled = enabled;
  }

  PaymentMethods.fromJson(dynamic json) {
    _code = json['code'];
    _enabled = json['enabled'];
  }

  String? _code;
  bool? _enabled;

  PaymentMethods copyWith({String? code, bool? enabled}) =>
      PaymentMethods(code: code ?? _code, enabled: enabled ?? _enabled);

  String? get code => _code;

  bool? get enabled => _enabled;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['code'] = _code;
    map['enabled'] = _enabled;
    return map;
  }
}

/// expiryTrackingEnabled : true
/// batchTrackingEnabled : true
/// lowStockAlertEnabled : true

class Inventory {
  Inventory({
    bool? expiryTrackingEnabled,
    bool? batchTrackingEnabled,
    bool? lowStockAlertEnabled,
  }) {
    _expiryTrackingEnabled = expiryTrackingEnabled;
    _batchTrackingEnabled = batchTrackingEnabled;
    _lowStockAlertEnabled = lowStockAlertEnabled;
  }

  Inventory.fromJson(dynamic json) {
    _expiryTrackingEnabled = json['expiryTrackingEnabled'];
    _batchTrackingEnabled = json['batchTrackingEnabled'];
    _lowStockAlertEnabled = json['lowStockAlertEnabled'];
  }

  bool? _expiryTrackingEnabled;
  bool? _batchTrackingEnabled;
  bool? _lowStockAlertEnabled;

  Inventory copyWith({
    bool? expiryTrackingEnabled,
    bool? batchTrackingEnabled,
    bool? lowStockAlertEnabled,
  }) => Inventory(
    expiryTrackingEnabled: expiryTrackingEnabled ?? _expiryTrackingEnabled,
    batchTrackingEnabled: batchTrackingEnabled ?? _batchTrackingEnabled,
    lowStockAlertEnabled: lowStockAlertEnabled ?? _lowStockAlertEnabled,
  );

  bool? get expiryTrackingEnabled => _expiryTrackingEnabled;

  bool? get batchTrackingEnabled => _batchTrackingEnabled;

  bool? get lowStockAlertEnabled => _lowStockAlertEnabled;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['expiryTrackingEnabled'] = _expiryTrackingEnabled;
    map['batchTrackingEnabled'] = _batchTrackingEnabled;
    map['lowStockAlertEnabled'] = _lowStockAlertEnabled;
    return map;
  }
}

/// maxDiscountPercent : 10
/// managerApprovalAbove : 5

class Pricing {
  Pricing({num? maxDiscountPercent, num? managerApprovalAbove}) {
    _maxDiscountPercent = maxDiscountPercent;
    _managerApprovalAbove = managerApprovalAbove;
  }

  Pricing.fromJson(dynamic json) {
    _maxDiscountPercent = json['maxDiscountPercent'];
    _managerApprovalAbove = json['managerApprovalAbove'];
  }

  num? _maxDiscountPercent;
  num? _managerApprovalAbove;

  Pricing copyWith({num? maxDiscountPercent, num? managerApprovalAbove}) =>
      Pricing(
        maxDiscountPercent: maxDiscountPercent ?? _maxDiscountPercent,
        managerApprovalAbove: managerApprovalAbove ?? _managerApprovalAbove,
      );

  num? get maxDiscountPercent => _maxDiscountPercent;

  num? get managerApprovalAbove => _managerApprovalAbove;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['maxDiscountPercent'] = _maxDiscountPercent;
    map['managerApprovalAbove'] = _managerApprovalAbove;
    return map;
  }
}

/// taxMode : "GST"
/// pricesIncludeTax : true
/// defaultTaxRate : 5
/// hsnEnabled : true
/// taxSlabs : [{"hsn":"1001","rate":0},{"hsn":"2106","rate":5},{"hsn":"3304","rate":18}]

class Tax {
  Tax({
    String? taxMode,
    bool? pricesIncludeTax,
    num? defaultTaxRate,
    bool? hsnEnabled,
    List<TaxSlabs>? taxSlabs,
  }) {
    _taxMode = taxMode;
    _pricesIncludeTax = pricesIncludeTax;
    _defaultTaxRate = defaultTaxRate;
    _hsnEnabled = hsnEnabled;
    _taxSlabs = taxSlabs;
  }

  Tax.fromJson(dynamic json) {
    _taxMode = json['taxMode'];
    _pricesIncludeTax = json['pricesIncludeTax'];
    _defaultTaxRate = json['defaultTaxRate'];
    _hsnEnabled = json['hsnEnabled'];
    if (json['taxSlabs'] != null) {
      _taxSlabs = [];
      json['taxSlabs'].forEach((v) {
        _taxSlabs?.add(TaxSlabs.fromJson(v));
      });
    }
  }

  String? _taxMode;
  bool? _pricesIncludeTax;
  num? _defaultTaxRate;
  bool? _hsnEnabled;
  List<TaxSlabs>? _taxSlabs;

  Tax copyWith({
    String? taxMode,
    bool? pricesIncludeTax,
    num? defaultTaxRate,
    bool? hsnEnabled,
    List<TaxSlabs>? taxSlabs,
  }) => Tax(
    taxMode: taxMode ?? _taxMode,
    pricesIncludeTax: pricesIncludeTax ?? _pricesIncludeTax,
    defaultTaxRate: defaultTaxRate ?? _defaultTaxRate,
    hsnEnabled: hsnEnabled ?? _hsnEnabled,
    taxSlabs: taxSlabs ?? _taxSlabs,
  );

  String? get taxMode => _taxMode;

  bool? get pricesIncludeTax => _pricesIncludeTax;

  num? get defaultTaxRate => _defaultTaxRate;

  bool? get hsnEnabled => _hsnEnabled;

  List<TaxSlabs>? get taxSlabs => _taxSlabs;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['taxMode'] = _taxMode;
    map['pricesIncludeTax'] = _pricesIncludeTax;
    map['defaultTaxRate'] = _defaultTaxRate;
    map['hsnEnabled'] = _hsnEnabled;
    if (_taxSlabs != null) {
      map['taxSlabs'] = _taxSlabs?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// hsn : "1001"
/// rate : 0

class TaxSlabs {
  TaxSlabs({String? hsn, num? rate}) {
    _hsn = hsn;
    _rate = rate;
  }

  TaxSlabs.fromJson(dynamic json) {
    _hsn = json['hsn'];
    _rate = json['rate'];
  }

  String? _hsn;
  num? _rate;

  TaxSlabs copyWith({String? hsn, num? rate}) =>
      TaxSlabs(hsn: hsn ?? _hsn, rate: rate ?? _rate);

  String? get hsn => _hsn;

  num? get rate => _rate;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['hsn'] = _hsn;
    map['rate'] = _rate;
    return map;
  }
}

/// allowHoldBill : true
/// allowBillVoid : true
/// allowSameDayReturn : true
/// roundOffEnabled : true
/// negativeStockAllowed : false
/// priceEditableAtPOS : false

class Pos {
  Pos({
    bool? allowHoldBill,
    bool? allowBillVoid,
    bool? allowSameDayReturn,
    bool? roundOffEnabled,
    bool? negativeStockAllowed,
    bool? priceEditableAtPOS,
  }) {
    _allowHoldBill = allowHoldBill;
    _allowBillVoid = allowBillVoid;
    _allowSameDayReturn = allowSameDayReturn;
    _roundOffEnabled = roundOffEnabled;
    _negativeStockAllowed = negativeStockAllowed;
    _priceEditableAtPOS = priceEditableAtPOS;
  }

  Pos.fromJson(dynamic json) {
    _allowHoldBill = json['allowHoldBill'];
    _allowBillVoid = json['allowBillVoid'];
    _allowSameDayReturn = json['allowSameDayReturn'];
    _roundOffEnabled = json['roundOffEnabled'];
    _negativeStockAllowed = json['negativeStockAllowed'];
    _priceEditableAtPOS = json['priceEditableAtPOS'];
  }

  bool? _allowHoldBill;
  bool? _allowBillVoid;
  bool? _allowSameDayReturn;
  bool? _roundOffEnabled;
  bool? _negativeStockAllowed;
  bool? _priceEditableAtPOS;

  Pos copyWith({
    bool? allowHoldBill,
    bool? allowBillVoid,
    bool? allowSameDayReturn,
    bool? roundOffEnabled,
    bool? negativeStockAllowed,
    bool? priceEditableAtPOS,
  }) => Pos(
    allowHoldBill: allowHoldBill ?? _allowHoldBill,
    allowBillVoid: allowBillVoid ?? _allowBillVoid,
    allowSameDayReturn: allowSameDayReturn ?? _allowSameDayReturn,
    roundOffEnabled: roundOffEnabled ?? _roundOffEnabled,
    negativeStockAllowed: negativeStockAllowed ?? _negativeStockAllowed,
    priceEditableAtPOS: priceEditableAtPOS ?? _priceEditableAtPOS,
  );

  bool? get allowHoldBill => _allowHoldBill;

  bool? get allowBillVoid => _allowBillVoid;

  bool? get allowSameDayReturn => _allowSameDayReturn;

  bool? get roundOffEnabled => _roundOffEnabled;

  bool? get negativeStockAllowed => _negativeStockAllowed;

  bool? get priceEditableAtPOS => _priceEditableAtPOS;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['allowHoldBill'] = _allowHoldBill;
    map['allowBillVoid'] = _allowBillVoid;
    map['allowSameDayReturn'] = _allowSameDayReturn;
    map['roundOffEnabled'] = _roundOffEnabled;
    map['negativeStockAllowed'] = _negativeStockAllowed;
    map['priceEditableAtPOS'] = _priceEditableAtPOS;
    return map;
  }
}

/// gstin : "27ABCDE1234F1Z5"
/// fssai : "12345678901234"
/// currency : "INR"
/// timezone : "Asia/Kolkata"

class Business {
  Business({String? gstin, String? fssai, String? currency, String? timezone}) {
    _gstin = gstin;
    _fssai = fssai;
    _currency = currency;
    _timezone = timezone;
  }

  Business.fromJson(dynamic json) {
    _gstin = json['gstin'];
    _fssai = json['fssai'];
    _currency = json['currency'];
    _timezone = json['timezone'];
  }

  String? _gstin;
  String? _fssai;
  String? _currency;
  String? _timezone;

  Business copyWith({
    String? gstin,
    String? fssai,
    String? currency,
    String? timezone,
  }) => Business(
    gstin: gstin ?? _gstin,
    fssai: fssai ?? _fssai,
    currency: currency ?? _currency,
    timezone: timezone ?? _timezone,
  );

  String? get gstin => _gstin;

  String? get fssai => _fssai;

  String? get currency => _currency;

  String? get timezone => _timezone;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['gstin'] = _gstin;
    map['fssai'] = _fssai;
    map['currency'] = _currency;
    map['timezone'] = _timezone;
    return map;
  }
}

/// phone : "+91-9876543210"
/// email : "store@supermart.com"

class Contact {
  Contact({String? phone, String? email}) {
    _phone = phone;
    _email = email;
  }

  Contact.fromJson(dynamic json) {
    _phone = json['phone'];
    _email = json['email'];
  }

  String? _phone;
  String? _email;

  Contact copyWith({String? phone, String? email}) =>
      Contact(phone: phone ?? _phone, email: email ?? _email);

  String? get phone => _phone;

  String? get email => _email;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['phone'] = _phone;
    map['email'] = _email;
    return map;
  }
}

/// line1 : "Shop No 12, Market Road"
/// line2 : "Near Bus Stand"
/// city : "Pune"
/// state : "MH"
/// country : "IN"
/// pincode : "411001"

class Address {
  Address({
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? country,
    String? pincode,
  }) {
    _line1 = line1;
    _line2 = line2;
    _city = city;
    _state = state;
    _country = country;
    _pincode = pincode;
  }

  Address.fromJson(dynamic json) {
    _line1 = json['line1'];
    _line2 = json['line2'];
    _city = json['city'];
    _state = json['state'];
    _country = json['country'];
    _pincode = json['pincode'];
  }

  String? _line1;
  String? _line2;
  String? _city;
  String? _state;
  String? _country;
  String? _pincode;

  Address copyWith({
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? country,
    String? pincode,
  }) => Address(
    line1: line1 ?? _line1,
    line2: line2 ?? _line2,
    city: city ?? _city,
    state: state ?? _state,
    country: country ?? _country,
    pincode: pincode ?? _pincode,
  );

  String? get line1 => _line1;

  String? get line2 => _line2;

  String? get city => _city;

  String? get state => _state;

  String? get country => _country;

  String? get pincode => _pincode;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['line1'] = _line1;
    map['line2'] = _line2;
    map['city'] = _city;
    map['state'] = _state;
    map['country'] = _country;
    map['pincode'] = _pincode;
    return map;
  }
}
