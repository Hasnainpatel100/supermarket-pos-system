import 'package:flutter/foundation.dart';

/// Models a parsed variable-weight or price-embedded supermarket barcode.
/// E.g., Barcodes starting with 20, 21, 02 typically used by supermarket weighing scales.
class ParsedWeightBarcode {
  final bool isVariableWeight;
  final String? itemPluOrCode;
  final double? weightInKg;
  final double? embeddedPrice;
  final String rawBarcode;

  const ParsedWeightBarcode({
    required this.isVariableWeight,
    this.itemPluOrCode,
    this.weightInKg,
    this.embeddedPrice,
    required this.rawBarcode,
  });

  Map<String, dynamic> toMap() => {
        'isVariableWeight': isVariableWeight,
        'itemPluOrCode': itemPluOrCode,
        'weightInKg': weightInKg,
        'embeddedPrice': embeddedPrice,
        'rawBarcode': rawBarcode,
      };

  factory ParsedWeightBarcode.fromMap(Map<String, dynamic> map) =>
      ParsedWeightBarcode(
        isVariableWeight: map['isVariableWeight'] as bool,
        itemPluOrCode: map['itemPluOrCode'] as String?,
        weightInKg: (map['weightInKg'] as num?)?.toDouble(),
        embeddedPrice: (map['embeddedPrice'] as num?)?.toDouble(),
        rawBarcode: map['rawBarcode'] as String? ?? '',
      );
}

/// Parameters for background shift financial aggregation.
class ShiftSummaryParams {
  final List<Map<String, dynamic>> rawBills;
  final double openingCash;

  const ShiftSummaryParams({
    required this.rawBills,
    required this.openingCash,
  });

  Map<String, dynamic> toMap() => {
        'rawBills': rawBills,
        'openingCash': openingCash,
      };
}

/// Result of background shift summary calculation.
class ShiftSummaryResult {
  final double totalSales;
  final double totalCash;
  final double totalUpi;
  final double totalCard;
  final double totalDue;
  final double totalDiscount;
  final double totalTax;
  final int totalBillsCount;
  final double expectedDrawerCash;

  const ShiftSummaryResult({
    required this.totalSales,
    required this.totalCash,
    required this.totalUpi,
    required this.totalCard,
    required this.totalDue,
    required this.totalDiscount,
    required this.totalTax,
    required this.totalBillsCount,
    required this.expectedDrawerCash,
  });

  factory ShiftSummaryResult.fromMap(Map<String, dynamic> map) =>
      ShiftSummaryResult(
        totalSales: (map['totalSales'] as num).toDouble(),
        totalCash: (map['totalCash'] as num).toDouble(),
        totalUpi: (map['totalUpi'] as num).toDouble(),
        totalCard: (map['totalCard'] as num).toDouble(),
        totalDue: (map['totalDue'] as num).toDouble(),
        totalDiscount: (map['totalDiscount'] as num).toDouble(),
        totalTax: (map['totalTax'] as num).toDouble(),
        totalBillsCount: map['totalBillsCount'] as int,
        expectedDrawerCash: (map['expectedDrawerCash'] as num).toDouble(),
      );
}

/// Engine providing Isolate-isolated computations for memory and UI smoothness.
/// All heavy parsing, math, and string filtering run off the Flutter UI thread.
class PosIsolateEngine {
  /// Parses standard Retail Weighing Scale Barcodes (EAN-13).
  /// Format 1 (Weight-embedded): Prefix 20 or 21 + 5-digit PLU + 5-digit Weight (in grams) + Checksum
  /// Format 2 (Price-embedded): Prefix 02 or 28 + 5-digit PLU + 5-digit Price (in cents/paise) + Checksum
  static Future<ParsedWeightBarcode> parseScaleBarcodeAsync(String barcode) async {
    final clean = barcode.trim();
    if (clean.length != 12 && clean.length != 13) {
      return ParsedWeightBarcode(isVariableWeight: false, rawBarcode: clean);
    }
    return compute(_parseScaleBarcodeWorker, clean);
  }

  /// Synchronous fallback / worker function for isolate
  static ParsedWeightBarcode _parseScaleBarcodeWorker(String raw) {
    try {
      if (raw.length == 13 || raw.length == 12) {
        final prefix = raw.substring(0, 2);
        // Prefix 20 or 21: Weight embedded (20 + 5 digit item code + 5 digit grams)
        if (prefix == '20' || prefix == '21') {
          final itemCode = raw.substring(2, 7);
          final weightGramsStr = raw.substring(7, 12);
          final grams = double.tryParse(weightGramsStr) ?? 0.0;
          final weightInKg = grams / 1000.0;
          return ParsedWeightBarcode(
            isVariableWeight: true,
            itemPluOrCode: itemCode,
            weightInKg: weightInKg,
            embeddedPrice: null,
            rawBarcode: raw,
          );
        }
        // Prefix 02 or 28: Price embedded (02 + 5 digit item code + 5 digit price cents/paise)
        if (prefix == '02' || prefix == '28') {
          final itemCode = raw.substring(2, 7);
          final priceCentsStr = raw.substring(7, 12);
          final cents = double.tryParse(priceCentsStr) ?? 0.0;
          final price = cents / 100.0;
          return ParsedWeightBarcode(
            isVariableWeight: true,
            itemPluOrCode: itemCode,
            weightInKg: null,
            embeddedPrice: price,
            rawBarcode: raw,
          );
        }
      }
    } catch (_) {}

    return ParsedWeightBarcode(isVariableWeight: false, rawBarcode: raw);
  }

