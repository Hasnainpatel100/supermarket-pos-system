import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/screens/user/controller_user.dart';

import '../../util/constant.dart';
import '../../util/my_row_expanded_two.dart';
import '../../util/vertical_space.dart';
import '../../widget/my_card_with_header.dart';
import '../../widget/my_check_box.dart';
import '../../widget/my_date_picker.dart';
import '../../widget/my_drop_down.dart';
import '../../widget/my_text_field.dart';

class ActivityUser extends GetView<ControllerUser> {
  const ActivityUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.entityUser == null ? 'user_create'.tr : 'user_update'.tr,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Form(
                  key: controller.formKey,
                  child: _buildForm(controller),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () => controller.saveUser(),
              style: ElevatedButton.styleFrom(minimumSize: const Size(120, 45)),
              child: Text(
                controller.entityUser == null ? 'save'.tr : 'update'.tr,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ControllerUser controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MyCardWithHeader(
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
        VerticalSpace(),
        MyCardWithHeader(
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
        VerticalSpace(),
        MyCardWithHeader(
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
        VerticalSpace(),
        MyCardWithHeader(
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
            right: Obx(() => MyCheckBox(isActive: controller.rxIsActive)),
          ),
        ),
      ],
    );
  }
}
