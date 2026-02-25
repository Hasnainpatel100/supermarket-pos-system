import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../enums/enum_permission.dart';
import '../../../widget/button_permission.dart';
import '../controller_home.dart';

class FragHomeReport extends StatelessWidget {
  const FragHomeReport({super.key});

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
                  permission: EnumPermission.reportSalesView.name,
                  permissions: permissions,
                  icon: Icons.bar_chart,
                  label: 'report_sales'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.reportStockView.name,
                  permissions: permissions,
                  icon: Icons.inventory_2,
                  label: 'report_stock'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.reportProfitView.name,
                  permissions: permissions,
                  icon: Icons.trending_up,
                  label: 'report_profit'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.reportTaxView.name,
                  permissions: permissions,
                  icon: Icons.receipt_long,
                  label: 'report_tax'.tr,
                  onPressed: () {},
                ),

                ButtonPermission(
                  permission: EnumPermission.reportExport.name,
                  permissions: permissions,
                  icon: Icons.file_download,
                  label: 'report_export'.tr,
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
