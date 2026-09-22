import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../model/model_brand.dart';
import '../../../../repository/repo_brand.dart';
import '../../../../util/snackbar_util.dart';
import '../../../brand/activity_brand_form.dart';
import '../../../brand/dialog_brand_api_config.dart';
import '../../../brand/dialog_brand_details.dart';

class ControllerHomeBrand extends GetxController {
  final RepoBrand _repo = Get.find<RepoBrand>();

  final rxBrandList = <ModelBrand>[].obs;
  final rxIsLoading = false.obs;
  final rxIsSyncing = false.obs;
  final rxSearchQuery = ''.obs;
  final rxAppTypeFilter = 'ALL'.obs;
  final rxStatusFilter = 'ALL'.obs;
  final rxIsGridView = true.obs;

  final searchController = TextEditingController();

  static const List<String> appTypeFilterOptions = ['ALL', 'MARKET'];
  static const List<String> statusFilterOptions = ['ALL', 'ACTIVE', 'INACTIVE'];

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      rxSearchQuery.value = searchController.text.trim().toLowerCase();
    });
    loadBrands();
  }

  Future<void> loadBrands({bool forceRefresh = false}) async {
    rxIsLoading.value = true;
    try {
      // On force refresh: clear local cache first so server deletions are reflected
      if (forceRefresh) {
        await _repo.clearLocalCache();
      }
      final (brands, isFromApi, errorMsg) = await _repo.fetchBrands(
        forceRefresh: forceRefresh,
      );
      rxBrandList.assignAll(brands);

      if (forceRefresh && errorMsg != null) {
        SnackbarUtil.showWarning('Could not sync with server: $errorMsg (showing local data)');
      }
    } catch (e) {
      debugPrint('Error loading brands: $e');
    } finally {
      rxIsLoading.value = false;
    }
  }

  // ─── Filtered List ───
  List<ModelBrand> get filteredBrands {
    return rxBrandList.where((b) {
      // 1. Search Query
      if (rxSearchQuery.value.isNotEmpty) {
        final q = rxSearchQuery.value;
        final nameMatch = b.name.en.toLowerCase().contains(q);
        final gstMatch = b.registration.gstNo.toLowerCase().contains(q);
        final emailMatch = b.contact.email.toLowerCase().contains(q);
        final phoneMatch = b.contact.phones.primary.toLowerCase().contains(q);
        final cinMatch = b.registration.cin.toLowerCase().contains(q);
        if (!nameMatch && !gstMatch && !emailMatch && !phoneMatch && !cinMatch) {
          return false;
        }
      }

      // 2. App Type Filter
      if (rxAppTypeFilter.value != 'ALL') {
        if (b.appType.toUpperCase() != rxAppTypeFilter.value) {
          return false;
        }
      }

      // 3. Status Filter
      if (rxStatusFilter.value != 'ALL') {
        if (b.status.toUpperCase() != rxStatusFilter.value) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ─── Metrics ───
  int get totalBrandsCount => rxBrandList.length;
  int get activeBrandsCount => rxBrandList.where((b) => b.isActive).length;
  int get marketBrandsCount => rxBrandList.where((b) => b.isMarket).length;
  int get restaurantBrandsCount => rxBrandList.where((b) => b.isRestaurant).length;

  // ─── Actions ───

  Future<void> openCreateDialog() async {
    final result = await Get.dialog(
      const ActivityBrandForm(),
      barrierDismissible: false,
    );
    if (result != null) {
      await loadBrands();
    }
  }

  Future<void> openEditDialog(ModelBrand brand) async {
    final result = await Get.dialog(
      ActivityBrandForm(editingBrand: brand),
      barrierDismissible: false,
    );
    if (result != null) {
      await loadBrands();
    }
  }

  Future<void> openDetailsDialog(ModelBrand brand) async {
    await Get.dialog(
      DialogBrandDetails(
        brand: brand,
        onBrandUpdated: () => loadBrands(),
        onBrandDeleted: () => loadBrands(),
      ),
      barrierDismissible: true,
    );
  }

  Future<void> openApiConfigDialog() async {
    final updated = await Get.dialog(
      const DialogBrandApiConfig(),
      barrierDismissible: true,
    );
    if (updated == true) {
      await loadBrands(forceRefresh: true);
    }
  }

  Future<void> toggleStatus(ModelBrand brand) async {
    if (brand.id == null) return;
    final newStatus = brand.isActive ? 'INACTIVE' : 'ACTIVE';
    final updatedBrand = brand.copyWith(status: newStatus);

    final (resBrand, success, msg) = await _repo.updateBrand(brand.id!, updatedBrand);
    if (success) {
      SnackbarUtil.showSuccess('Brand status changed to $newStatus');
    } else {
      SnackbarUtil.showWarning(msg);
    }
    await loadBrands();
  }

  Future<void> deleteBrand(ModelBrand brand) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Delete Brand?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${brand.name.en}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && brand.id != null) {
      final (success, message) = await _repo.deleteBrand(
        brand.id!,
        brandName: brand.name.en,
      );
      if (success) {
        SnackbarUtil.showSuccess('Brand deleted successfully');
      } else {
        SnackbarUtil.showWarning(message);
      }
      await loadBrands();
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
