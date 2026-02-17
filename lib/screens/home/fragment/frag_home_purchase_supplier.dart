import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../enums/enum_permission.dart';
import '../../../widget/button_permission.dart';
import '../controller_home.dart';

class FragHomePurchaseSupplier extends StatelessWidget {
  const FragHomePurchaseSupplier({super.key});

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
                  permission: EnumPermission.purchaseCreate.name,
                  permissions: permissions,
                  icon: Icons.add_shopping_cart,
                  label: 'purchase_create'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.purchaseReceive.name,
                  permissions: permissions,
                  icon: Icons.inventory_2,
                  label: 'purchase_receive'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.supplierManage.name,
                  permissions: permissions,
                  icon: Icons.local_shipping,
                  label: 'supplier_manage'.tr,
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
