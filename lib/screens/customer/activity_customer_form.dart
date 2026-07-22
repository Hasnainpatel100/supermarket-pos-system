import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/entity_customer.dart';
import '../../widget/app_dialog_components.dart';
import 'controller_customer_form.dart';

class ActivityCustomerForm extends StatelessWidget {
  const ActivityCustomerForm({super.key});

  @override
  Widget build(BuildContext context) {
    final EntityCustomer? editingCustomer = Get.arguments as EntityCustomer?;
    final controller = Get.put(
      ControllerCustomerForm(editingCustomer: editingCustomer),
    );
    final isEditing = editingCustomer != null;
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialog(
      maxWidth: 650,
      maxHeight: 700,
      header: DialogHeader(
        title: isEditing ? 'edit_customer'.tr : 'new_customer'.tr,
        icon: isEditing ? Icons.manage_accounts_rounded : Icons.person_add_rounded,
        iconColor: colorScheme.primary,
      ),
      body: DialogBody(
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// ── Basic Info Section ──
              FormSection(
                icon: Icons.person_outline_rounded,
                color: Colors.blue.shade600,
                title: 'basic_information'.tr,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: controller.nameController,
                label: 'customer_name'.tr,
                required: true,
                prefixIcon: Icons.person_rounded,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppNumberField(
                      controller: controller.phoneController,
                      label: 'phone_number'.tr,
                      prefixIcon: Icons.phone_rounded,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: controller.emailController,
                      label: 'email_address'.tr,
                      prefixIcon: Icons.email_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// ── Address Section ──
              FormSection(
                icon: Icons.location_on_outlined,
                color: Colors.green.shade600,
                title: 'address_details'.tr,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: controller.addressController,
                label: 'street_address'.tr,
                prefixIcon: Icons.home_rounded,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      controller: controller.cityController,
                      label: 'city'.tr,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: controller.stateController,
                      label: 'state'.tr,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppNumberField(
                      controller: controller.zipController,
                      label: 'zip_code'.tr,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// ── Notes Section ──
              FormSection(
                icon: Icons.note_alt_outlined,
                color: Colors.orange.shade700,
                title: 'additional_notes'.tr,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: controller.notesController,
                label: 'notes'.tr,
                maxLines: 3,
                prefixIcon: Icons.comment_rounded,
              ),

              const SizedBox(height: 24),

              /// ── VIP Section ──
              FormSection(
                icon: Icons.star_rounded,
                color: Colors.amber.shade700,
                title: 'vip_status'.tr,
              ),
              const SizedBox(height: 12),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: controller.rxIsVip.value
                        ? Colors.amber.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.rxIsVip.value
                          ? Colors.amber.shade300
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: controller.rxIsVip.value
                            ? Colors.amber.shade600
                            : Colors.grey.shade400,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'vip_customer'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: controller.rxIsVip.value
                                    ? Colors.amber.shade800
                                    : Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              controller.rxIsVip.value
                                  ? 'vip_privileges_active'.tr
                                  : 'mark_as_vip'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: controller.rxIsVip.value,
                        onChanged: (val) =>
                            controller.rxIsVip.value = val,
                        activeTrackColor: Colors.amber.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      footer: DialogFooter(
        onCancel: () => Get.back(),
        onSave: controller.saveCustomer,
        saveLabel: isEditing ? 'update_customer'.tr : 'save_customer'.tr,
      ),
    );
  }
}
