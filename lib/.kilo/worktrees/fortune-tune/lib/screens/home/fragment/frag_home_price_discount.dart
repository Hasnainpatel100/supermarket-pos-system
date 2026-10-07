import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../enums/enum_permission.dart';
import '../../../widget/button_permission.dart';
import '../controller_home.dart';

class FragHomePriceDiscount extends StatelessWidget {
  const FragHomePriceDiscount({super.key});

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
                  permission: EnumPermission.priceView.name,
                  permissions: permissions,
                  icon: Icons.visibility,
                  label: 'price_view'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.priceUpdate.name,
                  permissions: permissions,
                  icon: Icons.edit,
                  label: 'price_update'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.discountApply.name,
                  permissions: permissions,
                  icon: Icons.percent,
                  label: 'discount_apply'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.discountOverride.name,
                  permissions: permissions,
                  icon: Icons.lock_open,
                  label: 'discount_override'.tr,
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
