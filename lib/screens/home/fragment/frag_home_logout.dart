import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../commons/loader.dart';
import '../../../enums/enum_audit_action.dart';
import '../../../enums/enum_audit_module.dart';
import '../../../enums/enum_main_menu.dart';
import '../../../repository/repo_storage.dart';
import '../../../service/service_audit_log.dart';
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

              // Audit log
              AuditLogService.instance.logAction(
                module: AuditModule.system,
                action: AuditAction.logout,
                entityType: 'EntityUser',
                description: 'User logged out.',
              );

              final RepoStorage repoStorage = Get.find();
              repoStorage.logout();

              final ControllerHome homeController = Get.find();
              homeController.selectedMainMenu.value = EnumMainMenu.dashboard;

              Get.deleteAll(force: true);
              await StaticMethods.initServices();

              Get.offAllNamed(AppRoute.login);
            },
            child: Text('logout'.tr),
          ),
        ],
      ),
    );
  }
}
