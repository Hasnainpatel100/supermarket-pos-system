import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../model/model_api_user.dart';
import '../../../../repository/repo_api_user.dart';
import '../../../../service/service_brand_context.dart';
import '../../../../util/snackbar_util.dart';
import '../../../api_user/activity_api_user_form.dart';
import '../../../api_user/dialog_api_user_config.dart';
import '../../../api_user/dialog_api_user_details.dart';

class ControllerHomeApiUsers extends GetxController {
  final RepoApiUser _repo = Get.find<RepoApiUser>();

  final rxApiUserList = <ModelApiUser>[].obs;
  final rxIsLoading = false.obs;
  final rxSearchQuery = ''.obs;
  final rxUserTypeFilter = 'ALL'.obs;
  final rxRoleFilter = 'ALL'.obs;
  final rxIsGridView = false.obs;

  final searchController = TextEditingController();

  static const List<String> userTypeFilterOptions = ['ALL', 'PLATFORM', 'BRAND', 'BRANCH'];
  static const List<String> roleFilterOptions = [
    'ALL',
    'SUPPORT_TEAM',
    'ADMIN',
    'MANAGER',
    'CASHIER',
    'STAFF',
    'SUPER_ADMIN',
  ];

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      rxSearchQuery.value = searchController.text.trim().toLowerCase();
    });
    loadUsers();
  }

  Future<void> loadUsers({bool forceRefresh = false}) async {
    rxIsLoading.value = true;
    try {
      final brandContext = Get.isRegistered<ServiceBrandContext>() ? Get.find<ServiceBrandContext>() : null;
      final brandId = brandContext?.selectedBrandId;

      final (users, isFromApi, errorMsg) = await _repo.fetchUsers(
        brandId: brandId,
        forceRefresh: forceRefresh,
      );
      rxApiUserList.assignAll(users);

      if (forceRefresh && errorMsg != null) {
        SnackbarUtil.showWarning('Could not sync with server: $errorMsg (showing local data)');
      }
    } catch (e) {
      debugPrint('Error loading API Users: $e');
    } finally {
      rxIsLoading.value = false;
    }
  }

  List<ModelApiUser> get filteredUsers {
    return rxApiUserList.where((u) {
      // 1. Search Query
      if (rxSearchQuery.value.isNotEmpty) {
        final q = rxSearchQuery.value;
        final nameMatch = u.fullName.toLowerCase().contains(q);
        final usernameMatch = u.username.toLowerCase().contains(q);
        final emailMatch = u.email.toLowerCase().contains(q);
        final phoneMatch = u.phoneNumber.toLowerCase().contains(q);
        final roleMatch = u.role.toLowerCase().contains(q);
        final typeMatch = u.userType.toLowerCase().contains(q);
        if (!nameMatch && !usernameMatch && !emailMatch && !phoneMatch && !roleMatch && !typeMatch) {
          return false;
        }
      }

      // 2. User Type Filter
      if (rxUserTypeFilter.value != 'ALL') {
        if (u.userType.toUpperCase() != rxUserTypeFilter.value) {
          return false;
        }
      }

      // 3. Role Filter
      if (rxRoleFilter.value != 'ALL') {
        if (u.role.toUpperCase() != rxRoleFilter.value) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Metrics
  int get totalUsersCount => rxApiUserList.length;
  int get activeUsersCount => rxApiUserList.where((u) => u.isActive).length;
  int get platformUsersCount => rxApiUserList.where((u) => u.isPlatform).length;
  int get supportTeamUsersCount =>
      rxApiUserList.where((u) => u.role.toUpperCase() == 'SUPPORT_TEAM').length;

  Future<void> openCreateDialog() async {
    final result = await Get.dialog(
      const ActivityApiUserForm(),
      barrierDismissible: false,
    );
    if (result != null) {
      loadUsers();
    }
  }

  Future<void> openEditDialog(ModelApiUser user) async {
    final result = await Get.dialog(
      const ActivityApiUserForm(),
      arguments: user,
      barrierDismissible: false,
    );
    if (result != null) {
      loadUsers();
    }
  }

  void showUserDetails(ModelApiUser user) {
    Get.dialog(DialogApiUserDetails(user: user));
  }

  Future<void> openConfigDialog() async {
    final result = await Get.dialog(const DialogApiUserConfig());
    if (result == true) {
      loadUsers(forceRefresh: true);
    }
  }

  Future<void> toggleActive(ModelApiUser user) async {
    final updated = user.copyWith(isActive: !user.isActive);
    await _repo.updateUser(user.id ?? '', updated);
    loadUsers();
    SnackbarUtil.showSuccess('User status updated');
  }

  Future<void> deleteUser(ModelApiUser user) async {
    Get.defaultDialog(
      title: 'Delete API User',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText: 'Are you sure you want to delete API User "${user.username}"?',
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
        onPressed: () async {
          Get.back();
          if (user.id != null) {
            await _repo.deleteUser(user.id!);
          } else {
            rxApiUserList.removeWhere((u) => u.username == user.username);
          }
          loadUsers();
          SnackbarUtil.showSuccess('API User deleted');
        },
        child: const Text('Delete'),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
      ),
    );
  }
}
