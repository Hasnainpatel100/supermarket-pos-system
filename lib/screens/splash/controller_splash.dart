import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/token_storage.dart';
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
    // Check both: user session data exists AND a valid access token is stored
    String strUser = await _repoStorage.getUser();
    debugPrint("splash strUser: $strUser");

    if (strUser.isEmpty) {
      Get.offAllNamed(AppRoute.login);
      return;
    }

    // Also verify that we have a valid access token from previous server login
    if (Get.isRegistered<TokenStorage>()) {
      final tokenStorage = Get.find<TokenStorage>();
      if (!tokenStorage.hasAccessToken) {
        debugPrint('⚠️ [Splash] User session found but no access token. Redirecting to login.');
        Get.offAllNamed(AppRoute.login);
        return;
      }
    }

    Get.offAllNamed(AppRoute.home);
  }
}
