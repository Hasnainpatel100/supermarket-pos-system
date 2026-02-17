import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../enums/enum_permission.dart';
import '../../../widget/button_permission.dart';
import '../controller_home.dart';

class FragHomeInventory extends StatelessWidget {
  const FragHomeInventory({super.key});

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
                ButtonPermission(
                  permission: EnumPermission.itemCreate.name,
                  permissions: permissions,
                  icon: Icons.add_box_outlined,
                  label: 'item_create'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.itemUpdate.name,
                  permissions: permissions,
                  icon: Icons.edit_outlined,
                  label: 'item_update'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.stockIn.name,
                  permissions: permissions,
                  icon: Icons.call_received_outlined,
                  label: 'stock_in'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.stockOut.name,
                  permissions: permissions,
                  icon: Icons.call_made_outlined,
                  label: 'stock_out'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.stockAdjust.name,
                  permissions: permissions,
                  icon: Icons.tune_outlined,
                  label: 'stock_adjust'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.stockCount.name,
                  permissions: permissions,
                  icon: Icons.fact_check_outlined,
                  label: 'stock_count'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.expiryManage.name,
                  permissions: permissions,
                  icon: Icons.event_busy_outlined,
                  label: 'expiry_manage'.tr,
                  onPressed: () {},
                ),
              ],
            ),
          );
        }),
        Expanded(child: Container()),
      ],
    );
  }
}
