import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../commons/loader.dart';
import '../../../enums/enum_main_menu.dart';
import '../../../features/authentication/data/auth_repository.dart';
import '../../../repository/repo_storage.dart';
import '../../../util/app_route.dart';
import '../../../util/static_methods.dart';
import '../controller_home.dart';

class FragHomeLogout extends StatelessWidget {
  const FragHomeLogout({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerHome controllerHome = Get.find();
    return Center(
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_outlined,
              color: Theme.of(Get.context!).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Text(
              'logout'.tr,
              style: Theme.of(Get.context!).textTheme.titleLarge,
            ),
          ],
        ),
        content: Text(
          'confirm_logout_msg'.tr,
          style: Theme.of(Get.context!).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                controllerHome.selectedMainMenu.value = EnumMainMenu.dashboard,
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Loader.showLoader();

              try {
                if (Get.isRegistered<AuthRepository>()) {
                  await Get.find<AuthRepository>().logout();
                }

                if (Get.isRegistered<RepoStorage>()) {
                  final RepoStorage repoStorage = Get.find();
                  await repoStorage.logout();
                }

                if (Get.isRegistered<ControllerHome>()) {
                  final ControllerHome homeController = Get.find();
                  homeController.selectedMainMenu.value = EnumMainMenu.dashboard;
                }

                Get.deleteAll(force: true);
                await StaticMethods.initServices();
              } catch (e) {
                debugPrint('Notice during logout reset: $e');
              } finally {
                Loader.hideLoader();
                Get.offAllNamed(AppRoute.login);
              }
            },
            child: Text('logout'.tr),
          ),
        ],
      ),
    );
  }
}
