import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/model_api_user.dart';
import '../../repository/repo_api_user.dart';
import '../../util/snackbar_util.dart';

class ControllerApiUserForm extends GetxController {
  final RepoApiUser _repo = Get.find<RepoApiUser>();

  ModelApiUser? editingUser;

  final formKey = GlobalKey<FormState>();

  final textControllerBrandId = TextEditingController(
    text: '000000000000000000000000',
  );
  final textControllerBranchId = TextEditingController(
    text: '000000000000000000000000',
  );
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
    final args = Get.arguments;
    if (args is ModelApiUser) {
      editingUser = args;
      _populateData(args);
    }
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

    rxIsSubmitting.value = true;
    try {
      final user = ModelApiUser(
        id: editingUser?.id,
        brandId: textControllerBrandId.text.trim().isEmpty
            ? '000000000000000000000000'
            : textControllerBrandId.text.trim(),
        branchId: textControllerBranchId.text.trim().isEmpty
            ? '000000000000000000000000'
            : textControllerBranchId.text.trim(),
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

      if (editingUser == null) {
        final response = await _repo.createUser(user);
        if (response.success || response.data != null) {
          SnackbarUtil.showSuccess(response.message);
          Get.back(result: response.data ?? user);
        } else {
          SnackbarUtil.showError(response.message);
        }
      } else {
        final response = await _repo.updateUser(editingUser!.id ?? '', user);
        SnackbarUtil.showSuccess(response.message);
        Get.back(result: response.data ?? user);
      }
    } catch (e) {
      SnackbarUtil.showError('Failed to save API User: $e');
    } finally {
      rxIsSubmitting.value = false;
    }
  }
}
