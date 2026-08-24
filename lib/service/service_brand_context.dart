import 'package:get/get.dart';

import '../model/model_brand.dart';
import '../model/model_branch.dart';

/// Permanent GetX service storing the currently selected Brand and Branch
/// for the entire POS application.
///
/// Other modules (Items, Inventory, Bills, Reports, etc.) can access the
/// current Brand/Branch context via:
///   `Get.find<ServiceBrandContext>().selectedBrandId`
///   `Get.find<ServiceBrandContext>().selectedBranchId`
class ServiceBrandContext extends GetxService {
  final rxSelectedBrand = Rx<ModelBrand?>(null);
  final rxSelectedBranch = Rx<ModelBranch?>(null);

  // ── Convenience getters ───────────────────────────────────────────────────

  ModelBrand? get selectedBrand => rxSelectedBrand.value;
  ModelBranch? get selectedBranch => rxSelectedBranch.value;

  String? get selectedBrandId => rxSelectedBrand.value?.id;
  String? get selectedBranchId => rxSelectedBranch.value?.id;

  String get selectedBrandName => rxSelectedBrand.value?.name.en ?? '';
  String get selectedBranchName => rxSelectedBranch.value?.name.en ?? '';
  String get selectedBranchCode => rxSelectedBranch.value?.branchCode ?? '';

  bool get hasBrand => rxSelectedBrand.value != null;
  bool get hasBranch => rxSelectedBranch.value != null;
  bool get isFullyConfigured => hasBrand && hasBranch;

  // ── Setters ───────────────────────────────────────────────────────────────

  /// Sets the active brand. Clears the selected branch since it may
  /// not belong to the new brand.
  void selectBrand(ModelBrand brand) {
    rxSelectedBrand.value = brand;
    rxSelectedBranch.value = null; // reset branch when brand changes
  }

  /// Sets the active branch and also updates the brand reference if provided.
  void selectBranch(ModelBranch branch, {ModelBrand? brand}) {
    rxSelectedBranch.value = branch;
    if (brand != null) {
      rxSelectedBrand.value = brand;
    }
  }

  /// Clears both selected brand and branch (e.g. on logout).
  void clear() {
    rxSelectedBrand.value = null;
    rxSelectedBranch.value = null;
  }

  /// Returns a summary string for display in header bars etc.
  String get contextSummary {
    if (!hasBrand && !hasBranch) return 'No Brand/Branch selected';
    if (hasBrand && !hasBranch) return selectedBrandName;
    return '$selectedBrandName › $selectedBranchName';
  }
}
