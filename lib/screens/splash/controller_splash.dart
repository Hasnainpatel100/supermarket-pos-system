import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../repository/repo_storage.dart';
import '../../util/app_route.dart';

class ControllerSplash extends GetxController {
  final RepoStorage _repoStorage = Get.find();

  @override
  void onReady() {
    redirectToHomeScreen();
    super.onReady();
  }
  void redirectToHomeScreen() {
    Future.delayed(Duration(seconds: 3), () {
      isUserLogin();
    });
  }
  void isUserLogin() async {
    String strUser = await _repoStorage.getUser();
    debugPrint("splash strUser: $strUser");
    if (strUser.isEmpty) {
      Get.offAllNamed(AppRoute.login);
      return;
    }
    Get.offAllNamed(AppRoute.home);
  }
}
