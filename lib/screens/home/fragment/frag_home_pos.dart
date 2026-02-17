import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../enums/enum_permission.dart';
import '../../../widget/button_permission.dart';
import '../controller_home.dart';

class FragHomePos extends StatelessWidget {
  const FragHomePos({super.key});

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
                  permission: EnumPermission.posBillCreate.name,
                  permissions: permissions,
                  icon: Icons.add,
                  label: 'bill_create'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.posBillHold.name,
                  permissions: permissions,
                  icon: Icons.pause,
                  label: 'bill_hold'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.posBillResume.name,
                  permissions: permissions,
                  icon: Icons.play_arrow,
                  label: 'bill_resume'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.posBillCancel.name,
                  permissions: permissions,
                  icon: Icons.cancel,
                  label: 'bill_cancel'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.posBillVoid.name,
                  permissions: permissions,
                  icon: Icons.block,
                  label: 'bill_void'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.posBillReturnSameDay.name,
                  permissions: permissions,
                  icon: Icons.undo,
                  label: 'bill_return'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.posPaymentCollect.name,
                  permissions: permissions,
                  icon: Icons.payments,
                  label: 'payment_collect'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.posBillReprint.name,
                  permissions: permissions,
                  icon: Icons.print,
                  label: 'bill_reprint'.tr,
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
