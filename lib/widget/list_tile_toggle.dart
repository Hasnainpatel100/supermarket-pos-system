import 'package:flutter/material.dart';

/*
How to use?
Theme:
Obx(() {
  final isDark = settingsController.currentTheme.value == ThemeMode.dark;
  return ListTileToggle(
    leading: const Icon(Icons.dark_mode_outlined),
    title: 'Dark Mode',
    subtitle: 'Enable dark theme',
    value: isDark,
    onChanged: (enabled) {
      settingsController.toggleTheme();
    },
  );
})

language:
class FeatureController extends GetxController {
  final enabled = true.obs;

  void toggle(bool value) {
    enabled.value = value;
  }
}
Obx(() {
  final controller = Get.find<FeatureController>();

  return ListTileSwitch(
    leading: Icon(
      controller.enabled.value
          ? Icons.check_circle_outline
          : Icons.block_outlined,
    ),
    title: controller.enabled.value ? 'Enabled' : 'Disabled',
    subtitle: 'Feature status',
    value: controller.enabled.value,
    onChanged: controller.toggle,
  );
});
* */
class ListTileToggle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? leading;
  final bool enabled;

  const ListTileToggle({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.leading,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      leading: leading,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Switch(value: value, onChanged: enabled ? onChanged : null),
    );
  }
}
