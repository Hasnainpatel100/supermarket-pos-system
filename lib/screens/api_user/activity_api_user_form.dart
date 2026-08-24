import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller_api_user_form.dart';

class ActivityApiUserForm extends StatelessWidget {
  const ActivityApiUserForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerApiUserForm());
    final colorScheme = Theme.of(context).colorScheme;
    final isEdit = controller.editingUser != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 750,
        constraints: const BoxConstraints(maxHeight: 750),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEdit
                          ? Icons.edit_note_rounded
                          : Icons.person_add_alt_1_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit API User' : 'Create API User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isEdit
                            ? 'Update details for user ${controller.editingUser?.username}'
                            : 'Create a new backend API user (POST /api/users/create)',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Form Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Basic Information
                      _sectionTitle(
                        context,
                        'Basic Information',
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller.textControllerFirstName,
                              decoration: const InputDecoration(
                                labelText: 'First Name *',
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'First name is required';
                                if (v.trim().length < 2) return 'Minimum 2 characters';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: controller.textControllerLastName,
                              decoration: const InputDecoration(
                                labelText: 'Last Name *',
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Last name is required';
                                if (v.trim().length < 2) return 'Minimum 2 characters';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Section 2: Account & Security
                      _sectionTitle(
                        context,
                        'Account & Security',
                        Icons.security_rounded,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller.textControllerUsername,
                              decoration: const InputDecoration(
                                labelText: 'Username *',
                                prefixIcon: Icon(
                                  Icons.alternate_email_rounded,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Username is required';
                                if (v.trim().length < 3) return 'Minimum 3 characters';
                                if (v.contains(' ')) return 'No spaces allowed';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Obx(
                              () => TextFormField(
                                controller: controller.textControllerLoginPin,
                                obscureText:
                                    controller.rxIsPasswordHidden.value,
                                decoration: InputDecoration(
                                  labelText: 'Login PIN / Password *',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      controller.rxIsPasswordHidden.value
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        controller.rxIsPasswordHidden.value =
                                            !controller
                                                .rxIsPasswordHidden
                                                .value,
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'PIN / Password is required';
                                  if (v.trim().length < 6) return 'Minimum 6 characters/digits';
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Section 3: Contact Information
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller.textControllerEmail,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email *',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Email is required';
                                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: controller.textControllerPhone,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number *',
                                prefixIcon: Icon(
                                  Icons.phone_outlined,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Phone number is required';
                                final phoneRegex = RegExp(r'^\+?[0-9\s\-]{8,15}$');
                                if (!phoneRegex.hasMatch(v.trim())) return 'Enter a valid phone number (8-15 digits)';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 4: Role & Hierarchy
                      _sectionTitle(
                        context,
                        'Type & Role Assignment',
                        Icons.hub_outlined,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Obx(
                              () => DropdownButtonFormField<String>(
                                value: controller.rxUserType.value,
                                decoration: const InputDecoration(
                                  labelText: 'User Type *',
                                  prefixIcon: Icon(
                                    Icons.storefront_outlined,
                                    size: 20,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                items: ControllerApiUserForm.availableUserTypes
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null)
                                    controller.rxUserType.value = v;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Obx(
                              () => DropdownButtonFormField<String>(
                                value: controller.rxRole.value,
                                decoration: const InputDecoration(
                                  labelText: 'Role *',
                                  prefixIcon: Icon(
                                    Icons.admin_panel_settings_outlined,
                                    size: 20,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                items: ControllerApiUserForm.availableRoles
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(r),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) controller.rxRole.value = v;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Brand & Branch IDs
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller.textControllerBrandId,
                              decoration: const InputDecoration(
                                labelText: 'Brand ID',
                                prefixIcon: Icon(
                                  Icons.branding_watermark_outlined,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(),
                                helperText: 'Default: 000000000000000000000000',
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: controller.textControllerBranchId,
                              decoration: const InputDecoration(
                                labelText: 'Branch ID',
                                prefixIcon: Icon(
                                  Icons.add_business_outlined,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(),
                                helperText: 'Default: 000000000000000000000000',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 5: Permissions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionTitle(
                            context,
                            'Permissions',
                            Icons.rule_folder_outlined,
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: controller.selectAllPermissions,
                                icon: const Icon(
                                  Icons.done_all_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Select All',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: controller.clearAllPermissions,
                                icon: const Icon(
                                  Icons.clear_all_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Clear All',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Multi-select Chips
                      Obx(
                        () => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ControllerApiUserForm
                              .defaultPresetPermissions
                              .map((perm) {
                                final isSelected = controller.rxPermissions
                                    .contains(perm);
                                return FilterChip(
                                  selected: isSelected,
                                  label: Text(
                                    perm,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  selectedColor: colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  checkmarkColor: colorScheme.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : Colors.grey.shade700,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  onSelected: (_) =>
                                      controller.togglePermission(perm),
                                );
                              })
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Custom permission add input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller:
                                  controller.textControllerCustomPermission,
                              decoration: const InputDecoration(
                                hintText:
                                    'Add custom permission (e.g. CUSTOM_ACTION)',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) =>
                                  controller.addCustomPermission(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: controller.addCustomPermission,
                            icon: const Icon(Icons.add_rounded),
                            tooltip: 'Add Permission',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 24),

              // Actions Footer
              Row(
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
                          : controller.saveUser,
                      icon: controller.rxIsSubmitting.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        isEdit ? 'Update API User' : 'Create API User',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
