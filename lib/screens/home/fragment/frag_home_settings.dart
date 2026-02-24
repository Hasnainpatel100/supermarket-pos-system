import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/widget/icon_box.dart';

import '../../../service/service_currency.dart';
import '../../../service/service_locale.dart';
import '../../../service/service_theme.dart';
import '../../../widget/list_tile_dropdown.dart';
import '../../../widget/list_tile_toggle.dart';
import '../../../widget/my_card.dart';
import 'controller_home_settings.dart';

class FragHomeSettings extends StatelessWidget {
  FragHomeSettings({super.key});

  final themeService = Get.find<ServiceTheme>();
  final localeService = Get.find<ServiceLocale>();
  final currencyService = Get.find<ServiceCurrency>();
  final controllerSettings = Get.find<ControllerHomeSettings>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr), centerTitle: false),
      body: CustomScrollView(
        slivers: [
          // Settings Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader("Appearance & Locale"),
                MyCard(
                  child: Obx(() {
                    return ListTileToggle(
                      leading: const IconBox(icon: Icons.dark_mode_outlined),
                      title: 'Dark Mode',
                      subtitle: 'Enable dark theme',
                      value: themeService.rxIsDarkMode.value,
                      onChanged: (enabled) {
                        themeService.switchTheme();
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                MyCard(
                  child: Obx(() {
                    return ListTileDropdown<Locale>(
                      leading: const IconBox(icon: Icons.language_outlined),
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
                ),
                const SizedBox(height: 16),
                MyCard(
                  child: Obx(() {
                    var symbol = currencyService.rxCurrency.value;
                    return ListTileDropdown<String>(
                      leading: const IconBox(icon: Icons.attach_money_outlined),
                      title: 'Currency',
                      subtitle: 'Selected Currency: $symbol',
                      value: symbol,
                      onChanged: (value) {
                        if (value != null) {
                          currencyService.update(value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: '₹', child: Text('Rupees')),
                        DropdownMenuItem(value: '\$', child: Text('Dollars')),
                        DropdownMenuItem(value: '€', child: Text('Euro')),
                        DropdownMenuItem(value: '£', child: Text('Pounds')),
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
                ),
                const SizedBox(height: 32),
                _buildSectionHeader("Store Information"),
                MyCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: controllerSettings.storeNameController,
                        label: "Company Name",
                        icon: Icons.business_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: controllerSettings.storeAddressController,
                        label: "Address",
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller:
                                  controllerSettings.storePhoneController,
                              label: "Phone",
                              icon: Icons.phone_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller:
                                  controllerSettings.storeGstinController,
                              label: "GSTIN",
                              icon: Icons.receipt_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: controllerSettings.storeEmailController,
                        label: "Email",
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: controllerSettings.saveStoreDetails,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text("Save Store Details"),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader("Support"),
                MyCard(
                  child: ListTile(
                    leading: const IconBox(icon: Icons.help_outline),
                    title: Text('Help & Support'.tr),
                    subtitle: const Text("Click here to raise ticket"),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_sharp,
                      size: 16,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 30,
        child: Center(
          child: Text(
            "Version: 1.0.0",
            style: Theme.of(Get.context!).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(Get.context!).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(Get.context!).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(Get.context!).colorScheme.surface,
      ),
    );
  }

  void _showResetDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_outlined,
              color: Theme.of(Get.context!).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Text(
              'Reset Settings'.tr,
              style: Theme.of(Get.context!).textTheme.titleLarge,
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to reset all settings to default?'.tr,
          style: Theme.of(Get.context!).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              // Reset to default
              localeService.update(const Locale('en', 'US'));
              currencyService.update('INR');
              Get.back();

              // Show success message
              Get.snackbar(
                'Success'.tr,
                'Settings reset to default'.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Theme.of(Get.context!).colorScheme.primary,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(Get.context!).colorScheme.error,
            ),
            child: Text('Reset'.tr),
          ),
        ],
      ),
    );
  }
}
