import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/home/controller_home.dart';
import '../service/service_brand_context.dart';

class SideMenuHeader extends StatelessWidget {
  const SideMenuHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerHome controller = Get.find();
    final ServiceBrandContext brandCtx = Get.find();
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final bool collapsed = controller.isDrawerCollapsed.value;
      final brandName = brandCtx.rxSelectedBrand.value?.name.en ?? 'Supermarket';

      return SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: collapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween,
          children: [
            if (!collapsed)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.store_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          brandName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            IconButton(
              icon: Icon(
                collapsed ? Icons.chevron_right : Icons.chevron_left,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              onPressed: controller.isDrawerCollapsed.toggle,
            ),
          ],
        ),
      );
    });
  }
}
