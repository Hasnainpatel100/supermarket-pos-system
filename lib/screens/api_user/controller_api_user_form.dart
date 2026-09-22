import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/model_api_user.dart';
import '../../model/model_brand.dart';
import '../../model/model_branch.dart';
import '../../repository/repo_api_user.dart';
import '../../service/service_brand_api.dart';
import '../../service/service_branch_api.dart';
import '../../service/service_brand_context.dart';
import '../../service/service_storage.dart';
import '../../util/snackbar_util.dart';

class ControllerApiUserForm extends GetxController {
  final RepoApiUser _repo = Get.find<RepoApiUser>();
  final ServiceBrandApi _brandApi = Get.find<ServiceBrandApi>();
  final ServiceBranchApi _branchApi = Get.find<ServiceBranchApi>();

  ModelApiUser? editingUser;

  final formKey = GlobalKey<FormState>();

  final textControllerBrandId = TextEditingController();
  final textControllerBranchId = TextEditingController();
  final textControllerFirstName = TextEditingController();
  final textControllerLastName = TextEditingController();
  final textControllerUsername = TextEditingController();
  final textControllerLoginPin = TextEditingController(text: '888888');
  final textControllerEmail = TextEditingController();
  final textControllerPhone = TextEditingController();
  final textControllerCustomPermission = TextEditingController();

  final rxUserType = 'PLATFORM'.obs;
  final rxRole = 'SUPPORT_TEAM'.obs;
  final rxIsActive = true.obs;
  final rxIsPasswordHidden = true.obs;
  final rxIsSubmitting = false.obs;

  // ── Brand & Branch Server Selection (appType = MARKET) ──
  final rxIsLoadingBrands = false.obs;
  final rxIsLoadingBranches = false.obs;
  final rxBrandList = <ModelBrand>[].obs;
  final rxBranchList = <ModelBranch>[].obs;
  final rxSelectedBrand = Rx<ModelBrand?>(null);
  final rxSelectedBranch = Rx<ModelBranch?>(null);

  final rxPermissions = <String>[
    'USER_READ',
    'USER_UPDATE',
    'ORDER_READ',
    'ORDER_UPDATE',
    'REPORT_VIEW',
    'REPORT_EXPORT',
    'DEVICE_MANAGE',
    'BRANCH_READ',
    'RESTAURANT_READ',
    'PLAN_READ',
    'SUBSCRIPTION_READ',
  ].obs;

  static const List<String> availableUserTypes = [
    'PLATFORM',
    'BRAND',
    'BRANCH',
  ];
  static const List<String> availableRoles = [
    'SUPPORT_TEAM',
    'ADMIN',
    'MANAGER',
    'CASHIER',
    'STAFF',
    'SUPER_ADMIN',
  ];

  static const List<String> defaultPresetPermissions = [
    'USER_READ',
    'USER_UPDATE',
    'USER_CREATE',
    'USER_DELETE',
    'ORDER_READ',
    'ORDER_UPDATE',
    'ORDER_CREATE',
    'REPORT_VIEW',
    'REPORT_EXPORT',
    'DEVICE_MANAGE',
    'BRANCH_READ',
    'RESTAURANT_READ',
    'PLAN_READ',
    'SUBSCRIPTION_READ',
  ];

  @override
  void onInit() {
    super.onInit();

    final storage = Get.find<ServiceStorage>();
    final storedBrandId = storage.readString('auth_brand_id') ?? '';
    final storedBranchId = storage.readString('auth_branch_id') ?? '';

    String contextBrandId = '';
    String contextBranchId = '';
    if (Get.isRegistered<ServiceBrandContext>()) {
      final ctx = Get.find<ServiceBrandContext>();
      contextBrandId = ctx.selectedBrandId ?? '';
      contextBranchId = ctx.selectedBranchId ?? '';
    }

    textControllerBrandId.text = contextBrandId.isNotEmpty
        ? contextBrandId
        : storedBrandId;
    textControllerBranchId.text = contextBranchId.isNotEmpty
        ? contextBranchId
        : storedBranchId;

    final args = Get.arguments;
    if (args is ModelApiUser) {
      editingUser = args;
      _populateData(args);
    }

    // Load server brands with appType=MARKET
    loadBrands();
  }

