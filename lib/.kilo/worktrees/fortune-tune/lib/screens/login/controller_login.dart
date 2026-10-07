import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../enums/enum_permission.dart';
import '../../commons/loader.dart';
import '../../model/entity_user.dart';
import '../../objectbox.g.dart';
import '../../repository/repo_storage.dart';
import '../../service/service_object_box.dart';
import '../../util/app_route.dart';
import '../../util/my_date_time.dart';
import '../../util/snackbar_util.dart';
import '../../util/util_device.dart';

class ControllerLogin extends GetxController {
  late Box<EntityUser> _boxUser;
  final RepoStorage _repoStorage = Get.find();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isPasswordHidden = true.obs;

  @override
  void onInit() {
    final ob = Get.find<ServiceObjectBox>();
    _boxUser = ob.box<EntityUser>();
    super.onInit();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void login() async {
    Loader.showLoader();

    await checkUserCount();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      Loader.hideLoader();
      SnackbarUtil.showError('field_empty'.tr);
      return;
    }
    debugPrint('email: $email, password: $password');
    final query = _boxUser
        .query(
          EntityUser_.username.equals(email) &
              EntityUser_.password.equals(password),
        )
        .build();
    final user = query.findFirst();
    if (user == null) {
      Loader.hideLoader();
      SnackbarUtil.showError('invalid_credentials'.tr);
      return;
    }
    // reassign theme, local, currency after logout

    // ✅ PATCH: Ensure superAdmin has all permissions (including new ones)
    if (user.role == 'superAdmin') {
      final allPermissions = EnumPermission.values.map((e) => e.name).toList();
      user.permissions ??= [];
      for (var p in allPermissions) {
        if (!user.permissions!.contains(p)) {
          user.permissions!.add(p);
        }
      }
      debugPrint("superAdmin permissions updated: ${user.permissions?.length}");
    }

    // update login details in Entity User
    user.lastLoginAt = MyDateTime.getCurrentDateTimeUtc();
    var deviceName = await UtilDevice.getDeviceName();
    user.lastLoginDevice = deviceName;
    var deviceIp = await UtilDevice.getIpAddress();
    user.lastLoginIp = deviceIp;
    _boxUser.put(user);

    // store users details in storage
    await _repoStorage.setUser(json.encode(user.toMap()));
    // update last login time in Entity User
    Loader.hideLoader();
    Get.offAllNamed(AppRoute.home);
  }

  Future<void> checkUserCount() async {
    int userCount = _boxUser.count();
    debugPrint('userCount: $userCount');
    if (userCount == 0) {
      List<EntityUser> users = await loadUsersFromJson();
      _boxUser.putMany(users);
    } else {
      for (var user in _boxUser.getAll()) {
        debugPrint(json.encode(user.toMap()));
      }
    }
  }

  Future<List<EntityUser>> loadUsersFromJson() async {
    final String jsonString = await rootBundle.loadString(
      'assets/json/users.json',
    );
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => EntityUser.fromMap(e)).toList();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
