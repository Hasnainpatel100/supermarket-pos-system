import 'package:get/get.dart';

import '../../../model/entity_bill_item.dart';
import '../../../util/snackbar_util.dart';
import '../../../screens/home/fragment/pos/controller_home_pos.dart';
import '../models/steel_spec.dart';
import '../utils/steel_weight_calculator.dart';

class ControllerSteelPos extends GetxController {
  // Category Filter
  final Rxn<SteelCategory> rxSelectedCategory = Rxn<SteelCategory>();
  final RxString rxSearchQuery = ''.obs;

  // Logistics & Weighbridge Data
  final RxString rxVehicleNo = ''.obs;
  final RxString rxDeliverySite = ''.obs;
  final RxString rxDriverPhone = ''.obs;
  final RxString rxEwayBillNo = ''.obs;

  final RxDouble rxWeighbridgeGrossKg = 0.0.obs;
  final RxDouble rxWeighbridgeTareKg = 0.0.obs;
  final RxDouble rxCraneCharges = 0.0.obs;
  final RxDouble rxFreightCharges = 0.0.obs;

  // Weighbridge net weight = Gross - Tare
  double get netWeighbridgeWeightKg {
    final net = rxWeighbridgeGrossKg.value - rxWeighbridgeTareKg.value;
    return net > 0 ? net : 0.0;
  }

  /// Calculates total theoretical weight in kilograms of all items in current POS cart.
  double getCartTotalWeightKg() {
    if (!Get.isRegistered<ControllerHomePos>()) return 0.0;
    final posCtrl = Get.find<ControllerHomePos>();
    final cartItems = posCtrl.activeSession.rxCartItems;

    double totalKg = 0.0;
    for (final it in cartItems) {
      final unit = (it.unit ?? '').toLowerCase().trim();
      final qty = (it.qty ?? 0).toDouble();

      if (unit == 'kg' || unit == 'kilogram' || unit == 'kgs') {
        totalKg += qty;
      } else if (unit == 'mt' || unit == 'ton' || unit == 'tons' || unit == 'tonne') {
        totalKg += qty * 1000.0;
      } else if (unit == 'quintal') {
        totalKg += qty * 100.0;
      } else {
        // If unit is pcs / bars, estimate using standard catalog if name matches
        final spec = _findMatchingSpec(it.itemName ?? '');
        if (spec != null) {
          totalKg += spec.calculateWeightKg(pieces: it.qty ?? 1);
        } else {
          // Default heuristic: assume 1 kg if not specified
          totalKg += qty;
        }
      }
    }
    return totalKg;
  }

  SteelSectionSpec? _findMatchingSpec(String itemName) {
    final lower = itemName.toLowerCase();
    for (final spec in SteelCatalogData.standardCatalog) {
      if (lower.contains(spec.size.toLowerCase())) {
        return spec;
      }
    }
    return null;
  }

  /// Calculates discrepancy between Weighbridge Net and Theoretical Cart Weight
  double get weightDiscrepancyKg {
    final net = netWeighbridgeWeightKg;
    if (net <= 0) return 0.0;
    return net - getCartTotalWeightKg();
  }

  /// Add custom calculated steel section to active POS cart
  void addCalculatedSteelToCart({
    required SteelSectionSpec spec,
    required int pieces,
    required double lengthMtrs,
    required double totalWeightKg,
    required double ratePerKg,
    required String brandName,
  }) {
    if (!Get.isRegistered<ControllerHomePos>()) return;
    final posCtrl = Get.find<ControllerHomePos>();

    final totalAmount = totalWeightKg * ratePerKg;
    final displayName = '$brandName ${spec.name} ($pieces Pcs @ ${lengthMtrs}m)';

    final billItem = EntityBillItem(
      itemName: displayName,
      itemBarcode: 'STEEL-${spec.id.toUpperCase()}',
      hsnCode: spec.hsnCode,
      unit: 'Kg',
      price: ratePerKg,
      mrp: ratePerKg,
      qty: totalWeightKg.round(),
      taxRate: 18.0, // Standard 18% GST for steel
      tax: 0.0,
      discount: 0.0,
      total: totalAmount,
    );

    posCtrl.activeSession.rxCartItems.add(billItem);
    posCtrl.calculateTotals();

    SnackbarUtil.showSuccess(
      'Added $pieces pcs (${SteelWeightCalculator.formatWeight(totalWeightKg)}) to cart!',
    );
  }

  /// Clear logistics for new truck order
  void clearLogistics() {
    rxVehicleNo.value = '';
    rxDeliverySite.value = '';
    rxDriverPhone.value = '';
    rxEwayBillNo.value = '';
    rxWeighbridgeGrossKg.value = 0.0;
    rxWeighbridgeTareKg.value = 0.0;
    rxCraneCharges.value = 0.0;
    rxFreightCharges.value = 0.0;
  }
}
