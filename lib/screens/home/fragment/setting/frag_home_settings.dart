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

  final themeService        = Get.find<ServiceTheme>();
  final localeService       = Get.find<ServiceLocale>();
  final currencyService     = Get.find<ServiceCurrency>();
  final controllerSettings  = Get.find<ControllerHomeSettings>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.settings_outlined,
                  color: Theme.of(context).colorScheme.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                'settings'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          centerTitle: false,
          bottom: TabBar(
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(
                icon: Icon(Icons.person_outline_rounded, size: 20),
                text: 'Profile',
              ),
              Tab(
                icon: Icon(Icons.print_outlined, size: 20),
                text: 'Printer',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProfileTab(
              themeService: themeService,
              localeService: localeService,
              currencyService: currencyService,
              controllerSettings: controllerSettings,
            ),
            _PrinterTab(controller: controllerSettings),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: Profile (all existing settings unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.themeService,
    required this.localeService,
    required this.currencyService,
    required this.controllerSettings,
  });

  final ServiceTheme themeService;
  final ServiceLocale localeService;
  final ServiceCurrency currencyService;
  final ControllerHomeSettings controllerSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Appearance & Locale ──────────────────────────────────────
              _buildSectionHeader(context, "Appearance & Locale"),
              const SizedBox(height: 4),
              MyCard(
                child: Column(
                  children: [
                    // Dark Mode Toggle
                    Obx(() {
                      return ListTileToggle(
                        leading: const IconBox(icon: Icons.dark_mode_outlined),
                        title: 'Dark Mode',
                        subtitle: 'Enable dark theme',
                        value: themeService.rxIsDarkMode.value,
                        onChanged: (_) => themeService.switchTheme(),
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
                        leading: const IconBox(icon: Icons.language_outlined),
                        title: 'Language',
                        subtitle: 'Change app language',
                        value: localeService.rxLocale.value,
                        onChanged: (locale) {
                          if (locale != null) localeService.update(locale);
                        },
                        items: const [
                          DropdownMenuItem(
                              value: Locale('en', 'US'),
                              child: Text('English')),
                          DropdownMenuItem(
                              value: Locale('hi', 'IN'),
                              child: Text('Hindi')),
                          DropdownMenuItem(
                              value: Locale('mr', 'IN'),
                              child: Text('Marathi')),
                          DropdownMenuItem(
                              value: Locale('ur', 'PK'),
                              child: Text('Urdu')),
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
                      final symbol = currencyService.rxCurrency.value;
                      return ListTileDropdown<String>(
                        leading:
                            const IconBox(icon: Icons.attach_money_outlined),
                        title: 'Currency',
                        subtitle: 'Selected: $symbol',
                        value: symbol,
                        onChanged: (value) {
                          if (value != null) currencyService.update(value);
                        },
                        items: const [
                          DropdownMenuItem(value: '₹', child: Text('Rupees')),
                          DropdownMenuItem(
                              value: '\$', child: Text('Dollars')),
                          DropdownMenuItem(value: '€', child: Text('Euro')),
                          DropdownMenuItem(value: '£', child: Text('Pounds')),
                          DropdownMenuItem(
                              value: '﷼', child: Text('Saudi Riyal')),
                          DropdownMenuItem(
                              value: 'د.إ', child: Text('UAE Dirham')),
                          DropdownMenuItem(
                              value: 'د.ك', child: Text('Kuwaiti Dinar')),
                          DropdownMenuItem(
                              value: '.د.ب', child: Text('Bahraini Dinar')),
                          DropdownMenuItem(
                              value: 'ر.ق', child: Text('Qatari Riyal')),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Store Information ─────────────────────────────────────────
              _buildSectionHeader(context, "Store Information"),
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
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.storefront_rounded,
                              color: colorScheme.primary, size: 22),
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
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'This information appears on invoices & receipts',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.5)),
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
                      controller: controllerSettings.storeAddressController,
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
                              fontWeight: FontWeight.w600, fontSize: 14),
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



              // ── Support & About ───────────────────────────────────────────
              _buildSectionHeader(context, "Support & About"),
              const SizedBox(height: 4),
              MyCard(
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          const IconBox(icon: Icons.help_outline_rounded),
                      title: Text('Help & Support'.tr),
                      subtitle:
                          const Text("Click here to raise a ticket"),
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: colorScheme.onSurface.withValues(alpha: 0.4)),
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
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
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

              // ── Danger Zone ───────────────────────────────────────────────
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
                    child: Icon(Icons.restart_alt_rounded,
                        size: 20, color: colorScheme.error),
                  ),
                  title: Text(
                    'Reset Settings',
                    style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Restore all settings to default',
                    style: TextStyle(
                        color: colorScheme.error.withValues(alpha: 0.6),
                        fontSize: 13),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: colorScheme.error.withValues(alpha: 0.5)),
                  onTap: () => _showResetDialog(
                      localeService, currencyService, colorScheme),
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
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
          borderSide:
              BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : colorScheme.surfaceContainerLowest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _showResetDialog(ServiceLocale localeService,
      ServiceCurrency currencyService, ColorScheme colorScheme) {
    Get.dialog(
      AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: colorScheme.error, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Reset Settings'.tr,
              style: Theme.of(Get.context!)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to reset all settings to default? This action cannot be undone.'
              .tr,
          style: Theme.of(Get.context!)
              .textTheme
              .bodyMedium
              ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actionsPadding:
            const EdgeInsets.only(right: 16, bottom: 16, left: 16),
        actions: [
          OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: Printer Settings
// ─────────────────────────────────────────────────────────────────────────────

class _PrinterTab extends StatelessWidget {
  const _PrinterTab({required this.controller});

  final ControllerHomeSettings controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Default Printer ───────────────────────────────────────────
              _sectionHeader(context, 'Default Printer'),
              const SizedBox(height: 4),
              MyCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color:
                                colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.print_outlined,
                              color: colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Printer',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Choose a printer for barcode labels',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                        ),
                        // Refresh button
                        Obx(() => controller.rxFetchingPrinters.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Icons.refresh_rounded),
                                tooltip: 'Refresh printers',
                                onPressed: controller.fetchPrinters,
                                color: colorScheme.primary,
                              )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Printer Dropdown
                    Obx(() {
                      final printers = controller.rxAvailablePrinters;
                      final selected = controller.rxDefaultPrinter.value;

                      // Build a safe value: if selected not in list use null
                      final safeValue =
                          printers.contains(selected) ? selected : null;

                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.print_outlined,
                              size: 20, color: colorScheme.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color:
                                    colorScheme.outline.withValues(alpha: 0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color:
                                    colorScheme.outline.withValues(alpha: 0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: colorScheme.primary, width: 1.5),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : colorScheme.surfaceContainerLowest,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          hintText: printers.isEmpty
                              ? 'No printers found'
                              : 'Select a printer',
                        ),
                        isExpanded: true,
                        value: safeValue,
                        hint: Text(
                          printers.isEmpty
                              ? 'No printers found — tap refresh'
                              : 'System default',
                          style: TextStyle(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                              fontSize: 14),
                        ),
                        items: [
                          // "System Default" option (empty string = no override)
                          DropdownMenuItem<String>(
                            value: '',
                            child: Row(
                              children: [
                                Icon(Icons.computer_outlined,
                                    size: 18,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5)),
                                const SizedBox(width: 8),
                                const Text('System Default'),
                              ],
                            ),
                          ),
                          ...printers.map(
                            (name) => DropdownMenuItem<String>(
                              value: name,
                              child: Row(
                                children: [
                                  Icon(Icons.print_rounded,
                                      size: 18, color: colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          controller.rxDefaultPrinter.value = value ?? '';
                        },
                      );
                    }),
                    if (controller.rxAvailablePrinters.isEmpty) ...[
                      const SizedBox(height: 10),
                      Obx(() => !controller.rxFetchingPrinters.value
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        Colors.amber.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 16,
                                      color: Colors.amber.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No printers detected. The system default printer will be used.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.amber.shade800),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink()),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Barcode & Paper ──────────────────────────────────────────
              _sectionHeader(context, 'Barcode & Paper'),
              const SizedBox(height: 4),
              MyCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barcode Type
                    Text(
                      'Barcode Type',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            letterSpacing: 0.4,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Obx(() => DropdownButtonFormField<String>(
                          decoration: _dropdownDecoration(
                            colorScheme: colorScheme,
                            isDark: isDark,
                            icon: Icons.qr_code_scanner_outlined,
                          ),
                          isExpanded: true,
                          value: controller.rxBarcodeType.value,
                          items: const [
                            DropdownMenuItem(
                              value: '1D',
                              child: Row(
                                children: [
                                  Icon(Icons.view_week_rounded,
                                      size: 18, color: Colors.deepPurple),
                                  SizedBox(width: 10),
                                  Text('1D Barcode (Code128)'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: '2D',
                              child: Row(
                                children: [
                                  Icon(Icons.qr_code_2_rounded,
                                      size: 18, color: Colors.indigo),
                                  SizedBox(width: 10),
                                  Text('2D QR Code'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              controller.rxBarcodeType.value = val;
                            }
                          },
                        )),
                    const SizedBox(height: 18),

                    // Paper Size
                    Text(
                      'Paper Size',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            letterSpacing: 0.4,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Obx(() => DropdownButtonFormField<String>(
                          decoration: _dropdownDecoration(
                            colorScheme: colorScheme,
                            isDark: isDark,
                            icon: Icons.straighten_outlined,
                          ),
                          isExpanded: true,
                          value: controller.rxPaperSize.value,
                          items: const [
                            DropdownMenuItem(
                              value: '58mm',
                              child: Row(
                                children: [
                                  Icon(Icons.receipt_long_outlined,
                                      size: 18, color: Colors.teal),
                                  SizedBox(width: 10),
                                  Text('58mm (Narrow thermal)'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: '80mm',
                              child: Row(
                                children: [
                                  Icon(Icons.receipt_long_outlined,
                                      size: 18, color: Colors.green),
                                  SizedBox(width: 10),
                                  Text('80mm (Wide thermal)'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'A4',
                              child: Row(
                                children: [
                                  Icon(Icons.article_outlined,
                                      size: 18, color: Colors.blue),
                                  SizedBox(width: 10),
                                  Text('A4'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'custom',
                              child: Row(
                                children: [
                                  Icon(Icons.tune_rounded,
                                      size: 18, color: Colors.orange),
                                  SizedBox(width: 10),
                                  Text('Custom'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              controller.rxPaperSize.value = val;
                            }
                          },
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Label Details ─────────────────────────────────────────────
              _sectionHeader(context, 'Label Details'),
              const SizedBox(height: 4),
              MyCard(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    // Show Name
                    Obx(() => CheckboxListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          value: controller.rxShowName.value,
                          onChanged: (v) =>
                              controller.rxShowName.value = v ?? true,
                          title: const Text(
                            'Show Item Name',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Print item name above the barcode',
                            style: TextStyle(fontSize: 12),
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.label_outline,
                                size: 18, color: Colors.blue),
                          ),
                          activeColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        )),
                    Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: colorScheme.outline.withValues(alpha: 0.1)),
                    // Show Price
                    Obx(() => CheckboxListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          value: controller.rxShowPrice.value,
                          onChanged: (v) =>
                              controller.rxShowPrice.value = v ?? false,
                          title: const Text(
                            'Show Price',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Print selling price below the barcode',
                            style: TextStyle(fontSize: 12),
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                                Icons.attach_money_outlined,
                                size: 18,
                                color: Colors.green),
                          ),
                          activeColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        )),
                    Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: colorScheme.outline.withValues(alpha: 0.1)),
                    // Extra Info TextField
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.orange.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.notes_outlined,
                                    size: 18, color: Colors.orange),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Extra Information',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Optional text printed on the label',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.5)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: controller.extraInfoController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. "Best before 30 days" or store tagline',
                              hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.4)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: colorScheme.outline
                                        .withValues(alpha: 0.2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: colorScheme.outline
                                        .withValues(alpha: 0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: colorScheme.primary, width: 1.5),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : colorScheme.surfaceContainerLowest,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── A4 Layout Settings ─────────────────────────────────────────
              Obx(() {
                if (controller.rxPaperSize.value != 'A4') {
                  return const SizedBox.shrink();
                }
                return MyCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.grid_on_rounded,
                                color: Colors.blue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'A4 Layout',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Configure barcode grid for A4 paper',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.5)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Columns (barcodes per line)
                      Text(
                        'Barcodes per Line',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                              letterSpacing: 0.4,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (controller.rxA4Columns.value > 1) {
                                controller.rxA4Columns.value =
                                    controller.rxA4Columns.value - 1;
                              }
                            },
                            tooltip: 'Decrease',
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                              ),
                              alignment: Alignment.center,
                              child: Obx(() => Text(
                                    '${controller.rxA4Columns.value} column${controller.rxA4Columns.value > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  )),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              if (controller.rxA4Columns.value < 10) {
                                controller.rxA4Columns.value =
                                    controller.rxA4Columns.value + 1;
                              }
                            },
                            tooltip: 'Increase',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Rows (lines per page)
                      Text(
                        'Lines per Page',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                              letterSpacing: 0.4,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (controller.rxA4Rows.value > 1) {
                                controller.rxA4Rows.value =
                                    controller.rxA4Rows.value - 1;
                              }
                            },
                            tooltip: 'Decrease',
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.indigo.withValues(alpha: 0.3)),
                              ),
                              alignment: Alignment.center,
                              child: Obx(() => Text(
                                    '${controller.rxA4Rows.value} line${controller.rxA4Rows.value > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  )),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              if (controller.rxA4Rows.value < 20) {
                                controller.rxA4Rows.value =
                                    controller.rxA4Rows.value + 1;
                              }
                            },
                            tooltip: 'Increase',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Capacity display
                      Obx(() {
                        final cols = controller.rxA4Columns.value;
                        final rows = controller.rxA4Rows.value;
                        final total = cols * rows;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal.withValues(alpha: 0.1),
                                Colors.green.withValues(alpha: 0.1)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.teal.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.grid_on_rounded,
                                  color: Colors.teal, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Page Capacity',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.teal.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal.shade800,
                                        ),
                                        children: [
                                          TextSpan(text: '$total '),
                                          TextSpan(
                                            text:
                                                'barcode${total > 1 ? 's' : ''}',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.normal),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${cols}×${rows}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // ── Save Button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: controller.savePrinterSettings,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text(
                    'Save Printer Settings',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              // ── Info card ─────────────────────────────────────────────────
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'These settings are global defaults. You can still override '
                        'them individually when printing from the Items screen.',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.65),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
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

  InputDecoration _dropdownDecoration({
    required ColorScheme colorScheme,
    required bool isDark,
    required IconData icon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 20, color: colorScheme.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : colorScheme.surfaceContainerLowest,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