  /// GET /api/brands?appType=MARKET&page=1&limit=20
  Future<void> loadBrands() async {
    rxIsLoadingBrands.value = true;
    try {
      final response = await _brandApi.getBrands(appType: 'MARKET', page: 1, limit: 20);
      if (response.success && response.data != null) {
        // Only keep brands with appType=MARKET and real server IDs
        final marketBrands = response.data!.where((b) {
          final isMarket = b.appType.toUpperCase() == 'MARKET';
          final hasValidId = b.id != null &&
              b.id!.isNotEmpty &&
              !b.id!.startsWith('local_') &&
              b.id != '000000000000000000000000';
          return isMarket && hasValidId;
        }).toList();

        rxBrandList.assignAll(marketBrands);

        // Pre-select brand
        final brandIdToSelect = editingUser?.brandId.isNotEmpty == true
            ? editingUser!.brandId
            : textControllerBrandId.text.trim();

        if (brandIdToSelect.isNotEmpty &&
            brandIdToSelect != '000000000000000000000000' &&
            !brandIdToSelect.startsWith('local_')) {
          final matched = marketBrands.firstWhereOrNull((b) => b.id == brandIdToSelect);
          if (matched != null) {
            onBrandSelected(matched, initialBranchId: editingUser?.branchId ?? textControllerBranchId.text.trim());
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading MARKET brands for API user form: $e');
    } finally {
      rxIsLoadingBrands.value = false;
    }
  }

  void onBrandSelected(ModelBrand? brand, {String? initialBranchId}) {
    rxSelectedBrand.value = brand;
    textControllerBrandId.text = brand?.id ?? '';
    rxSelectedBranch.value = null;
    rxBranchList.clear();

    if (brand != null && brand.id != null && brand.id!.isNotEmpty) {
      loadBranchesForBrand(brand.id!, initialBranchId: initialBranchId);
    }
  }

  /// GET /api/branches/brand/:brandId?page=1&limit=20 for branches with appType=MARKET
  Future<void> loadBranchesForBrand(String brandId, {String? initialBranchId}) async {
    rxIsLoadingBranches.value = true;
    try {
      final response = await _branchApi.getBranchesByBrand(brandId, page: 1, limit: 100);
      if (response.success && response.data != null) {
        // Filter strictly for branches with appType=MARKET and real server IDs
        final marketBranches = response.data!.where((b) {
          final isMarket = b.appType.toUpperCase() == 'MARKET';
          final hasValidId = b.id != null &&
              b.id!.isNotEmpty &&
              !b.id!.startsWith('local_') &&
              b.id != '000000000000000000000000';
          return isMarket && hasValidId;
        }).toList();

        rxBranchList.assignAll(marketBranches);

        final branchIdToSelect = initialBranchId ?? editingUser?.branchId ?? textControllerBranchId.text.trim();
        if (branchIdToSelect.isNotEmpty &&
            branchIdToSelect != '000000000000000000000000' &&
            !branchIdToSelect.startsWith('local_')) {
          final matched = marketBranches.firstWhereOrNull((b) => b.id == branchIdToSelect);
          if (matched != null) {
            onBranchSelected(matched);
          }
        } else if (marketBranches.length == 1) {
          onBranchSelected(marketBranches.first);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading branches for brand $brandId: $e');
    } finally {
      rxIsLoadingBranches.value = false;
    }
  }

  void onBranchSelected(ModelBranch? branch) {
    rxSelectedBranch.value = branch;
    textControllerBranchId.text = branch?.id ?? '';
  }

  void _populateData(ModelApiUser user) {
    textControllerBrandId.text = user.brandId;
    textControllerBranchId.text = user.branchId;
    textControllerFirstName.text = user.firstName;
    textControllerLastName.text = user.lastName;
    textControllerUsername.text = user.username;
    textControllerLoginPin.text = user.loginPin ?? '888888';
    textControllerEmail.text = user.email;
    textControllerPhone.text = user.phoneNumber;

    rxUserType.value = user.userType;
    rxRole.value = user.role;
    rxIsActive.value = user.isActive;
    rxPermissions.assignAll(user.permissions);
  }

  void togglePermission(String permission) {
    if (rxPermissions.contains(permission)) {
      rxPermissions.remove(permission);
    } else {
      rxPermissions.add(permission);
    }
  }

  void addCustomPermission() {
    final custom = textControllerCustomPermission.text.trim().toUpperCase();
    if (custom.isNotEmpty && !rxPermissions.contains(custom)) {
      rxPermissions.add(custom);
      textControllerCustomPermission.clear();
    }
  }

  void selectAllPermissions() {
    for (var p in defaultPresetPermissions) {
      if (!rxPermissions.contains(p)) {
        rxPermissions.add(p);
      }
    }
  }

  void clearAllPermissions() {
    rxPermissions.clear();
  }

  Future<void> saveUser() async {
    if (!formKey.currentState!.validate()) return;

    final selectedBrandId = rxSelectedBrand.value?.id ?? textControllerBrandId.text.trim();
    final selectedBranchId = rxSelectedBranch.value?.id ?? textControllerBranchId.text.trim();
    final userType = rxUserType.value.toUpperCase();

    // Enforce selection for BRAND and BRANCH user types
    if (userType == 'BRAND' || userType == 'BRANCH') {
      if (selectedBrandId.isEmpty ||
          selectedBrandId == '000000000000000000000000' ||
          selectedBrandId.startsWith('local_')) {
        SnackbarUtil.showWarning('Please select a Brand (appType: MARKET) from the dropdown.');
        return;
      }
    }
    if (userType == 'BRANCH') {
      if (selectedBranchId.isEmpty ||
          selectedBranchId == '000000000000000000000000' ||
          selectedBranchId.startsWith('local_')) {
        SnackbarUtil.showWarning('Please select a Branch (appType: MARKET) from the dropdown.');
        return;
      }
    }

    rxIsSubmitting.value = true;
    try {
      final validBrandId = (selectedBrandId.isNotEmpty &&
              selectedBrandId != '000000000000000000000000' &&
              !selectedBrandId.startsWith('local_'))
          ? selectedBrandId
          : '';

      final validBranchId = (selectedBranchId.isNotEmpty &&
              selectedBranchId != '000000000000000000000000' &&
              !selectedBranchId.startsWith('local_'))
          ? selectedBranchId
          : '';

      final user = ModelApiUser(
        id: editingUser?.id,
        brandId: validBrandId,
        branchId: validBranchId,
        userType: rxUserType.value,
        role: rxRole.value,
        firstName: textControllerFirstName.text.trim(),
        lastName: textControllerLastName.text.trim(),
        username: textControllerUsername.text.trim(),
        loginPin: textControllerLoginPin.text.trim(),
        email: textControllerEmail.text.trim(),
        phoneNumber: textControllerPhone.text.trim(),
        permissions: rxPermissions.toList(),
        isActive: rxIsActive.value,
      );

      if (kDebugMode) {
        debugPrint('👤 [UserForm] Submitting payload directly to server:');
        debugPrint(user.toCreatePayloadJson().toString());
      }

      if (editingUser == null) {
        final response = await _repo.createUser(user);
        if (response.success && response.data != null) {
          SnackbarUtil.showSuccess(response.message.isNotEmpty ? response.message : 'User created on server successfully');
          Get.back(result: response.data);
        } else {
          SnackbarUtil.showError(response.message.isNotEmpty ? response.message : 'Server rejected user creation');
        }
      } else {
        final response = await _repo.updateUser(editingUser!.id ?? '', user);
        if (response.success) {
          SnackbarUtil.showSuccess(response.message.isNotEmpty ? response.message : 'User updated successfully');
          Get.back(result: response.data ?? user);
        } else {
          SnackbarUtil.showError(response.message.isNotEmpty ? response.message : 'Server update failed');
        }
      }
    } catch (e) {
      SnackbarUtil.showError('Failed to save API User: $e');
    } finally {
      rxIsSubmitting.value = false;
    }
  }
}
