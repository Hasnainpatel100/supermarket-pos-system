import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/home/controller_home.dart';

/// Lightweight widget to conditionally render [child] if the current user possesses
/// the required permission(s). If unauthorized, renders [fallback] (defaults to SizedBox.shrink()).
class PermissionWidget extends StatelessWidget {
  /// Single permission check
  final String? permission;

  /// Multiple permissions check: user must possess AT LEAST ONE
  final List<String>? anyOf;

  /// Multiple permissions check: user must possess ALL of them
  final List<String>? allOf;

  /// Widget rendered when permission is granted
  final Widget child;

  /// Widget rendered when permission is denied (defaults to SizedBox.shrink())
  final Widget fallback;

  const PermissionWidget({
    super.key,
    this.permission,
    this.anyOf,
    this.allOf,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ControllerHome>()) {
      return child;
    }

    final controller = Get.find<ControllerHome>();

    return Obx(() {
      final user = controller.rxUser.value;
      if (user == null) {
        return fallback;
      }

      // SuperAdmin bypass
      final role = (user.role ?? '').trim().toUpperCase().replaceAll('_', '');
      if (role == 'SUPERADMIN') {
        return child;
      }

      final permissions = user.permissions ?? [];

      if (permission != null) {
        if (!permissions.contains(permission)) return fallback;
      }

      if (anyOf != null && anyOf!.isNotEmpty) {
        if (!anyOf!.any((p) => permissions.contains(p))) return fallback;
      }

      if (allOf != null && allOf!.isNotEmpty) {
        if (!allOf!.every((p) => permissions.contains(p))) return fallback;
      }

      return child;
    });
  }
}
