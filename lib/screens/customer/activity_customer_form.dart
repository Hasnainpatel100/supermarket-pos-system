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

    return AppDialog(
      maxWidth: 700,
      maxHeight: 700,
      header: DialogHeader(
        title: isEditing ? 'Edit Customer' : 'New Customer',
        icon: isEditing ? Icons.manage_accounts_rounded : Icons.person_add_rounded,
      ),
      body: DialogBody(
        child: Form(
          key: controller.formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 550;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// ── Basic Info Section ──
                  const FormSection(
                    icon: Icons.person_outline_rounded,
                    color: Colors.blue,
                    title: 'Basic Information',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: controller.nameController,
                    label: "Customer Name",
                    required: true,
                    prefixIcon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 16),

                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppNumberField(
                            controller: controller.phoneController,
                            label: "Phone Number",
                            prefixIcon: Icons.phone_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: controller.emailController,
                            label: "Email Address",
                            prefixIcon: Icons.email_rounded,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    AppNumberField(
                      controller: controller.phoneController,
                      label: "Phone Number",
                      prefixIcon: Icons.phone_rounded,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: controller.emailController,
                      label: "Email Address",
                      prefixIcon: Icons.email_rounded,
                    ),
                  ],

                  const SizedBox(height: 24),

                  /// ── Address Section ──
                  const FormSection(
                    icon: Icons.location_on_outlined,
                    color: Colors.green,
                    title: 'Address Details',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: controller.addressController,
                    label: "Street Address",
                    prefixIcon: Icons.home_rounded,
                  ),
                  const SizedBox(height: 16),

                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppTextField(
                            controller: controller.cityController,
                            label: "City",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: controller.stateController,
                            label: "State",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppNumberField(
                            controller: controller.zipController,
                            label: "Zip Code",
                          ),
                        ),
                      ],
                    )
                  else ...[
                    AppTextField(
                      controller: controller.cityController,
                      label: "City",
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: controller.stateController,
                      label: "State",
                    ),
                    const SizedBox(height: 16),
                    AppNumberField(
                      controller: controller.zipController,
                      label: "Zip Code",
                    ),
                  ],

                  const SizedBox(height: 24),

                  /// ── Notes Section ──
                  const FormSection(
                    icon: Icons.note_alt_outlined,
                    color: Colors.orange,
                    title: 'Additional Notes',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: controller.notesController,
                    label: "Notes",
                    maxLines: 3,
                    prefixIcon: Icons.comment_rounded,
                  ),

                  const SizedBox(height: 24),

                  /// ── VIP Section ──
                  const FormSection(
                    icon: Icons.star_rounded,
                    color: Colors.amber,
                    title: 'VIP Status',
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
                            ? Colors.amber.withOpacity(0.08)
                            : Colors.grey.withOpacity(0.04),
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
                                  'VIP Customer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: controller.rxIsVip.value
                                        ? Colors.amber.shade800
                                        : Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  controller.rxIsVip.value
                                      ? 'This customer has VIP privileges'
                                      : 'Mark as VIP for special treatment',
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
              );
            },
          ),
        ),
      ),
      footer: DialogFooter(
        onCancel: () => Get.back(),
        onSave: controller.saveCustomer,
        saveLabel: isEditing ? "Update Customer" : "Save Customer",
      ),
    );
  }
}
