import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/screens/home/fragment/customer/fragment_home_customer.dart';
import 'package:super_market/screens/home/fragment/item/fragment_home_item.dart';
import 'package:super_market/screens/home/fragment/pos/fragment_home_pos.dart';
import 'package:super_market/screens/home/fragment/stocks/fragment_home_stock.dart';

import '../../commons/frag_coming_soon.dart';
import '../../enums/enum_main_menu.dart';
import '../../model/entity_user.dart';
import '../../repository/repo_drawer.dart';
import 'controller_home.dart';
import 'fragment/frag_home_dashboard.dart';
import 'fragment/frag_home_logout.dart';
// import 'fragment/frag_home_pos.dart'; // Removed to avoid conflict
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
                return FragmentHomePos();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.item) {
                return FragmentHomeItem();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.stocks) {
                return FragmentHomeStock();
              }
              if (controller.selectedMainMenu.value == EnumMainMenu.customer) {
                return FragmentHomeCustomer();
              }
              if (controller.selectedMainMenu.value ==
                  EnumMainMenu.pricingDiscount) {
                return FragHomePriceDiscount();
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
