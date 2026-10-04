import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../model/model_branch.dart';
import '../../model/model_brand.dart';
import '../../widget/app_dialog_components.dart';
import '../../widget/dialog_plan_expiry.dart';
import '../../widget/dialog_renew_plan.dart';
import 'controller_branch_form.dart';

/// Returns null if valid, else an error message.
/// Enforces exactly 10 digits (ignoring any spaces or hyphens).
String? _validateBranchPhone(String? value, {bool required = false}) {
  if (value == null || value.trim().isEmpty) {
    return required ? 'Phone number is required' : null;
  }
  final digits = value.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.length != 10) {
    return 'Phone number must be exactly 10 digits';
  }
  return null;
}

class ActivityBranchForm extends StatelessWidget {
  final ModelBranch? editingBranch;
  const ActivityBranchForm({super.key, this.editingBranch});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ControllerBranchForm(editingBranch: editingBranch),
    );
    final isEditing = editingBranch != null && editingBranch!.id != null;
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialog(
      maxWidth: 960,
      maxHeight: 780,
      header: DialogHeader(
        title: isEditing ? 'Edit Branch' : 'Create New Branch',
        icon: isEditing
            ? Icons.edit_location_alt_rounded
            : Icons.add_business_rounded,
        iconColor: Colors.deepPurple.shade400,
      ),
      body: DialogBody(
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isEditing && editingBranch?.planDetails != null) ...[
                  _buildPlanSummaryBanner(context, editingBranch!),
                  const SizedBox(height: 20),
                ],

                // ─── Section 1: Branch Identity ───────────────────────────
                _buildSectionHeader(
                  context,
                  Icons.business_rounded,
                  'Branch Identity',
                  Colors.deepPurple.shade400,
                ),
                const SizedBox(height: 12),
                _buildBrandDropdown(controller, colorScheme),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: controller.tcBranchCode,
                        label: 'Branch Code *',
                        hint: 'e.g. BR001',
                        icon: Icons.tag_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Branch code is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _buildTextField(
                        controller: controller.tcName,
                        label: 'Branch Name (EN) *',
                        hint: 'e.g. Mumkin Main Branch',
                        icon: Icons.storefront_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Branch name is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Obx(
                        () => _buildDropdown(
                          label: 'App Type',
                          value: controller.rxAppType.value,
                          items: ControllerBranchForm.appTypeOptions,
                          onChanged: (v) => controller.rxAppType.value = v!,
                          colorScheme: colorScheme,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Obx(
                        () => _buildDropdown(
                          label: 'Status',
                          value: controller.rxStatus.value,
                          items: ControllerBranchForm.statusOptions,
                          onChanged: (v) => controller.rxStatus.value = v!,
                          colorScheme: colorScheme,
                          activeColor: controller.rxStatus.value == 'ACTIVE'
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── Section 2: Address ───────────────────────────────────
                _buildSectionHeader(
                  context,
                  Icons.location_on_rounded,
                  'Address',
                  Colors.blue.shade400,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.tcFullAddress,
                  label: 'Full Address',
                  hint: 'Street address, building, floor...',
                  icon: Icons.home_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: controller.tcCity,
                        label: 'City',
                        hint: 'e.g. Dubai',
                        icon: Icons.location_city_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: controller.tcState,
                        label: 'State / Emirate',
                        hint: 'e.g. Dubai',
                        icon: Icons.map_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: controller.tcCountry,
                        label: 'Country',
                        hint: 'e.g. UAE',
                        icon: Icons.flag_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: controller.tcZipCode,
                        label: 'ZIP / Postal Code',
                        hint: 'e.g. 00000',
                        icon: Icons.markunread_mailbox_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: controller.tcLatitude,
                        label: 'Latitude',
                        hint: 'e.g. 25.2048',
                        icon: Icons.gps_fixed_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: controller.tcLongitude,
                        label: 'Longitude',
                        hint: 'e.g. 55.2708',
                        icon: Icons.gps_fixed_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: controller.tcGMapUrl,
                        label: 'Google Maps URL',
                        hint: 'https://maps.google.com/...',
                        icon: Icons.directions_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: controller.tcGMapPlaceId,
                  label: 'Google Maps Place ID',
                  hint: 'e.g. ChIJN1t_tDeuEmsRUs...',
                  icon: Icons.place_rounded,
                ),

                const SizedBox(height: 24),

                // ─── Section 3: Contact ───────────────────────────────────
                _buildSectionHeader(
                  context,
                  Icons.contact_phone_rounded,
                  'Contact Info',
                  Colors.teal.shade400,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: controller.tcPrimaryPhone,
                        label: 'Primary Phone * (10 digits)',
                        hint: '9715048470',
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (v) => _validateBranchPhone(v, required: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: controller.tcAlternatePhone,
                        label: 'Alternate Phone (10 digits)',
                        hint: '9715048470',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => _validateBranchPhone(v, required: false),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: controller.tcWhatsapp,
                        label: 'WhatsApp (10 digits)',
                        hint: '9715048470',
                        icon: Icons.chat_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (v) => _validateBranchPhone(v, required: false),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        suffix: IconButton(
                          tooltip: 'Copy Primary to WhatsApp',
                          icon: Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: Colors.teal.shade600,
                          ),
                          onPressed: controller.copyPrimaryToWhatsapp,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: controller.tcEmail,
                        label: 'Email',
                        hint: 'branch@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── Section 4: Service Types ─────────────────────────────
                _buildSectionHeader(
                  context,
                  Icons.room_service_rounded,
                  'Service Types',
                  Colors.orange.shade600,
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: ModelBranch.allServiceTypes.map((type) {
                      final isSelected = controller.rxSelectedServiceTypes
                          .contains(type);
                      return FilterChip(
                        label: Text(
                          type.replaceAll('_', ' '),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : colorScheme.onSurface,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) => controller.toggleServiceType(type),
                        selectedColor: Colors.deepPurple.shade500,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        checkmarkColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      footer: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: Border(
            top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            Obx(
              () => FilledButton.icon(
                onPressed: controller.rxIsSubmitting.value
                    ? null
                    : controller.submitForm,
                icon: controller.rxIsSubmitting.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isEditing
                            ? Icons.save_rounded
                            : Icons.add_circle_rounded,
                        size: 18,
                      ),
                label: Text(
                  controller.rxIsSubmitting.value
                      ? (isEditing ? 'Saving...' : 'Creating...')
                      : (isEditing ? 'Save Changes' : 'Create Branch'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget Helpers ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: color.withValues(alpha: 0.2))),
      ],
    );
  }

  Widget _buildBrandDropdown(
    ControllerBranchForm controller,
    ColorScheme colorScheme,
  ) {
    return Obx(() {
      if (controller.rxIsLoadingBrands.value) {
        return const SizedBox(
          height: 56,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading brands...', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        );
      }

      final selectedBrand = controller.rxBrandList
          .where((b) => b.id == controller.rxSelectedBrand.value?.id)
          .firstOrNull;

      // Only brands with a valid 24-char server ObjectId can be used as brandId
      bool isServerSynced(ModelBrand b) {
        final id = b.id ?? '';
        return RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id) &&
            id != '000000000000000000000000';
      }

      return DropdownButtonFormField<ModelBrand>(
        value: selectedBrand,
        decoration: InputDecoration(
          labelText: 'Brand *',
          hintText: 'Select a Brand',
          prefixIcon: const Icon(Icons.branding_watermark_rounded, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        validator: (v) {
          if (v == null) return 'Please select a Brand';
          if (!isServerSynced(v)) {
            return 'This brand is not yet synced to the server. Please sync it first.';
          }
          return null;
        },
        items: controller.rxBrandList.map((brand) {
          final synced = isServerSynced(brand);
          return DropdownMenuItem(
            value: brand,
            enabled: synced, // Disable unsynced (local-only) brands
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: brand.isActive ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  brand.name.en,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: synced ? null : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    brand.appType,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!synced) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Not synced to server — sync brand first',
                    child: Icon(
                      Icons.cloud_off_rounded,
                      size: 14,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        onChanged: (brand) => controller.rxSelectedBrand.value = brand,
      );
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required ColorScheme colorScheme,
    Color? activeColor,
  }) {
    // Case-insensitive match against allowed items to prevent Flutter DropdownButton AssertionError
    final normalizedValue = items.firstWhere(
      (item) => item.toUpperCase() == value.toUpperCase(),
      orElse: () => items.first,
    );

    return DropdownButtonFormField<String>(
      value: normalizedValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPlanSummaryBanner(BuildContext context, ModelBranch branch) {
    final plan = branch.planDetails!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusColor = plan.isExpired
        ? const Color(0xFFEF4444)
        : plan.isExpiringSoon
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.card_membership_rounded, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Subscription Plan: ${plan.note.isNotEmpty ? plan.note : "Active Plan"}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: statusColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  plan.expiryStatusText.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Expires: ${plan.formattedExpiry} • Users: ${plan.maxUsers} • POS Terminals: ${plan.maxPosDevices}',
                style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => DialogPlanExpiry.showHistory(context, branch: branch),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.history_edu_rounded, size: 14),
                label: const Text('Plan History', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 6),
              FilledButton.icon(
                onPressed: () => DialogRenewPlan.show(context, branch: branch),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: statusColor,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.autorenew_rounded, size: 14),
                label: const Text('Renew Plan', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
