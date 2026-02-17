import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../commons/frag_coming_soon.dart';
import '../../enums/enum_main_menu.dart';
import '../../model/entity_user.dart';
import '../../repository/repo_drawer.dart';
import 'controller_home.dart';
import 'fragment/frag_home_dashboard.dart';
import 'fragment/frag_home_inventory.dart';
import 'fragment/frag_home_logout.dart';
import 'fragment/frag_home_pos.dart';
import 'fragment/frag_home_price_discount.dart';
import 'fragment/frag_home_purchase_supplier.dart';
import 'fragment/frag_home_report.dart';
import 'fragment/frag_home_settings.dart';
import 'fragment/users/frag_home_users.dart';

class ActivityHome extends StatelessWidget {
  const ActivityHome({super.key});

  @override
  Widget build(BuildContext context) {
    ControllerHome controller = Get.put(ControllerHome(), permanent: true);
    return Scaffold(
      body: Row(
        children: [
          Obx(() {
            EntityUser? user = controller.rxUser.value;
            if (user == null) {
              return SizedBox();
            }
            return SizedBox(
              width: controller.isDrawerCollapsed.value ? 70 : 260,
              child: RepoDrawer.drawerList(user),
            );
          }),

          Expanded(
            child: Obx(() {
              // return Center(
              //   child: Text(controller.selectedMainMenu.value.toString()),
              // );
              if (controller.selectedMainMenu.value == EnumMainMenu.dashboard) {
                return FragHomeDashboard();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.pos) {
                return FragHomePos();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.inventory) {
                return FragHomeInventory();
              }
              if (controller.selectedMainMenu.value ==
                  EnumMainMenu.pricingDiscount) {
                return FragHomePriceDiscount();
              }
              if (controller.selectedMainMenu.value ==
                  EnumMainMenu.purchaseSupplier) {
                return FragHomePurchaseSupplier();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.reports) {
                return FragHomeReport();
              }
              if (controller.selectedMainMenu.value ==
                  EnumMainMenu.systemUsers) {
                return FragHomeUsers(entityUser: controller.rxUser.value);
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.settings) {
                return FragHomeSettings();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.logout) {
                return FragHomeLogout();
              }
              return FragComingSoon();
            }),
          ),
        ],
      ),
    );
  }
}
