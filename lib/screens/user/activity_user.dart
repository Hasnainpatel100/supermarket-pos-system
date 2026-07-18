import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/screens/user/controller_user.dart';
import '../../util/constant.dart';
import '../../widget/app_dialog_components.dart';

class ActivityUser extends StatelessWidget {
  const ActivityUser({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerUser controller = Get.put(ControllerUser());
    final isEditing = controller.entityUser != null;

    return AppDialog(
      maxWidth: 900,
      maxHeight: 750,
      header: DialogHeader(
        title: isEditing ? 'user_update'.tr : 'user_create'.tr,
        icon: isEditing ? Icons.person_outline_rounded : Icons.person_add_alt_1_rounded,
      ),
      body: DialogBody(
        child: Form(
          key: controller.formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// ── Personal Information ──
                  const FormSection(
                    icon: Icons.person_outlined,
                    color: Colors.blue,
                    title: "Personal Information",
                  ),
                  const SizedBox(height: 16),
                  if (isWide) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: controller.textEditingControllerFirstName,
                            label: "first_name".tr,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: controller.textEditingControllerLastName,
                            label: "last_name".tr,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppDatePicker(
                            controller: controller.textEditingControllerDob,
                            label: "dob".tr,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                controller.textEditingControllerDob.text =
                                    picked.toString().split(' ').first;
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(
                            () => AppDropdown<String>(
                              label: "gender".tr,
                              value: controller.rxGender.value,
                              items: Constant.listGender.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (v) => controller.rxGender.value = v,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    AppTextField(
                      controller: controller.textEditingControllerFirstName,
                      label: "first_name".tr,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: controller.textEditingControllerLastName,
                      label: "last_name".tr,
                    ),
                    const SizedBox(height: 16),
                    AppDatePicker(
                      controller: controller.textEditingControllerDob,
                      label: "dob".tr,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          controller.textEditingControllerDob.text =
                              picked.toString().split(' ').first;
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => AppDropdown<String>(
                        label: "gender".tr,
                        value: controller.rxGender.value,
                        items: Constant.listGender.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) => controller.rxGender.value = v,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  /// ── Contact & Identity ──
                  const FormSection(
                    icon: Icons.contact_phone_outlined,
                    color: Colors.teal,
                    title: "Contact & Identity",
                  ),
                  const SizedBox(height: 16),
                  if (isWide) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppNumberField(
                            controller: controller.textEditingControllerMobileNumber,
                            label: "mobile".tr,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppNumberField(
                            controller: controller.textEditingControllerAlternateMobile,
                            label: "alternate_mobile".tr,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Obx(
                            () => AppDropdown<String>(
                              label: "id_proof_type".tr,
                              value: controller.rsListProofType.value,
                              items: Constant.listProofType.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: (v) => controller.rsListProofType.value = v,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: controller.textEditingControllerIdProofNumber,
                            label: "id_proof_number".tr,
                            required: true,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    AppNumberField(
                      controller: controller.textEditingControllerMobileNumber,
                      label: "mobile".tr,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    AppNumberField(
                      controller: controller.textEditingControllerAlternateMobile,
                      label: "alternate_mobile".tr,
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => AppDropdown<String>(
                        label: "id_proof_type".tr,
                        value: controller.rsListProofType.value,
                        items: Constant.listProofType.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (v) => controller.rsListProofType.value = v,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: controller.textEditingControllerIdProofNumber,
                      label: "id_proof_number".tr,
                      required: true,
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: controller.textEditingControllerAddress,
                    label: "address".tr,
                    required: true,
                  ),

                  const SizedBox(height: 24),

                  /// ── Login & Security ──
                  const FormSection(
                    icon: Icons.lock_outline_rounded,
                    color: Colors.orange,
                    title: "Login & Security",
                  ),
                  const SizedBox(height: 16),
                  if (isWide) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: controller.textEditingControllerUserName,
                            label: "username".tr,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(
                            () => AppTextField(
                              controller: controller.textEditingControllerPassword,
                              label: "password".tr,
                              required: true,
                              obscure: controller.isPasswordHidden.value,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.isPasswordHidden.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: controller.togglePasswordVisibility,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    AppTextField(
                      controller: controller.textEditingControllerUserName,
                      label: "username".tr,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => AppTextField(
                        controller: controller.textEditingControllerPassword,
                        label: "password".tr,
                        required: true,
                        obscure: controller.isPasswordHidden.value,
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isPasswordHidden.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  /// ── Role & Status ──
                  const FormSection(
                    icon: Icons.admin_panel_settings_outlined,
                    color: Colors.deepPurple,
                    title: "Role & Status",
                  ),
                  const SizedBox(height: 16),
                  if (isWide) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Obx(
                            () => AppDropdown<String>(
                              label: "role".tr,
                              value: controller.rxRole.value,
                              items: Constant.listUserRole.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                              onChanged: (v) => controller.rxRole.value = v,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Obx(
                          () => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: controller.rxIsActive.value,
                                onChanged: (v) {
                                  if (v != null) controller.rxIsActive.value = v;
                                },
                              ),
                              const SizedBox(width: 8),
                              Text("active".tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ] else ...[
                    Obx(
                      () => AppDropdown<String>(
                        label: "role".tr,
                        value: controller.rxRole.value,
                        items: Constant.listUserRole.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (v) => controller.rxRole.value = v,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => Row(
                        children: [
                          Checkbox(
                            value: controller.rxIsActive.value,
                            onChanged: (v) {
                              if (v != null) controller.rxIsActive.value = v;
                            },
                          ),
                          const SizedBox(width: 8),
                          Text("active".tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      footer: DialogFooter(
        onCancel: () => Get.back(),
        onSave: controller.saveUser,
        saveLabel: isEditing ? 'update'.tr : 'save'.tr,
      ),
    );
  }
}
