import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../model/model_branch.dart';
import '../../../../model/model_brand.dart';
import '../../../../repository/repo_branch.dart';
import '../../../../repository/repo_brand.dart';
import '../../../../service/service_brand_context.dart';
import '../../../../util/snackbar_util.dart';
import '../../../branch/activity_branch_form.dart';
import '../../../branch/dialog_branch_details.dart';

class ControllerHomeBranch extends GetxController {
  final RepoBranch _repoBranch = Get.find<RepoBranch>();
  final RepoBrand _repoBrand = Get.find<RepoBrand>();
  final ServiceBrandContext _brandContext = Get.find<ServiceBrandContext>();

  final rxBranchList = <ModelBranch>[].obs;
  final rxBrandList = <ModelBrand>[].obs;
  final rxIsLoading = false.obs;
  final rxHasError = false.obs;
  final rxErrorMessage = ''.obs;
  final rxSearchQuery = ''.obs;
  final rxBrandFilter = 'ALL'.obs; // 'ALL' or brand ID
  final rxStatusFilter = 'ALL'.obs;
  final rxIsGridView = true.obs;

  final searchController = TextEditingController();
  static const List<String> statusFilterOptions = ['ALL', 'ACTIVE', 'INACTIVE'];

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      rxSearchQuery.value = searchController.text.trim().toLowerCase();
    });
    _loadBrands();
    loadBranches();
  }

  // ── Data Loading ──────────────────────────────────────────────────────────

  Future<void> _loadBrands() async {
    final (brands, _, errMsg) = await _repoBrand.fetchBrands();
    rxBrandList.assignAll(brands);
  }

  Future<void> loadBranches({bool forceRefresh = false}) async {
    rxIsLoading.value = true;
    rxHasError.value = false;
    try {
      final filterBrandId = rxBrandFilter.value;
      final shouldFilterByBrand = filterBrandId != 'ALL' &&
          filterBrandId.isNotEmpty &&
          !filterBrandId.startsWith('local_') &&
          RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(filterBrandId);

      final (branches, isFromApi, errorMsg) = shouldFilterByBrand
          ? await _repoBranch.fetchBranchesByBrand(filterBrandId)
          : await _repoBranch.fetchBranches(forceRefresh: forceRefresh);

      rxBranchList.assignAll(branches);

      if (!isFromApi && errorMsg != null) {
        SnackbarUtil.showWarning('Could not sync: $errorMsg (showing local data)');
      }
    } catch (e) {
      rxHasError.value = true;
      rxErrorMessage.value = 'Failed to load branches: $e';
    } finally {
      rxIsLoading.value = false;
    }
  }

  // ── Filtered List ─────────────────────────────────────────────────────────

  List<ModelBranch> get filteredBranches {
    return rxBranchList.where((b) {
      // Search
      if (rxSearchQuery.value.isNotEmpty) {
        final q = rxSearchQuery.value;
        final nameMatch = b.name.en.toLowerCase().contains(q);
        final codeMatch = b.branchCode.toLowerCase().contains(q);
        final cityMatch = b.address.city.toLowerCase().contains(q);
        final emailMatch = b.contact.email.toLowerCase().contains(q);
        final phoneMatch = b.contact.phones.primary.toLowerCase().contains(q);
        final brandMatch = b.displayBrandName.toLowerCase().contains(q);
        if (!nameMatch && !codeMatch && !cityMatch && !emailMatch && !phoneMatch && !brandMatch) {
          return false;
        }
      }

      // Status filter
      if (rxStatusFilter.value != 'ALL') {
        if (b.status.toUpperCase() != rxStatusFilter.value) return false;
      }

      return true;
    }).toList();
  }

  // ── Metrics ───────────────────────────────────────────────────────────────

  int get totalBranchCount => rxBranchList.length;
  int get activeBranchCount => rxBranchList.where((b) => b.isActive).length;
  int get uniqueBrandCount => rxBranchList.map((b) => b.brandId).toSet().length;

  // ── Brand Filter Helpers ──────────────────────────────────────────────────

  String getBrandName(String brandId) {
    return rxBrandList.firstWhereOrNull((b) => b.id == brandId)?.name.en ?? brandId;
  }

  List<DropdownMenuItem<String>> get brandFilterItems {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'ALL', child: Text('All Brands')),
    ];
    for (final brand in rxBrandList) {
      items.add(DropdownMenuItem(
        value: brand.id ?? '',
        child: Text(brand.name.en, style: const TextStyle(fontWeight: FontWeight.w600)),
      ));
    }
    return items;
  }

  void onBrandFilterChanged(String? brandId) {
    rxBrandFilter.value = brandId ?? 'ALL';
    loadBranches();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> openCreateDialog() async {
    final result = await Get.dialog<ModelBranch>(
      const ActivityBranchForm(),
      barrierDismissible: false,
    );
    if (result != null) {
      // Instantly insert into local observable list for instant UI feedback
      rxBranchList.removeWhere((b) => b.id == result.id);
      rxBranchList.insert(0, result);
      await loadBranches(forceRefresh: true);
    }
  }

  Future<void> openEditDialog(ModelBranch branch) async {
    final result = await Get.dialog<ModelBranch>(
      ActivityBranchForm(editingBranch: branch),
      barrierDismissible: false,
    );
    if (result != null) {
      final idx = rxBranchList.indexWhere((b) => b.id == result.id);
      if (idx != -1) {
        rxBranchList[idx] = result;
      }
      await loadBranches(forceRefresh: true);
    }
  }

  Future<void> openDetailsDialog(ModelBranch branch) async {
    await Get.dialog(
      DialogBranchDetails(
        branch: branch,
        onBranchUpdated: () => loadBranches(),
        onBranchDeleted: () => loadBranches(),
      ),
      barrierDismissible: true,
    );
  }

  /// Selects this branch as the active POS context branch.
  void selectAsActive(ModelBranch branch) {
    final brand = rxBrandList.firstWhereOrNull((b) => b.id == branch.brandId);
    _brandContext.selectBranch(branch, brand: brand);
    SnackbarUtil.showSuccess(
      'Active branch set to: ${branch.name.en} [${branch.branchCode}]',
    );
  }

  Future<void> toggleStatus(ModelBranch branch) async {
    if (branch.id == null) return;
    final newStatus = branch.isActive ? 'INACTIVE' : 'ACTIVE';
    final updated = branch.copyWith(status: newStatus);
    final (_, success, msg) = await _repoBranch.updateBranch(branch.id!, updated);
    if (success) {
      SnackbarUtil.showSuccess('Branch status changed to $newStatus');
    } else {
      SnackbarUtil.showWarning(msg);
    }
    await loadBranches();
  }

  Future<void> deleteBranch(ModelBranch branch) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Branch?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${branch.name.en}" [${branch.branchCode}]? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final branchId = branch.id;
      final (success, message) = await _repoBranch.deleteBranch(
        branchId ?? '',
        branchName: branch.name.en,
        branchCode: branch.branchCode,
      );

      // Instantly remove from local observable list for immediate UI response
      rxBranchList.removeWhere((b) =>
          (branchId != null && branchId.isNotEmpty && b.id == branchId) ||
          (b.branchCode.isNotEmpty && b.branchCode == branch.branchCode) ||
          (b.name.en.isNotEmpty && b.name.en == branch.name.en));

      if (success) {
        SnackbarUtil.showSuccess('Branch deleted successfully');
      } else {
        SnackbarUtil.showWarning(message);
      }
      await loadBranches();
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
