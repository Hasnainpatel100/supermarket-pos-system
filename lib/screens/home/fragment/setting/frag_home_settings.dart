import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/widget/icon_box.dart';

import '../../../../service/service_currency.dart';
import '../../../../service/service_locale.dart';
import '../../../../service/service_theme.dart';
import '../../../../widget/list_tile_dropdown.dart';
import '../../../../widget/list_tile_toggle.dart';
import '../../../../widget/my_card.dart';
import 'controller_home_settings.dart';

class FragHomeSettings extends StatelessWidget {
  FragHomeSettings({super.key});

  final themeService = Get.find<ServiceTheme>();
  final localeService = Get.find<ServiceLocale>();
  final currencyService = Get.find<ServiceCurrency>();
  final controllerSettings = Get.find<ControllerHomeSettings>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.settings_outlined, color: colorScheme.primary, size: 24),
            const SizedBox(width: 10),
            Text(
              'settings'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ──────────────────────────────────────────
                // SECTION: Appearance & Locale
                // ──────────────────────────────────────────
                _buildSectionHeader(context, "Appearance & Locale"),
                const SizedBox(height: 4),
                MyCard(
                  child: Column(
                    children: [
                      // Dark Mode Toggle
                      Obx(() {
                        return ListTileToggle(
                          leading:
                              const IconBox(icon: Icons.dark_mode_outlined),
                          title: 'Dark Mode',
                          subtitle: 'Enable dark theme',
                          value: themeService.rxIsDarkMode.value,
                          onChanged: (enabled) {
                            themeService.switchTheme();
                          },
                        );
                      }),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: colorScheme.outline.withValues(alpha: 0.12),
                      ),
                      // Language Selector
                      Obx(() {
                        return ListTileDropdown<Locale>(
                          leading:
                              const IconBox(icon: Icons.language_outlined),
                          title: 'Language',
                          subtitle: 'Change app language',
                          value: localeService.rxLocale.value,
                          onChanged: (locale) {
                            if (locale != null) {
                              localeService.update(locale);
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: Locale('en', 'US'),
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: Locale('hi', 'IN'),
                              child: Text('Hindi'),
                            ),
                            DropdownMenuItem(
                              value: Locale('mr', 'IN'),
                              child: Text('Marathi'),
                            ),
                            DropdownMenuItem(
                              value: Locale('ur', 'PK'),
                              child: Text('Urdu'),
                            ),
                          ],
                        );
                      }),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: colorScheme.outline.withValues(alpha: 0.12),
                      ),
                      // Currency Selector
                      Obx(() {
                        var symbol = currencyService.rxCurrency.value;
                        return ListTileDropdown<String>(
                          leading: const IconBox(
                              icon: Icons.attach_money_outlined),
                          title: 'Currency',
                          subtitle: 'Selected: $symbol',
                          value: symbol,
                          onChanged: (value) {
                            if (value != null) {
                              currencyService.update(value);
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                                value: '₹', child: Text('Rupees')),
                            DropdownMenuItem(
                                value: '\$', child: Text('Dollars')),
                            DropdownMenuItem(
                                value: '€', child: Text('Euro')),
                            DropdownMenuItem(
                                value: '£', child: Text('Pounds')),
                            DropdownMenuItem(
                              value: '﷼',
                              child: Text('Saudi Riyal'),
                            ),
                            DropdownMenuItem(
                              value: 'د.إ',
                              child: Text('UAE Dirham'),
                            ),
                            DropdownMenuItem(
                              value: 'د.ك',
                              child: Text('Kuwaiti Dinar'),
                            ),
                            DropdownMenuItem(
                              value: '.د.ب',
                              child: Text('Bahraini Dinar'),
                            ),
                            DropdownMenuItem(
                              value: 'ر.ق',
                              child: Text('Qatari Riyal'),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ──────────────────────────────────────────
                // SECTION: Store Information
                // ──────────────────────────────────────────
                _buildSectionHeader(context, "Store Information"),
                const SizedBox(height: 4),
                MyCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store icon + subtitle
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Business Details',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'This information appears on invoices & receipts',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildTextField(
                        context: context,
                        controller: controllerSettings.storeNameController,
                        label: "Company Name",
                        icon: Icons.business_outlined,
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context: context,
                        controller:
                            controllerSettings.storeAddressController,
                        label: "Address",
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              context: context,
                              controller:
                                  controllerSettings.storePhoneController,
                              label: "Phone",
                              icon: Icons.phone_outlined,
                              isDark: isDark,
                              colorScheme: colorScheme,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              context: context,
                              controller:
                                  controllerSettings.storeGstinController,
                              label: "GSTIN",
                              icon: Icons.receipt_outlined,
                              isDark: isDark,
                              colorScheme: colorScheme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context: context,
                        controller: controllerSettings.storeEmailController,
                        label: "Email",
                        icon: Icons.email_outlined,
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: controllerSettings.saveStoreDetails,
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text(
                            "Save Store Details",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ──────────────────────────────────────────
                // SECTION: WhatsApp Integration
                // ──────────────────────────────────────────
                _buildSectionHeader(context, "WhatsApp Integration"),
                const SizedBox(height: 4),
                MyCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.chat_outlined,
                              color: Color(0xFF25D366),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cloud API Settings',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Configure to send invoices via WhatsApp',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        context: context,
                        controller:
                            controllerSettings.whatsAppTokenController,
                        label: "Access Token",
                        icon: Icons.vpn_key_outlined,
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context: context,
                        controller:
                            controllerSettings.whatsAppPhoneIdController,
                        label: "Phone Number ID",
                        icon: Icons.phone_android_outlined,
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed:
                              controllerSettings.saveWhatsAppCredentials,
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text(
                            "Save WhatsApp Settings",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ──────────────────────────────────────────
                // SECTION: Support & About
                // ──────────────────────────────────────────
                _buildSectionHeader(context, "Support & About"),
                const SizedBox(height: 4),
                MyCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading:
                            const IconBox(icon: Icons.help_outline_rounded),
                        title: Text('Help & Support'.tr),
                        subtitle: const Text("Click here to raise a ticket"),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: colorScheme.outline.withValues(alpha: 0.12),
                      ),
                      ListTile(
                        leading:
                            const IconBox(icon: Icons.info_outline_rounded),
                        title: const Text('About'),
                        subtitle: const Text("Supermarket POS System"),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'v1.0.0',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Danger Zone ──
                const SizedBox(height: 28),
                _buildSectionHeader(context, "Danger Zone"),
                const SizedBox(height: 4),
                MyCard(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.restart_alt_rounded,
                        size: 20,
                        color: colorScheme.error,
                      ),
                    ),
                    title: Text(
                      'Reset Settings',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Restore all settings to default',
                      style: TextStyle(
                        color: colorScheme.error.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: colorScheme.error.withValues(alpha: 0.5),
                    ),
                    onTap: _showResetDialog,
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required ColorScheme colorScheme,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  void _showResetDialog() {
    final colorScheme = Theme.of(Get.context!).colorScheme;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Reset Settings'.tr,
              style: Theme.of(Get.context!).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to reset all settings to default? This action cannot be undone.'
              .tr,
          style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
        actionsPadding:
            const EdgeInsets.only(right: 16, bottom: 16, left: 16),
        actions: [
          OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Cancel'.tr),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              localeService.update(const Locale('en', 'US'));
              currencyService.update('INR');
              Get.back();

              Get.snackbar(
                'Success'.tr,
                'Settings reset to default'.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: colorScheme.primary,
                colorText: Colors.white,
                margin: const EdgeInsets.all(12),
                borderRadius: 10,
              );
            },
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: Text('Reset'.tr),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
