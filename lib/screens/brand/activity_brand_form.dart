import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../model/model_brand.dart';
import '../../util/snackbar_util.dart';
import '../../widget/app_dialog_components.dart';
import 'controller_brand_form.dart';

/// Returns null if valid, else an error message.
/// Accepts: optional leading '+', then exactly 10 digits (ignoring spaces/hyphens).
String? _validatePhone(String? value, {bool required = false}) {
  if (value == null || value.trim().isEmpty) {
    return required ? 'Phone number is required' : null;
  }
  final digits = value.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.length != 10) {
    return 'Phone number must be exactly 10 digits';
  }
  return null;
}

class ActivityBrandForm extends StatelessWidget {
  final ModelBrand? editingBrand;

  const ActivityBrandForm({super.key, this.editingBrand});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ControllerBrandForm(editingBrand: editingBrand),
    );
    final isEditing = editingBrand != null && editingBrand!.id != null;
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialog(
      maxWidth: 900,
      maxHeight: 760,
      header: DialogHeader(
        title: isEditing ? 'Edit Brand' : 'Create New Brand',
        icon: isEditing ? Icons.edit_note_rounded : Icons.storefront_rounded,
        iconColor: colorScheme.primary,
        actions: [
          Obx(() => TextButton.icon(
                onPressed: () {
                  controller.rxShowJsonPreview.value = !controller.rxShowJsonPreview.value;
                },
                icon: Icon(
                  controller.rxShowJsonPreview.value
                      ? Icons.code_off_rounded
                      : Icons.data_object_rounded,
                  size: 18,
                ),
                label: Text(
                  controller.rxShowJsonPreview.value ? 'Hide API Payload' : 'View API Payload',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: controller.rxShowJsonPreview.value
                      ? Colors.teal.shade700
                      : colorScheme.primary,
                ),
              )),
        ],
      ),
      body: DialogBody(
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Collapsible Live JSON Preview ───
              Obx(() {
                if (!controller.rxShowJsonPreview.value) {
                  return const SizedBox.shrink();
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.webhook_rounded, color: Colors.cyanAccent, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'LIVE API REQUEST PAYLOAD (POST /api/brands)',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 16),
                            tooltip: 'Copy JSON payload',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: controller.rxJsonPreview.value),
                              );
                              SnackbarUtil.showSuccess('JSON payload copied to clipboard');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        controller.rxJsonPreview.value,
                        style: const TextStyle(
                          color: Color(0xFFA6E22E),
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // ─── SECTION 1: Brand Identity & App Type ───
              FormSection(
                title: 'BRAND IDENTITY',
                icon: Icons.store_rounded,
                color: Colors.indigo.shade600,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand English Name
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      controller: controller.nameEnController,
                      label: 'Brand Name (English) *',
                      hint: 'e.g. Mumkin Restaurant BR',
                      required: true,
                      prefixIcon: Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // App Type Dropdown
                  Expanded(
                    flex: 2,
                    child: Obx(() => AppDropdown<String>(
                          value: controller.rxAppType.value,
                          label: 'App Type *',
                          prefixIcon: Icons.category_outlined,
                          items: ControllerBrandForm.appTypeOptions.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(
                                    type == 'MARKET'
                                        ? Icons.shopping_basket_rounded
                                        : type == 'RESTAURANT'
                                            ? Icons.restaurant_rounded
                                            : Icons.storefront_rounded,
                                    size: 16,
                                    color: type == 'MARKET'
                                        ? Colors.teal
                                        : type == 'RESTAURANT'
                                            ? Colors.deepOrange
                                            : Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(type),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) controller.rxAppType.value = val;
                          },
                        )),
                  ),
                  const SizedBox(width: 16),
                  // Status
                  Expanded(
                    flex: 2,
                    child: Obx(() => AppDropdown<String>(
                          value: controller.rxStatus.value,
                          label: 'Status *',
                          prefixIcon: Icons.toggle_on_outlined,
                          items: ControllerBrandForm.statusOptions.map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: status == 'ACTIVE' ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(status),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) controller.rxStatus.value = val;
                          },
                        )),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ─── SECTION 2: Registration & Tax Compliance ───
              FormSection(
                title: 'REGISTRATION & TAX DETAILS',
                icon: Icons.receipt_long_rounded,
                color: Colors.teal.shade700,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GST / VAT Number
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      controller: controller.gstNoController,
                      label: 'GST / VAT Number',
                      hint: 'e.g. 104099208100003',
                      prefixIcon: Icons.numbers_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // GST Type
                  Expanded(
                    flex: 2,
                    child: Obx(() => AppDropdown<String>(
                          value: controller.rxGstType.value,
                          label: 'Tax / GST Type',
                          prefixIcon: Icons.account_balance_outlined,
                          items: ControllerBrandForm.gstTypeOptions.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) controller.rxGstType.value = val;
                          },
                        )),
                  ),
                  const SizedBox(width: 16),
                  // GST Registration Date
                  Expanded(
                    flex: 2,
                    child: AppDatePicker(
                      controller: controller.gstRegistrationDateController,
                      label: 'GST Reg. Date',
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2050),
                        );
                        if (picked != null) {
                          controller.gstRegistrationDateController.text =
                              DateFormat('yyyy-MM-dd').format(picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FSSAI No
                  Expanded(
                    child: AppTextField(
                      controller: controller.fssaiNoController,
                      label: 'FSSAI License No',
                      hint: 'e.g. 11223344556677',
                      prefixIcon: Icons.verified_user_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // FSSAI Expiry Date
                  Expanded(
                    child: AppDatePicker(
                      controller: controller.fssaiExpiryDateController,
                      label: 'FSSAI Expiry Date',
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2050),
                        );
                        if (picked != null) {
                          controller.fssaiExpiryDateController.text =
                              DateFormat('yyyy-MM-dd').format(picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // CIN
                  Expanded(
                    child: AppTextField(
                      controller: controller.cinController,
                      label: 'CIN (Corporate ID)',
                      hint: 'e.g. U74999DL2026PTC123456',
                      prefixIcon: Icons.business_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ─── SECTION 3: Contact Details ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FormSection(
                      title: 'CONTACT INFORMATION',
                      icon: Icons.contact_phone_rounded,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: controller.copyPrimaryPhoneToWhatsapp,
                    icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.green),
                    label: const Text(
                      'Copy Primary to WhatsApp',
                      style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primary Phone
                  Expanded(
                    child: AppTextField(
                      controller: controller.phonePrimaryController,
                      label: 'Primary Phone * (10 digits)',
                      hint: 'e.g. 9715048470',
                      required: true,
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (v) => _validatePhone(v, required: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Alternate Phone
                  Expanded(
                    child: AppTextField(
                      controller: controller.phoneAlternateController,
                      label: 'Alternate Phone (10 digits)',
                      hint: 'e.g. 9715000000',
                      prefixIcon: Icons.phone_callback_rounded,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // WhatsApp Phone
                  Expanded(
                    child: AppTextField(
                      controller: controller.phoneWhatsappController,
                      label: 'WhatsApp Phone (10 digits)',
                      hint: 'e.g. 9715048470',
                      prefixIcon: Icons.chat_bubble_outline_rounded,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Email
                  Expanded(
                    child: AppTextField(
                      controller: controller.emailController,
                      label: 'Email Address',
                      hint: 'e.g. mumkin2023@gmail.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Website
                  Expanded(
                    child: AppTextField(
                      controller: controller.websiteController,
                      label: 'Website URL',
                      hint: 'e.g. https://www.mumkinrestaurant.com',
                      prefixIcon: Icons.language_rounded,
                      keyboardType: TextInputType.url,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      footer: Obx(() => DialogFooter(
            onCancel: () => Get.back(),
            onSave: controller.submit,
            saveLabel: isEditing ? 'Update Brand' : 'Create Brand',
            isSaving: controller.rxIsSaving.value,
            saveButtonColor: isEditing ? Colors.blue.shade700 : Colors.teal.shade700,
          )),
    );
  }
}
