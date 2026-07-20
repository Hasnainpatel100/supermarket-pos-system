import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/entity_customer.dart';
import '../../widget/my_text_field.dart';
import 'controller_customer_form.dart';

class ActivityCustomerForm extends StatelessWidget {
  const ActivityCustomerForm({super.key});

  @override
  Widget build(BuildContext context) {
    final EntityCustomer? editingCustomer = Get.arguments as EntityCustomer?;
    final controller = Get.put(
      ControllerCustomerForm(editingCustomer: editingCustomer),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = editingCustomer != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Icon(
              isEditing
                  ? Icons.manage_accounts_rounded
                  : Icons.person_add_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              isEditing ? 'edit_customer'.tr : 'new_customer'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Center(
        child: SizedBox(
          width: 600,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: controller.formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      /// ── Basic Info Section ──
                      _FormSectionHeader(
                        icon: Icons.person_outline_rounded,
                        color: Colors.blue.shade600,
                        title: 'basic_information'.tr,
                      ),
                      const SizedBox(height: 16),
                      MyTextField(
                        controller: controller.nameController,
                        label: 'customer_name'.tr,
                        required: true,
                        prefixIcon: Icons.person_rounded,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: MyTextField(
                              controller: controller.phoneController,
                              label: 'phone_number'.tr,
                              prefixIcon: Icons.phone_rounded,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MyTextField(
                              controller: controller.emailController,
                              label: 'email_address'.tr,
                              prefixIcon: Icons.email_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      /// ── Address Section ──
                      _FormSectionHeader(
                        icon: Icons.location_on_outlined,
                        color: Colors.green.shade600,
                        title: 'address_details'.tr,
                      ),
                      const SizedBox(height: 16),
                      MyTextField(
                        controller: controller.addressController,
                        label: 'street_address'.tr,
                        prefixIcon: Icons.home_rounded,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: MyTextField(
                              controller: controller.cityController,
                              label: 'city'.tr,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MyTextField(
                              controller: controller.stateController,
                              label: 'state'.tr,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MyTextField(
                              controller: controller.zipController,
                              label: 'zip_code'.tr,
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      /// ── Notes Section ──
                      _FormSectionHeader(
                        icon: Icons.note_alt_outlined,
                        color: Colors.orange.shade600,
                        title: 'additional_notes'.tr,
                      ),
                      const SizedBox(height: 16),
                      MyTextField(
                        controller: controller.notesController,
                        label: 'notes'.tr,
                        maxLines: 3,
                        prefixIcon: Icons.comment_rounded,
                      ),

                      const SizedBox(height: 24),

                      /// ── VIP Section ──
                      _FormSectionHeader(
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

                      const SizedBox(height: 32),

                      /// ── Action Buttons ──
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => Get.back(),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                            ),
                            label: Text('back'.tr),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(
                                color: colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: controller.saveCustomer,
                            icon: Icon(
                              isEditing
                                  ? Icons.check_rounded
                                  : Icons.save_rounded,
                              size: 18,
                            ),
                            label: Text(
                              isEditing ? 'update_customer'.tr : 'save_customer'.tr,
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormSectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  const _FormSectionHeader({
    required this.icon,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(height: 1, color: color.withValues(alpha: 0.2)),
        ),
      ],
    );
  }
}
