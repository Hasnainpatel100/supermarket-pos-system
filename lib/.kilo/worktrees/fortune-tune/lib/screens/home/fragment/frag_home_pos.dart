import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../enums/enum_permission.dart';
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
            return const SizedBox();
          }
          var permissions = controllerHome.rxUser.value!.permissions!;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ModernPosAction(
                    permission: EnumPermission.posBillCreate.name,
                    permissions: permissions,
                    icon: Icons.add_circle_outline_rounded,
                    label: 'bill_create'.tr,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 12),
                  _ModernPosAction(
                    permission: EnumPermission.posBillHold.name,
                    permissions: permissions,
                    icon: Icons.pause_circle_outline_rounded,
                    label: 'bill_hold'.tr,
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 12),
                  _ModernPosAction(
                    permission: EnumPermission.posBillResume.name,
                    permissions: permissions,
                    icon: Icons.play_circle_outline_rounded,
                    label: 'bill_resume'.tr,
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 12),
                  _ModernPosAction(
                    permission: EnumPermission.posBillCancel.name,
                    permissions: permissions,
                    icon: Icons.cancel_outlined,
                    label: 'bill_cancel'.tr,
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 12),
                  _ModernPosAction(
                    permission: EnumPermission.posBillVoid.name,
                    permissions: permissions,
                    icon: Icons.block_rounded,
                    label: 'bill_void'.tr,
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade600, Colors.grey.shade800],
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 12),
                  _ModernPosAction(
                    permission: EnumPermission.posBillReturnSameDay.name,
                    permissions: permissions,
                    icon: Icons.undo_rounded,
                    label: 'bill_return'.tr,
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade600],
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 12),
                  _ModernPosAction(
                    permission: EnumPermission.posPaymentCollect.name,
                    permissions: permissions,
                    icon: Icons.payments_outlined,
                    label: 'payment_collect'.tr,
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade400, Colors.teal.shade600],
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 12),
                  _ModernPosAction(
                    permission: EnumPermission.posBillReprint.name,
                    permissions: permissions,
                    icon: Icons.print_rounded,
                    label: 'bill_reprint'.tr,
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        }),
        Expanded(child: Container(color: Colors.grey.shade50)),
      ],
    );
  }
}

class _ModernPosAction extends StatelessWidget {
  final String permission;
  final List<String> permissions;
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onPressed;

  const _ModernPosAction({
    required this.permission,
    required this.permissions,
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!permissions.contains(permission)) return const SizedBox.shrink();

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
