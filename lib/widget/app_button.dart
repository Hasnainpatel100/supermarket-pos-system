import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final double borderRadius;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 48,
    this.borderRadius = 14,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: FilledButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor ?? cs.onPrimary),
                ),
              )
            : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
        label: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? cs.primary,
          foregroundColor: foregroundColor ?? cs.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}
