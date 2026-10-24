import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/widget/icon_box.dart';
import '../../../../widget/app_dialog_components.dart';

import '../../../../service/service_currency.dart';
import '../../../../service/service_locale.dart';
import '../../../../service/service_theme.dart';
import '../../../../service/service_brand_context.dart';
import '../../../../widget/dialog_plan_expiry.dart';
import '../../../../widget/list_tile_dropdown.dart';
import '../../../../widget/list_tile_toggle.dart';
import '../../../../widget/my_card.dart';
import 'controller_home_settings.dart';
import '../../../../service/service_voice.dart';
import '../bills/dialog_bill_print_preview.dart';

class FragHomeSettings extends StatelessWidget {
  FragHomeSettings({super.key});

  final themeService        = Get.find<ServiceTheme>();
  final localeService       = Get.find<ServiceLocale>();
  final currencyService     = Get.find<ServiceCurrency>();
  final controllerSettings  = Get.find<ControllerHomeSettings>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
            tabs: [
              Tab(
                icon: const Icon(Icons.person_outline_rounded, size: 20),
                text: 'profile'.tr,
              ),
              Tab(
                icon: const Icon(Icons.print_outlined, size: 20),
                text: 'printer'.tr,
              ),
              Tab(
                icon: const Icon(Icons.receipt_long_rounded, size: 20),
                text: 'Bill & Preview'.tr,
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
            _BillPreviewTab(controller: controllerSettings),
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
              _buildSectionHeader(context, 'appearance_locale'.tr),
              const SizedBox(height: 4),
              MyCard(
                child: Column(
                  children: [
                    // Dark Mode Toggle
                    Obx(() {
                      return ListTileToggle(
                        leading: const IconBox(icon: Icons.dark_mode_outlined),
                        title: 'dark_mode'.tr,
                        subtitle: 'enable_dark_theme'.tr,
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
                        title: 'language'.tr,
                        subtitle: 'change_app_language'.tr,
                        value: localeService.rxLocale.value,
                        onChanged: (locale) {
                          if (locale != null) localeService.update(locale);
                        },
                        items: [
                          DropdownMenuItem(
                              value: const Locale('en', 'US'),
                              child: Text('lang_english'.tr)),
                          DropdownMenuItem(
                              value: const Locale('hi', 'IN'),
                              child: Text('lang_hindi'.tr)),
                          DropdownMenuItem(
                              value: const Locale('mr', 'IN'),
                              child: Text('lang_marathi'.tr)),
                          DropdownMenuItem(
                              value: const Locale('ur', 'PK'),
                              child: Text('lang_urdu'.tr)),
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
                        title: 'currency'.tr,
                        subtitle: '${'selected'.tr}: $symbol',
                        value: symbol,
                        onChanged: (value) {
                          if (value != null) currencyService.update(value);
                        },
                        items: [
                          DropdownMenuItem(value: '₹', child: Text('currency_rupees'.tr)),
                          DropdownMenuItem(
                              value: '\$', child: Text('currency_dollars'.tr)),
                          DropdownMenuItem(value: '€', child: Text('currency_euro'.tr)),
                          DropdownMenuItem(value: '£', child: Text('currency_pounds'.tr)),
                          DropdownMenuItem(
                              value: '﷼', child: Text('currency_saudi_riyal'.tr)),
                          DropdownMenuItem(
                              value: 'د.إ', child: Text('currency_uae_dirham'.tr)),
                          DropdownMenuItem(
                              value: 'د.ك', child: Text('currency_kuwaiti_dinar'.tr)),
                          DropdownMenuItem(
                              value: '.د.ب', child: Text('currency_bahraini_dinar'.tr)),
                          DropdownMenuItem(
                              value: 'ر.ق', child: Text('currency_qatari_riyal'.tr)),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Active Brand & Branch ────────────────────────────────────
              _buildSectionHeader(context, 'Brand & Branch Details'),
              const SizedBox(height: 4),
              Obx(() {
                final brandCtx = Get.find<ServiceBrandContext>();
                final brand = brandCtx.rxSelectedBrand.value;
                final branch = brandCtx.rxSelectedBranch.value;
                final brandName = brand?.name.en ?? 'No Brand Configured';
                final branchName = branch?.name.en ?? 'No Branch Selected';
                final branchCode = branch?.branchCode ?? '';
                final isBranchActive = (branch?.status.toLowerCase() ?? '') == 'active';

                return MyCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.store_mall_directory_rounded,
                                color: colorScheme.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'active_org_context'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'current_org_desc'.tr,
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
                      Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Brand Box
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.storefront_rounded, size: 16, color: colorScheme.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'active_brand'.tr,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.primary,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    brandName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (brand?.branchCode != null && brand!.branchCode!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Code: ${brand.branchCode}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                  if (brand?.registration.gstNo != null &&
                                      brand!.registration.gstNo.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'GST/Tax: ${brand.registration.gstNo}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Branch Box
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded, size: 16, color: Colors.deepPurple),
                                      const SizedBox(width: 6),
                                      Text(
                                        'active_branch'.tr,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.deepPurple,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isBranchActive
                                              ? Colors.green.withValues(alpha: 0.15)
                                              : Colors.orange.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          branch?.status.toUpperCase() ?? 'NONE',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isBranchActive ? Colors.green : Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    branchName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (branchCode.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Branch Code: $branchCode',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                  if (branch?.address.city != null && branch!.address.city.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'City: ${branch.address.city}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                  if (branch?.planDetails != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Plan: ${branch!.planDetails!.note.isNotEmpty ? branch.planDetails!.note : "Active"} (Expires: ${branch.planDetails!.formattedExpiry})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: branch.planDetails!.isExpiringSoon || branch.planDetails!.isExpired
                                            ? Colors.amber.shade800
                                            : Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (branch?.planDetails != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Expiry Alarm: Alerts ${brandCtx.expiryAlarmDays} days before expiry',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colorScheme.onSurface.withValues(alpha: 0.65),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => DialogPlanExpiry.show(context, branch: branch),
                              icon: const Icon(Icons.credit_card_rounded, size: 14),
                              label: Text('view_plan_set_alarm'.tr, style: const TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 28),

              // ── Store Information ─────────────────────────────────────────
              _buildSectionHeader(context, 'store_information'.tr),
              const SizedBox(height: 4),
              MyCard(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: controllerSettings.formKey,
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
                                'business_details'.tr,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'business_details_subtitle'.tr,
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
                      label: 'company_name'.tr,
                      icon: Icons.business_outlined,
                      isDark: isDark,
                      colorScheme: colorScheme,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      context: context,
                      controller: controllerSettings.storeAddressController,
                      label: 'address'.tr,
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                      isDark: isDark,
                      colorScheme: colorScheme,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            context: context,
                            controller:
                                controllerSettings.storePhoneController,
                            label: 'phone'.tr,
                            icon: Icons.phone_outlined,
                            isDark: isDark,
                            colorScheme: colorScheme,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            context: context,
                            controller:
                                controllerSettings.storeGstinController,
                            label: 'gstin'.tr,
                            icon: Icons.receipt_outlined,
                            isDark: isDark,
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            context: context,
                            controller: controllerSettings.storeEmailController,
                            label: 'email'.tr,
                            icon: Icons.email_outlined,
                            isDark: isDark,
                            colorScheme: colorScheme,
                            required: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // UPI & Digital Payments Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.qr_code_2_rounded, size: 18, color: colorScheme.primary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'UPI & Digital Payments (POS QR Billing)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Configure UPI IDs for dynamic customer QR code generation at checkout.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  context: context,
                                  controller: controllerSettings.storeUpiIdController,
                                  label: 'Primary UPI ID / VPA (Default: patelhusnain02-1@oksbi)',
                                  icon: Icons.verified_user_outlined,
                                  isDark: isDark,
                                  colorScheme: colorScheme,
                                  required: false,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildTextField(
                                  context: context,
                                  controller: controllerSettings.storeAlternateUpiIdController,
                                  label: 'Alternate UPI ID / VPA (Backup Account)',
                                  icon: Icons.swap_horiz_rounded,
                                  isDark: isDark,
                                  colorScheme: colorScheme,
                                  required: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 14, color: colorScheme.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Cashiers can switch between Primary and Alternate UPI ID with 1 tap during billing if bank servers are busy.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.primary.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: controllerSettings.saveStoreDetails,
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: Text(
                          'save_store_details'.tr,
                          style: const TextStyle(
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
            ),
              const SizedBox(height: 28),



              // ── Support & About ───────────────────────────────────────────
              _buildSectionHeader(context, 'support_about'.tr),
              const SizedBox(height: 4),
              MyCard(
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          const IconBox(icon: Icons.help_outline_rounded),
                      title: Text('help_support'.tr),
                      subtitle:
                          Text('help_support_subtitle'.tr),
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
                      title: Text('about'.tr),
                      subtitle: Text('pos_system_name'.tr),
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
              _buildSectionHeader(context, 'danger_zone'.tr),
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
                    'reset_settings'.tr,
                    style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'restore_settings_to_default'.tr,
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
    bool required = false,
  }) {
    return AppTextField(
      controller: controller,
      label: label,
      prefixIcon: icon,
      maxLines: maxLines,
      required: required,
      keyboardType: label.toLowerCase().contains('phone')
          ? TextInputType.phone
          : label.toLowerCase().contains('email')
              ? TextInputType.emailAddress
              : TextInputType.text,
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
              'reset_settings'.tr,
              style: Theme.of(Get.context!)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'reset_confirmation_message'.tr,
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
            child: Text('cancel'.tr),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              localeService.update(const Locale('en', 'US'));
              currencyService.update('INR');
              Get.back();
              Get.snackbar(
                'success'.tr,
                'settings_reset_success'.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: colorScheme.primary,
                colorText: Colors.white,
                margin: const EdgeInsets.all(12),
                borderRadius: 10,
              );
            },
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: Text('reset'.tr),
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
              // ── 1. Thermal Receipt Printer (POS Checkout) ────────────────
              _sectionHeader(context, 'Thermal Receipt Printer (POS Checkout)'),
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
                            color: Colors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_long_rounded,
                              color: Colors.teal, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Default Thermal Receipt Printer',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Used for printing customer receipts & thermal slips at checkout',
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
                                tooltip: 'refresh_printers'.tr,
                                onPressed: controller.fetchPrinters,
                                color: colorScheme.primary,
                              )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Thermal Printer Dropdown
                    Text(
                      'Select Thermal Receipt Printer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Obx(() {
                      final printers = controller.rxAvailablePrinters;
                      final selected = controller.rxDefaultThermalPrinter.value;
                      final safeValue =
                          printers.contains(selected) ? selected : null;

                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.receipt_outlined,
                              size: 20, color: Colors.teal),
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
                            borderSide: const BorderSide(
                                color: Colors.teal, width: 1.5),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : colorScheme.surfaceContainerLowest,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          hintText: printers.isEmpty
                              ? 'no_printers_found'.tr
                              : 'Select Thermal Printer',
                        ),
                        isExpanded: true,
                        initialValue: safeValue,
                        hint: Text(
                          printers.isEmpty
                              ? 'no_printers_tap_refresh'.tr
                              : 'System Default Printer (Auto-detect)',
                          style: TextStyle(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                              fontSize: 14),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: '',
                            child: Row(
                              children: [
                                Icon(Icons.computer_outlined,
                                    size: 18,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5)),
                                const SizedBox(width: 8),
                                const Text('System Default Printer'),
                              ],
                            ),
                          ),
                          ...printers.map(
                            (name) => DropdownMenuItem<String>(
                              value: name,
                              child: Row(
                                children: [
                                  const Icon(Icons.print_rounded,
                                      size: 18, color: Colors.teal),
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
                          controller.rxDefaultThermalPrinter.value = value ?? '';
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                    // Default Receipt Paper Size (80mm vs 56mm/58mm vs A4)
                    Text(
                      'Default Thermal Paper Size',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Obx(() => DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.straighten_rounded,
                                size: 20, color: Colors.teal),
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
                              borderSide: const BorderSide(
                                  color: Colors.teal, width: 1.5),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : colorScheme.surfaceContainerLowest,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          isExpanded: true,
                          initialValue: controller.rxThermalPaperSize.value,
                          items: const [
                            DropdownMenuItem(
                              value: '80mm',
                              child: Row(
                                children: [
                                  Icon(Icons.receipt_long_rounded,
                                      size: 18, color: Colors.teal),
                                  SizedBox(width: 10),
                                  Text('80mm Thermal (3") - Standard Supermarket Roll'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: '58mm',
                              child: Row(
                                children: [
                                  Icon(Icons.receipt_outlined,
                                      size: 18, color: Colors.teal),
                                  SizedBox(width: 10),
                                  Text('58mm Thermal (2.25") - POS Roll'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: '56mm',
                              child: Row(
                                children: [
                                  Icon(Icons.receipt_outlined,
                                      size: 18, color: Colors.teal),
                                  SizedBox(width: 10),
                                  Text('56mm Thermal (2") - Compact Roll'),
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
                                  Text('A4 Full Page Tax Invoice'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              controller.rxThermalPaperSize.value = val;
                            }
                          },
                        )),
                    const SizedBox(height: 12),
                    // Auto-print switch
                    Obx(() => SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Auto-print receipt on bill settlement',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Automatically send receipt to printer when cashier clicks Settle / Complete',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                          value: controller.rxAutoPrintBill.value,
                          activeThumbColor: Colors.teal,
                          onChanged: (v) => controller.rxAutoPrintBill.value = v,
                        )),

                    const SizedBox(height: 8),

                    // Show item tax in receipt item list switch
                    Obx(() => SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Show item tax in receipt item list',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Show tax rate next to each item in the receipt (Standard restaurant style is OFF for a clean bill)',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                          value: controller.rxShowTaxInItemList.value,
                          activeThumbColor: Colors.teal,
                          onChanged: (v) => controller.rxShowTaxInItemList.value = v,
                        )),

                    const Divider(height: 24),

                    // Voice Soundbox announcement switch
                    Obx(() => SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              const Text(
                                'Digital Software Soundbox (PC Speaker)',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'IN-APP TTS',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Uses PC speakers to announce payments aloud like a digital soundbox (saves physical soundbox rental). Turn OFF if you already use a physical hardware Paytm/PhonePe soundbox.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                          value: controller.rxVoiceAnnouncement.value,
                          activeThumbColor: Colors.purple,
                          onChanged: (v) => controller.rxVoiceAnnouncement.value = v,
                        )),

                    // Test Voice Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          ServiceVoice.announcePayment(
                            amount: 150.0,
                            paymentMode: 'UPI',
                            storeName: controller.rxStoreName.value,
                          );
                        },
                        icon: const Icon(Icons.volume_up_rounded, size: 16, color: Colors.purple),
                        label: const Text(
                          'Test Soundbox Voice',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.purple),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 2. Barcode & Label Sticker Printer ─────────────────────────
              _sectionHeader(context, 'Barcode & Label Printer (Product Stickers)'),
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
                            color: Colors.deepPurple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded,
                              color: Colors.deepPurple, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Barcode Label Printer',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Used exclusively by Barcode Generator to print price tags & stickers',
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
                    // Barcode Printer Dropdown
                    Obx(() {
                      final printers = controller.rxAvailablePrinters;
                      final selected = controller.rxDefaultPrinter.value;
                      final safeValue =
                          printers.contains(selected) ? selected : null;

                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.qr_code_scanner_rounded,
                              size: 20, color: Colors.deepPurple),
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
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(
                                color: Colors.deepPurple, width: 1.5),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : colorScheme.surfaceContainerLowest,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          hintText: printers.isEmpty
                              ? 'no_printers_found'.tr
                              : 'Select Barcode Printer',
                        ),
                        isExpanded: true,
                        initialValue: safeValue,
                        hint: Text(
                          printers.isEmpty
                              ? 'no_printers_tap_refresh'.tr
                              : 'system_default'.tr,
                          style: TextStyle(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                              fontSize: 14),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: '',
                            child: Row(
                              children: [
                                Icon(Icons.computer_outlined,
                                    size: 18,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5)),
                                const SizedBox(width: 8),
                                Text('system_default'.tr),
                              ],
                            ),
                          ),
                          ...printers.map(
                            (name) => DropdownMenuItem<String>(
                              value: name,
                              child: Row(
                                children: [
                                  const Icon(Icons.print_rounded,
                                      size: 18, color: Colors.deepPurple),
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
                                      'no_printers_detected'.tr,
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
              _sectionHeader(context, 'barcode_paper'.tr),
              const SizedBox(height: 4),
              MyCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barcode Type
                    Text(
                      'barcode_type'.tr,
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
                          initialValue: controller.rxBarcodeType.value,
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
                      'paper_size'.tr,
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
                          initialValue: controller.rxPaperSize.value,
                          items: [
                            DropdownMenuItem(
                              value: '58mm',
                              child: Row(
                                children: [
                                  const Icon(Icons.receipt_long_outlined,
                                      size: 18, color: Colors.teal),
                                  const SizedBox(width: 10),
                                  Text('${'paper_size_58mm'.tr} (56mm/58mm Thermal - 2")'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: '80mm',
                              child: Row(
                                children: [
                                  const Icon(Icons.receipt_long_outlined,
                                      size: 18, color: Colors.green),
                                  const SizedBox(width: 10),
                                  Text('${'paper_size_80mm'.tr} (80mm Thermal - 3")'),
                                ],
                              ),
                            ),
                            const DropdownMenuItem(
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
                                  Text('custom'.tr),
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
              _sectionHeader(context, 'label_details'.tr),
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
                          title: Text(
                            'show_item_name'.tr,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            'show_item_name_subtitle'.tr,
                            style: const TextStyle(fontSize: 12),
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
                          title: Text(
                            'show_price'.tr,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            'show_price_subtitle'.tr,
                            style: const TextStyle(fontSize: 12),
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
                                  Text(
                                    'extra_information'.tr,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'extra_information_subtitle'.tr,
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
                              hintText: 'extra_info_hint'.tr,
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
                                  'a4_layout'.tr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'a4_layout_subtitle'.tr,
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
                        'barcodes_per_line'.tr,
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
                            tooltip: 'decrease'.tr,
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
                                    '${controller.rxA4Columns.value} ${'columns'.tr}',
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
                            tooltip: 'increase'.tr,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Rows (lines per page)
                      Text(
                        'lines_per_page'.tr,
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
                            tooltip: 'decrease'.tr,
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
                                    '${controller.rxA4Rows.value} ${'lines'.tr}',
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
                            tooltip: 'increase'.tr,
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
                                      'page_capacity'.tr,
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
                                            text: 'barcodes'.tr,
                                            style: const TextStyle(
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
                                  '$cols×$rows',
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
                  label: Text(
                    'save_printer_settings'.tr,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
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
                        'printer_settings_info'.tr,
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

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: Bill & Receipt Print Preview Settings
// ─────────────────────────────────────────────────────────────────────────────

class _BillPreviewTab extends StatefulWidget {
  final ControllerHomeSettings controller;
  const _BillPreviewTab({required this.controller});

  @override
  State<_BillPreviewTab> createState() => _BillPreviewTabState();
}

class _BillPreviewTabState extends State<_BillPreviewTab> {
  void _openFullScreenPreview(BuildContext context) {
    final sampleBill = widget.controller.createSampleBill();
    Get.dialog(
      DialogBillPrintPreview(
        bill: sampleBill,
        initialPaperSize: widget.controller.rxThermalPaperSize.value,
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.1,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return MyCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (activeColor ?? cs.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: activeColor ?? cs.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: activeColor ?? cs.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Configuration Controls
                    Expanded(
                      flex: 6,
                      child: _buildControls(context, cs, isDark),
                    ),
                    const SizedBox(width: 24),
                    // Right Column: Live Interactive Receipt Mockup
                    Expanded(
                      flex: 4,
                      child: _buildLiveReceiptMockup(context, cs, isDark),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildControls(context, cs, isDark),
                    const SizedBox(height: 24),
                    _buildLiveReceiptMockup(context, cs, isDark),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildControls(BuildContext context, ColorScheme cs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Top Gradient Info Banner ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E3A8A), const Color(0xFF1E293B)]
                  : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bill & Receipt Preview Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customize your receipt layout, toggle GST breakdown details, and preview changes live.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: cs.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.fullscreen_rounded, size: 20),
                label: const Text('Open PDF Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _openFullScreenPreview(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── SECTION 1: GST Breakdown & Tax Settings ──
        _buildSectionHeader(context, 'GST Breakdown & Tax Display', Icons.calculate_outlined),

        Obx(() => _buildSwitchCard(
              context: context,
              title: 'Show GST Breakdown Table',
              subtitle: 'Display the slab-wise GST table (Taxable, CGST, SGST, CESS, Total) at the bottom of the bill',
              icon: Icons.table_chart_rounded,
              activeColor: Colors.teal,
              value: widget.controller.rxShowGstBreakup.value,
              onChanged: (val) => widget.controller.rxShowGstBreakup.value = val,
            )),

        Obx(() => _buildSwitchCard(
              context: context,
              title: 'Show Tax Rate in Item List',
              subtitle: 'Display [GST 5%] beneath each item row in the receipt item list',
              icon: Icons.percent_rounded,
              activeColor: Colors.indigo,
              value: widget.controller.rxShowTaxInItemList.value,
              onChanged: (val) => widget.controller.rxShowTaxInItemList.value = val,
            )),

        const SizedBox(height: 16),

        // ── SECTION 2: Bill Customization & Extra Details ──
        _buildSectionHeader(context, 'Receipt Content & Extra Details', Icons.tune_rounded),

        Obx(() => _buildSwitchCard(
              context: context,
              title: 'Print Barcode on Bill',
              subtitle: 'Prints Code128 barcode of Bill Number at the bottom for quick scanner search and returns',
              icon: Icons.qr_code_rounded,
              activeColor: Colors.deepPurple,
              value: widget.controller.rxShowBillBarcode.value,
              onChanged: (val) => widget.controller.rxShowBillBarcode.value = val,
            )),

        Obx(() => _buildSwitchCard(
              context: context,
              title: 'Auto-Print Receipt on Bill Settlement',
              subtitle: 'Instantly sends print job to thermal printer upon completing cash/UPI checkout',
              icon: Icons.print_rounded,
              activeColor: Colors.blue,
              value: widget.controller.rxAutoPrintBill.value,
              onChanged: (val) => widget.controller.rxAutoPrintBill.value = val,
            )),

        // Paper Size Quick Switcher
        MyCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.aspect_ratio_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Thermal Paper Roll Width',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Select standard POS roll width for thermal printing.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final current = widget.controller.rxThermalPaperSize.value;
                  return Wrap(
                    spacing: 10,
                    children: [
                      ChoiceChip(
                        label: const Text('80mm (Standard POS)'),
                        selected: current == '80mm',
                        onSelected: (sel) {
                          if (sel) widget.controller.rxThermalPaperSize.value = '80mm';
                        },
                      ),
                      ChoiceChip(
                        label: const Text('58mm (Compact)'),
                        selected: current == '58mm',
                        onSelected: (sel) {
                          if (sel) widget.controller.rxThermalPaperSize.value = '58mm';
                        },
                      ),
                      ChoiceChip(
                        label: const Text('56mm (Mini)'),
                        selected: current == '56mm',
                        onSelected: (sel) {
                          if (sel) widget.controller.rxThermalPaperSize.value = '56mm';
                        },
                      ),
                      ChoiceChip(
                        label: const Text('A4 Invoice'),
                        selected: current == 'A4',
                        onSelected: (sel) {
                          if (sel) widget.controller.rxThermalPaperSize.value = 'A4';
                        },
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),

        // Footer Tagline & Return Policy Fields
        MyCard(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Custom Footer & Return Policy',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: widget.controller.billFooterTaglineController,
                  decoration: InputDecoration(
                    labelText: 'Footer Tagline (e.g. Thank You! Visit Again)',
                    prefixIcon: const Icon(Icons.favorite_outline_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: widget.controller.billTermsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Return / Exchange Terms & Conditions',
                    prefixIcon: const Icon(Icons.policy_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Save Button
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
            ),
            icon: const Icon(Icons.save_rounded, size: 20),
            label: const Text(
              'Save Bill Settings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: () => widget.controller.saveBillSettings(),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveReceiptMockup(BuildContext context, ColorScheme cs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(context, 'Live Receipt Mockup', Icons.visibility_rounded),

        // Thermal Paper Container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          child: Obx(() {
            final storeName = widget.controller.rxStoreName.value;
            final storeAddr = widget.controller.rxStoreAddress.value;
            final storeGstin = widget.controller.rxStoreGstin.value;
            final showGstBreakup = widget.controller.rxShowGstBreakup.value;
            final showTaxInItem = widget.controller.rxShowTaxInItemList.value;
            final showBarcode = widget.controller.rxShowBillBarcode.value;
            final tagline = widget.controller.billFooterTaglineController.text.isNotEmpty
                ? widget.controller.billFooterTaglineController.text
                : widget.controller.rxBillFooterTagline.value;
            final terms = widget.controller.billTermsController.text.isNotEmpty
                ? widget.controller.billTermsController.text
                : widget.controller.rxBillTerms.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Store Name & Header
                Center(
                  child: Text(
                    storeName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black87),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'RETAIL TAX INVOICE',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Center(
                  child: Text(
                    storeAddr,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 10),
                  ),
                ),
                if (storeGstin.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Center(
                    child: Text(
                      'GSTIN: $storeGstin',
                      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // Double Divider
                _mockDivider(doubleLine: true),
                const SizedBox(height: 6),

                // Bill Metadata Row 1: Bill No
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bill: #BIL-1792831688290',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Bill Metadata Row 2: Customer Name on left, Date & Time in front on right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cust: Hasnain',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '24/10/2026, 02:18 PM',
                      style: TextStyle(
                        color: Colors.grey.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                _mockDivider(dashed: true),
                const SizedBox(height: 4),

                // Items Table Header
                const Row(
                  children: [
                    Expanded(flex: 4, child: Text('ITEM', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10))),
                    Expanded(flex: 3, child: Text('QTY x RATE', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10))),
                    Expanded(flex: 3, child: Text('AMOUNT', textAlign: TextAlign.right, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10))),
                  ],
                ),
                const SizedBox(height: 4),
                _mockDivider(dashed: true),
                const SizedBox(height: 4),

                // Item 1: iPhone 17 (Inclusive 5% GST)
                _mockItemRow('iPhone 17', '1 x ₹75,000', '₹75,000', showTax: showTaxInItem, taxLabel: '[GST 5%]'),
                const SizedBox(height: 4),

                // Item 2: Odonil
                _mockItemRow('Odonil [B: 1]', '1 x ₹120', '₹120', showTax: showTaxInItem, taxLabel: '[GST 5%]'),

                const SizedBox(height: 6),
                _mockDivider(dashed: true),
                const SizedBox(height: 4),

                // Subtotal & Totals
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Items: 2', style: TextStyle(color: Colors.black, fontSize: 10.5)),
                    Text('Total Qty: 2', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10.5)),
                  ],
                ),
                const SizedBox(height: 3),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                    Text('₹75,120.00', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CGST (2.5%):', style: TextStyle(color: Colors.black, fontSize: 10)),
                    Text('₹1,878.0', style: TextStyle(color: Colors.black, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 2),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SGST (2.5%):', style: TextStyle(color: Colors.black, fontSize: 10)),
                    Text('₹1,878.0', style: TextStyle(color: Colors.black, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 8),

                // NET PAYABLE Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NET PAYABLE:',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '₹78,876.00',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── GST Breakup Section (Toggled live by rxShowGstBreakup) ──
                if (showGstBreakup) ...[
                  const Center(
                    child: Text(
                      '<------- GST Breakup Details ------->',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  _mockDivider(dashed: true),
                  const SizedBox(height: 3),
                  const Row(
                    children: [
                      Expanded(flex: 2, child: Text('GST IND', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8.5))),
                      Expanded(flex: 3, child: Text('Taxable', textAlign: TextAlign.right, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8.5))),
                      Expanded(flex: 2, child: Text('CGST', textAlign: TextAlign.right, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8.5))),
                      Expanded(flex: 2, child: Text('SGST', textAlign: TextAlign.right, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8.5))),
                      Expanded(flex: 3, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8.5))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  _mockDivider(dashed: true),
                  const SizedBox(height: 2),
                  const Row(
                    children: [
                      Expanded(flex: 2, child: Text('1 (5%)', style: TextStyle(color: Colors.black, fontSize: 8.5))),
                      Expanded(flex: 3, child: Text('71,364.00', textAlign: TextAlign.right, style: TextStyle(color: Colors.black, fontSize: 8.5))),
                      Expanded(flex: 2, child: Text('1,878.0', textAlign: TextAlign.right, style: TextStyle(color: Colors.black, fontSize: 8.5))),
                      Expanded(flex: 2, child: Text('1,878.0', textAlign: TextAlign.right, style: TextStyle(color: Colors.black, fontSize: 8.5))),
                      Expanded(flex: 3, child: Text('75,120.00', textAlign: TextAlign.right, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8.5))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _mockDivider(dashed: true),
                  const SizedBox(height: 6),
                ],

                // Payment Details
                const Center(
                  child: Text(
                    '<----- Payment Details ----->',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 9.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const Center(
                  child: Text(
                    'CASH Payment : ₹78,876.00 /-',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // ── Barcode Section (Toggled live by rxShowBillBarcode) ──
                if (showBarcode) ...[
                  _mockDivider(dashed: true),
                  const SizedBox(height: 6),
                  Center(
                    child: Column(
                      children: [
                        // Barcode Representation Bars
                        Container(
                          height: 28,
                          width: 170,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black54, width: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              26,
                              (i) => Container(
                                width: (i % 3 == 0) ? 2.5 : ((i % 2 == 0) ? 1.5 : 1.0),
                                color: (i % 5 == 1) ? Colors.transparent : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'BIL-1792831688290',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Footer
                _mockDivider(dashed: true),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    tagline.isNotEmpty ? '*** $tagline ***' : '*** Thank You! Visit Again ***',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Center(
                  child: Text(
                    terms.isNotEmpty ? terms : 'Goods once sold can be exchanged within 7 days with bill',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 9.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Center(
                  child: Text(
                    'Software: RH POS',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 8.5,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),

        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.print_outlined, size: 18),
          label: const Text('Test Print / View Full PDF', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => _openFullScreenPreview(context),
        ),
      ],
    );
  }

  Widget _mockDivider({bool dashed = false, bool doubleLine = false}) {
    if (doubleLine) {
      return Column(
        children: [
          Container(height: 1, color: Colors.black54),
          const SizedBox(height: 2),
          Container(height: 1, color: Colors.black54),
        ],
      );
    }
    return Container(
      height: 1,
      color: Colors.grey.shade400,
    );
  }

  Widget _mockItemRow(String name, String qtyRate, String total, {bool showTax = false, String? taxLabel}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(flex: 4, child: Text(name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 10.5))),
            Expanded(flex: 3, child: Text(qtyRate, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade900, fontSize: 10))),
            Expanded(flex: 3, child: Text(total, textAlign: TextAlign.right, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10.5))),
          ],
        ),
        if (showTax && taxLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              taxLabel,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 9, fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}