  /// Calculates shift or daily financial totals in background isolate
  /// so UI never freezes even if hundreds of bills exist.
  static Future<ShiftSummaryResult> computeShiftSummaryAsync({
    required List<Map<String, dynamic>> rawBills,
    required double openingCash,
  }) async {
    final params = ShiftSummaryParams(
      rawBills: rawBills,
      openingCash: openingCash,
    );
    final map = await compute(_computeShiftSummaryWorker, params.toMap());
    return ShiftSummaryResult.fromMap(map);
  }

  static Map<String, dynamic> _computeShiftSummaryWorker(Map<String, dynamic> params) {
    final rawBills = params['rawBills'] as List;
    final openingCash = (params['openingCash'] as num).toDouble();

    double totalSales = 0.0;
    double totalCash = 0.0;
    double totalUpi = 0.0;
    double totalCard = 0.0;
    double totalDue = 0.0;
    double totalDiscount = 0.0;
    double totalTax = 0.0;
    int count = 0;

    for (final item in rawBills) {
      if (item is! Map) continue;
      final status = item['status']?.toString().toUpperCase();
      if (status == 'CANCELLED') continue;

      count++;
      final grand = (item['grandTotal'] as num?)?.toDouble() ?? 0.0;
      final mode = item['paymentMode']?.toString().toUpperCase() ?? 'CASH';
      final disc = (item['discount'] as num?)?.toDouble() ?? 0.0;
      final tax = (item['tax'] as num?)?.toDouble() ?? 0.0;
      final due = (item['dueAmount'] as num?)?.toDouble() ?? 0.0;
      final received = (item['amountReceived'] as num?)?.toDouble() ?? grand;

      totalSales += grand;
      totalDiscount += disc;
      totalTax += tax;
      totalDue += due;

      if (mode.contains('UPI')) {
        totalUpi += grand;
      } else if (mode.contains('CARD')) {
        totalCard += grand;
      } else {
        // Cash or mixed
        totalCash += received > grand ? grand : received;
      }
    }

    final expectedDrawerCash = openingCash + totalCash;

    return {
      'totalSales': totalSales,
      'totalCash': totalCash,
      'totalUpi': totalUpi,
      'totalCard': totalCard,
      'totalDue': totalDue,
      'totalDiscount': totalDiscount,
      'totalTax': totalTax,
      'totalBillsCount': count,
      'expectedDrawerCash': expectedDrawerCash,
    };
  }

  /// Fast fuzzy search and scoring in background isolate for large item datasets
  static Future<List<int>> searchItemIdsFuzzyAsync({
    required List<Map<String, dynamic>> itemsSnapshot,
    required String query,
    int limit = 30,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return compute(_searchFuzzyWorker, {
      'items': itemsSnapshot,
      'query': q,
      'limit': limit,
    });
  }

  static List<int> _searchFuzzyWorker(Map<String, dynamic> data) {
    final items = data['items'] as List;
    final query = data['query'] as String;
    final limit = data['limit'] as int;

    final matched = <Map<String, dynamic>>[];

    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final id = raw['id'] as int?;
      if (id == null) continue;

      final name = (raw['name'] ?? '').toString().toLowerCase();
      final barcode = (raw['barcode'] ?? '').toString().toLowerCase();
      final sku = (raw['sku'] ?? '').toString().toLowerCase();

      int score = 0;
      if (barcode == query || sku == query) {
        score = 1000;
      } else if (barcode.startsWith(query) || sku.startsWith(query)) {
        score = 500;
      } else if (name.startsWith(query)) {
        score = 300;
      } else if (name.contains(query)) {
        score = 100;
      }

      if (score > 0) {
        matched.add({'id': id, 'score': score});
      }
    }

    matched.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    return matched.take(limit).map((e) => e['id'] as int).toList();
  }

  /// Filters a full item catalogue in a background isolate so typing in the
  /// search box never drops below 60 FPS even with 10,000+ SKUs in stock.
  /// Returns the filtered list of item maps (already serializable).
  static Future<List<Map<String, dynamic>>> filterItemsAsync({
    required List<Map<String, dynamic>> allItems,
    required String query,
    required String selectedCategory,
  }) async {
    return compute(
      _filterItemsWorker,
      {
        'items': allItems,
        'query': query,
        'category': selectedCategory,
      },
    );
  }

  static List<Map<String, dynamic>> _filterItemsWorker(Map<String, dynamic> data) {
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    final query = (data['query'] as String).trim().toLowerCase();
    final category = (data['category'] as String).trim().toLowerCase();

    final results = <Map<String, dynamic>>[];
    final seen = <int>{};

    for (final item in items) {
      final id = item['id'] as int?;
      if (id == null || seen.contains(id)) continue;
      seen.add(id);

      final isActive = item['isActive'] as bool? ?? true;
      if (!isActive) continue;

      // Category filter (case-insensitive, 'all' matches everything)
      if (category != 'all') {
        final cat = (item['category'] ?? '').toString().toLowerCase();
        if (cat != category) continue;
      }

      if (query.isEmpty) {
        results.add(item);
        continue;
      }

      final name = (item['name'] ?? '').toString().toLowerCase();
      final barcode = (item['barcode'] ?? '').toString().toLowerCase();
      final sku = (item['sku'] ?? '').toString().toLowerCase();

      if (name.contains(query) || barcode.contains(query) || sku.contains(query)) {
        results.add(item);
      }
    }

    return results;
  }
}
