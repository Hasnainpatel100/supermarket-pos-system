import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/entity_user.dart';
import '../../objectbox.g.dart';
import '../../service/service_object_box.dart';

class ControllerUser extends GetxController {
  EntityUser? entityUser;

  final formKey = GlobalKey<FormState>();
  final textEditingControllerFirstName = TextEditingController();
  final textEditingControllerLastName = TextEditingController();
  final textEditingControllerDob = TextEditingController();
  final textEditingControllerUserName = TextEditingController();
  final textEditingControllerPassword = TextEditingController();
  final textEditingControllerMobileNumber = TextEditingController();
  final textEditingControllerAlternateMobile = TextEditingController();
  final textEditingControllerIdProofNumber = TextEditingController();
  final textEditingControllerAddress = TextEditingController();

  var isPasswordHidden = true.obs;

  final rxGender = RxnString();
  final rxRole = RxnString();
  final rsListProofType = RxnString();
  final rxIsActive = true.obs;

  late Box<EntityUser> _boxUser;

  @override
  void onInit() {
    // Standard GetX: Pull arguments from the route
    entityUser = Get.arguments as EntityUser?;
    debugPrint("ControllerUser onInit: entityUser=$entityUser");

    final ob = Get.find<ServiceObjectBox>();
    _boxUser = ob.box<EntityUser>();

    displayPreData();
    super.onInit();
  }

  void saveUser() {
    if (!formKey.currentState!.validate()) return;

    if (entityUser == null) {
      final user = EntityUser()
        ..mobileNumber = textEditingControllerMobileNumber.text.trim()
        ..alternateMobile = textEditingControllerAlternateMobile.text.trim()
        ..idProofType = rsListProofType.value
        ..idProofNumber = textEditingControllerIdProofNumber.text.trim()
        ..address = textEditingControllerAddress.text.trim()
        ..mongoId = null
        ..first = textEditingControllerFirstName.text.trim()
        ..last = textEditingControllerLastName.text.trim()
        ..dob = textEditingControllerDob.text
        ..gender = rxGender.value
        ..username = textEditingControllerUserName.text.trim()
        ..password = textEditingControllerPassword.text
        ..role = rxRole.value
        ..isActive = rxIsActive.value
        ..permissions = []
        ..isSync = false;

      _boxUser.put(user);
      Get.back(result: user);
    } else {
      entityUser!.username = textEditingControllerUserName.text.trim();
      entityUser!.password = textEditingControllerPassword.text;
      entityUser!.first = textEditingControllerFirstName.text.trim();
      entityUser!.last = textEditingControllerLastName.text.trim();
      entityUser!.dob = textEditingControllerDob.text;
      entityUser!.gender = rxGender.value;
      entityUser!.role = rxRole.value;
      entityUser!.isActive = rxIsActive.value;
      entityUser!.address = textEditingControllerAddress.text.trim();
      entityUser!.mobileNumber = textEditingControllerMobileNumber.text.trim();
      entityUser!.alternateMobile = textEditingControllerAlternateMobile.text
          .trim();
      entityUser!.idProofType = rsListProofType.value;
      entityUser!.idProofNumber = textEditingControllerIdProofNumber.text
          .trim();

      _boxUser.put(entityUser!);
      Get.back(result: entityUser!);
    }
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void displayPreData() {
    if (entityUser != null) {
      textEditingControllerFirstName.text = entityUser!.first ?? "";
      textEditingControllerLastName.text = entityUser!.last ?? "";
      textEditingControllerDob.text = entityUser!.dob ?? "";
      textEditingControllerUserName.text = entityUser!.username ?? "";
      textEditingControllerPassword.text = entityUser!.password ?? "";
      textEditingControllerMobileNumber.text = entityUser!.mobileNumber ?? "";
      textEditingControllerAlternateMobile.text =
          entityUser!.alternateMobile ?? "";
      textEditingControllerIdProofNumber.text = entityUser!.idProofNumber ?? "";
      textEditingControllerAddress.text = entityUser!.address ?? "";

      rxGender.value = entityUser!.gender;
      rxRole.value = entityUser!.role;
      rsListProofType.value = entityUser!.idProofType;
      rxIsActive.value = entityUser!.isActive ?? true;
    }
  }
}
