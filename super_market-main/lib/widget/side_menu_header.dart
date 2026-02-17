import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/home/controller_home.dart';

class SideMenuHeader extends StatelessWidget {
  const SideMenuHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerHome controller = Get.find();

    return Obx(() {
      final bool collapsed = controller.isDrawerCollapsed.value;

      return SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: collapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween,
          children: [
            if (!collapsed)
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'RH Supermarket',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            IconButton(
              icon: Icon(collapsed ? Icons.chevron_right : Icons.chevron_left),
              onPressed: controller.isDrawerCollapsed.toggle,
            ),
          ],
        ),
      );
    });
  }
}
