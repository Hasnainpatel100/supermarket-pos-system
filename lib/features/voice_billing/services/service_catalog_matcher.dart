import 'package:get/get.dart';
import '../../../../model/entity_customer.dart';
import '../../../../model/entity_item.dart';
import '../../../../model/entity_item_batch.dart';
import '../../../../objectbox.g.dart';
import '../../../../service/service_object_box.dart';
import '../models/model_voice_invoice.dart';
import '../models/model_voice_item.dart';

class ServiceCatalogMatcher {
  late final Box<EntityItem> _boxItem;
  late final Box<EntityItemBatch> _boxBatch;
  late final Box<EntityCustomer> _boxCustomer;

  ServiceCatalogMatcher() {
    final ob = Get.find<ServiceObjectBox>();
    _boxItem = ob.box<EntityItem>();
    _boxBatch = ob.box<EntityItemBatch>();
    _boxCustomer = ob.box<EntityCustomer>();
  }

  // Common Hindi / Marathi / English retail synonyms mapping
  static const Map<String, List<String>> _synonyms = {
    'sugar': ['sugar', 'sakhar', 'cheeni', 'chini', 'shakar'],
    'milk': ['milk', 'doodh', 'dudh'],
    'oil': ['oil', 'tel', 'tail'],
    'rice': ['rice', 'chawal', 'tandul'],
    'wheat': ['wheat', 'atta', 'gehu', 'gahu', 'flour'],
    'tea': ['tea', 'chai', 'chaha', 'patti'],
    'coffee': ['coffee', 'kafi'],
    'soap': ['soap', 'sabun', 'saban'],
    'salt': ['salt', 'namak', 'meeth'],
    'biscuit': ['biscuit', 'biskit', 'cookies'],
    'water': ['water', 'pani'],
  };

  /// Enriches the extracted voice invoice by matching its items and customer against local database.
  Future<void> matchInvoice(ModelVoiceInvoice invoice) async {
    // 1. Match Customer if name or phone is present
    if (invoice.customerPhone != null && invoice.customerPhone!.isNotEmpty) {
      final q = _boxCustomer.query(EntityCustomer_.phone.contains(invoice.customerPhone!)).build();
      final cust = q.findFirst();
      q.close();
      if (cust != null) {
        invoice.customerName ??= cust.name;
      }
    } else if (invoice.customerName != null && invoice.customerName!.isNotEmpty) {
      final name = invoice.customerName!.trim();
      final q = _boxCustomer.query(EntityCustomer_.name.contains(name, caseSensitive: false)).build();
      final cust = q.findFirst();
      q.close();
      if (cust != null) {
        invoice.customerName = cust.name;
        invoice.customerPhone ??= cust.phone;
      }
    }

    // 2. Match each item
    for (final item in invoice.items) {
      matchItem(item);
    }

    invoice.recalculate();
  }

  /// Match a single voice item against the inventory
  void matchItem(ModelVoiceItem voiceItem) {
    final queryCandidates = <String>[];
    
    final cleanName = voiceItem.itemName.trim().toLowerCase();
    queryCandidates.add(cleanName);

    if (voiceItem.spokenName.isNotEmpty) {
      queryCandidates.add(voiceItem.spokenName.trim().toLowerCase());
    }

    // Check synonyms
    for (final entry in _synonyms.entries) {
      if (entry.value.any((syn) => cleanName.contains(syn) || (voiceItem.spokenName.isNotEmpty && voiceItem.spokenName.toLowerCase().contains(syn)))) {
        queryCandidates.add(entry.key);
        queryCandidates.addAll(entry.value);
      }
    }

    EntityItem? matched;

    // A. Check exact barcode or SKU first
    final barcodeMatch = _boxItem.query(EntityItem_.barcode.equals(cleanName).or(EntityItem_.sku.equals(cleanName))).build().findFirst();
    if (barcodeMatch != null) {
      matched = barcodeMatch;
    }

    // B. Search by name candidates
    if (matched == null) {
      for (final cand in queryCandidates.toSet()) {
        if (cand.length < 2) continue;
        final q = _boxItem.query(
          EntityItem_.name.contains(cand, caseSensitive: false)
            .and(EntityItem_.isActive.equals(true)),
        ).build();
        final found = q.find();
        q.close();

        if (found.isNotEmpty) {
          // Find best match: exact name match or first available with stock
          matched = found.firstWhereOrNull((it) => (it.name ?? '').toLowerCase() == cand) 
                 ?? found.firstWhereOrNull((it) => (it.totalQty ?? 0) > 0) 
                 ?? found.first;
          break;
        }
      }
    }

    if (matched != null) {
      voiceItem.isMatched = true;
      voiceItem.matchedItemId = matched.id;
      voiceItem.matchedBarcode = matched.barcode;
      voiceItem.matchedSku = matched.sku;
      voiceItem.hsnCode = matched.hsnCode;
      voiceItem.entityItem = matched;

      // Retain clean product name from store master
      if (matched.name != null && matched.name!.isNotEmpty) {
        voiceItem.itemName = matched.name!;
      }

      // If price was NOT explicitly mentioned in voice, use store price
      if (voiceItem.price <= 0) {
        voiceItem.price = matched.sellingPrice ?? 0.0;
        voiceItem.mrp = matched.sellingPrice ?? voiceItem.price;
      }

      // If tax rate was NOT explicitly mentioned, use store tax rate
      if (voiceItem.taxRate <= 0 && matched.taxRate != null) {
        voiceItem.taxRate = matched.taxRate!;
      }

      // Assign unit if missing
      if (matched.unit != null && matched.unit!.isNotEmpty) {
        voiceItem.unit = matched.unit!;
      }

      // Check available batch
      final batchQuery = _boxBatch.query(
        EntityItemBatch_.itemId.equals(matched.id ?? 0)
          .and(EntityItemBatch_.quantity.greaterThan(0)),
      ).build();
      final batches = batchQuery.find();
      batchQuery.close();

      if (batches.isNotEmpty) {
        voiceItem.entityBatch = batches.first;
        if (voiceItem.price <= 0 && batches.first.salePrice != null) {
          voiceItem.price = batches.first.salePrice!;
          voiceItem.mrp = batches.first.mrp ?? voiceItem.price;
        }
      }
    } else {
      voiceItem.isMatched = false;
      // Default price to standard placeholder if zero so cashier can review
      if (voiceItem.price <= 0) {
        voiceItem.price = 0.0;
      }
    }

    voiceItem.recalculate();
  }
}
