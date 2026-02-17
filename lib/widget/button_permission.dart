import 'package:flutter/material.dart';

class ButtonPermission extends StatelessWidget {
  const ButtonPermission({
    super.key,
    required this.permission,
    required this.permissions,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final String permission;
  final List<String> permissions;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (!permissions.contains(permission)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 12),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(padding: padding),
      ),
    );
  }
}
