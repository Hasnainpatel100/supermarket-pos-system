import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../enums/enum_main_menu.dart';
import '../../../../enums/enum_permission.dart';
import '../../../../widget/section_tile.dart';
import '../../controller_home.dart';

class FragHomeSystem extends StatelessWidget {
  const FragHomeSystem({super.key});

  @override
  Widget build(BuildContext context) {
    ControllerHome controllerHome = Get.find();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Obx(() {
          if (controllerHome.rxUser.value == null) {
            return SizedBox();
          }
          var permissions = controllerHome.rxUser.value!.permissions!;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Wrap(
              children: [
                SectionTile(
                  title: 'Users',
                  icon: Icons.people,
                  visible: permissions.any((p) => p.startsWith('user')),
                  selected: true,
                  onTap: () {
                    controllerHome.selectedMainMenu.value = EnumMainMenu.systemUsers;
                  },
                ),

                SectionTile(
                  title: 'Backup & Recovery',
                  icon: Icons.backup_outlined,
                  visible: permissions.contains(
                    EnumPermission.backupRestore.name,
                  ),
                  selected: false,
                  onTap: () {
                    controllerHome.selectedMainMenu.value = EnumMainMenu.backup;
                  },
                ),

                /*ButtonPermission(
                  permission: EnumPermission.userCreate.name,
                  permissions: permissions,
                  icon: Icons.person_add,
                  label: 'user_create'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.userUpdate.name,
                  permissions: permissions,
                  icon: Icons.manage_accounts,
                  label: 'user_update'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.userDisable.name,
                  permissions: permissions,
                  icon: Icons.person_off,
                  label: 'user_disable'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.roleAssign.name,
                  permissions: permissions,
                  icon: Icons.security,
                  label: 'role_assign'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.systemSettingsUpdate.name,
                  permissions: permissions,
                  icon: Icons.settings,
                  label: 'system_settings'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.dataSyncManual.name,
                  permissions: permissions,
                  icon: Icons.sync,
                  label: 'data_sync'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.auditLogView.name,
                  permissions: permissions,
                  icon: Icons.history,
                  label: 'audit_log'.tr,
                  onPressed: () {},
                ),*/
              ],
            ),
          );
        }),
        Expanded(child: Container(color: Colors.black26)),
      ],
    );
  }
}
