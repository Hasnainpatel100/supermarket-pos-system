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

  // ── Plan & Subscription getters ──────────────────────────────────────────

  final rxExpiryAlarmDays = 15.obs;
  int get expiryAlarmDays => rxExpiryAlarmDays.value;

  BranchPlanDetails? get planDetails => rxSelectedBranch.value?.planDetails;
  bool get hasPlanDetails => planDetails != null;
  DateTime? get planExpiryDate => planDetails?.expiryDate;
  int? get planDaysRemaining => planDetails?.daysRemaining;
  /// Returns true only if the plan has passed its expiration date.
  /// (A plan remains valid throughout its expiry date until 23:59:59.999).
  bool get isPlanExpired => planDetails?.isExpired ?? false;

  /// Backwards compatibility alias: returns true if plan is expired.
  /// Users can log in throughout the entire calendar day of their expiry date.
  bool get isPlanExpiredOrToday => isPlanExpired;

  /// Whether the plan is expired or will expire within the configured alarm window
  bool get isPlanExpiringSoon {
    if (isPlanExpired) return true;
    final days = planDaysRemaining;
    if (days == null) return false;
    return days <= rxExpiryAlarmDays.value;
  }

  String get planExpiryStatusText =>
      planDetails?.expiryStatusText ?? 'Active Plan';

  void setExpiryAlarmDays(int days) {
    rxExpiryAlarmDays.value = days;
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  /// Sets the active brand. Only resets the selected branch if the branch
  /// does not belong to the new brand.
  void selectBrand(ModelBrand brand) {
    rxSelectedBrand.value = brand;
    final currentBranch = rxSelectedBranch.value;
    if (currentBranch != null &&
        brand.id != null &&
        currentBranch.brandId.isNotEmpty &&
        currentBranch.brandId != brand.id) {
      rxSelectedBranch.value = null;
    }
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

