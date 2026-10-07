import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/screens/user/controller_user.dart';

import '../../util/constant.dart';
import '../../util/my_row_expanded_two.dart';
import '../../widget/my_check_box.dart';
import '../../widget/my_date_picker.dart';
import '../../widget/my_drop_down.dart';
import '../../widget/my_text_field.dart';

class ActivityUser extends StatelessWidget {
  const ActivityUser({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerUser controller = Get.put(ControllerUser());
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = controller.entityUser != null;

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
                  ? Icons.person_outline_rounded
                  : Icons.person_add_alt_1_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              isEditing ? 'user_update'.tr : 'user_create'.tr,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Form(
                  key: controller.formKey,
                  child: _buildForm(context, controller),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text('cancel'.tr),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => controller.saveUser(),
              icon: Icon(
                isEditing ? Icons.check_rounded : Icons.save_rounded,
                size: 18,
              ),
              label: Text(isEditing ? 'update'.tr : 'save'.tr),
              style: FilledButton.styleFrom(
                minimumSize: const Size(130, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, ControllerUser controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// ── Personal Information ──
        _SectionCard(
          icon: Icons.person_outlined,
          iconColor: Colors.blue.shade600,
          title: "personal_information".tr,
          child: Column(
            children: [
              MyRowExpandedTwo(
                left: MyTextField(
                  controller: controller.textEditingControllerFirstName,
                  label: "first_name".tr,
                  required: true,
                ),
                right: MyTextField(
                  controller: controller.textEditingControllerLastName,
                  label: "last_name".tr,
                ),
              ),
              const SizedBox(height: 16),
              MyRowExpandedTwo(
                left: MyDatePicker(
                  controller: controller.textEditingControllerDob,
                  label: "dob".tr,
                ),
                right: Obx(
                  () => MyDropDown(
                    label: "gender".tr,
                    value: controller.rxGender.value,
                    items: Constant.listGender,
                    onChanged: (v) => controller.rxGender.value = v,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        /// ── Contact & Identity ──
        _SectionCard(
          icon: Icons.contact_phone_outlined,
          iconColor: Colors.teal.shade600,
          title: "Contact & Identity",
          child: Column(
            children: [
              MyRowExpandedTwo(
                left: MyTextField(
                  controller: controller.textEditingControllerMobileNumber,
                  label: "mobile".tr,
                  required: true,
                  isNumber: true,
                ),
                right: MyTextField(
                  controller: controller.textEditingControllerAlternateMobile,
                  label: "alternate_mobile".tr,
                  isNumber: true,
                ),
              ),
              const SizedBox(height: 16),
              MyRowExpandedTwo(
                left: Obx(
                  () => MyDropDown(
                    label: "id_proof_type".tr,
                    value: controller.rsListProofType.value,
                    items: Constant.listProofType,
                    onChanged: (v) => controller.rsListProofType.value = v,
                  ),
                ),
                right: MyTextField(
                  controller: controller.textEditingControllerIdProofNumber,
                  label: "id_proof_number".tr,
                  required: true,
                ),
              ),
              const SizedBox(height: 16),
              MyTextField(
                controller: controller.textEditingControllerAddress,
                label: "address".tr,
                required: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        /// ── Login & Security ──
        _SectionCard(
          icon: Icons.lock_outline_rounded,
          iconColor: Colors.orange.shade700,
          title: "login_&_security".tr,
          child: MyRowExpandedTwo(
            left: MyTextField(
              controller: controller.textEditingControllerUserName,
              label: "username".tr,
              required: true,
            ),
            right: MyTextField(
              controller: controller.textEditingControllerPassword,
              label: "password".tr,
              required: true,
              obscure: true,
            ),
          ),
        ),
        const SizedBox(height: 16),

        /// ── Role & Status ──
        _SectionCard(
          icon: Icons.admin_panel_settings_outlined,
          iconColor: Colors.deepPurple.shade500,
          title: "role_&_status".tr,
          child: MyRowExpandedTwo(
            left: Obx(
              () => MyDropDown(
                label: "role".tr,
                value: controller.rxRole.value,
                items: Constant.listUserRole,
                onChanged: (v) => controller.rxRole.value = v,
              ),
            ),
            right: MyCheckBox(isActive: controller.rxIsActive),
          ),
        ),
      ],
    );
  }
}

/// ── Beautiful Section Card ──
/// A card with a colored icon + title header and content body.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// Content
            child,
          ],
        ),
      ),
    );
  }
}
