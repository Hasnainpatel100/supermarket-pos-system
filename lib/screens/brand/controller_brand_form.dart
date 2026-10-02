import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/model_brand.dart';
import '../../repository/repo_brand.dart';
import '../../util/snackbar_util.dart';

class ControllerBrandForm extends GetxController {
  final ModelBrand? editingBrand;
  final RepoBrand _repo = Get.find<RepoBrand>();

  ControllerBrandForm({this.editingBrand});

  final formKey = GlobalKey<FormState>();

  // ─── Identity ───
  final nameEnController = TextEditingController();
  final rxAppType = 'MARKET'.obs;
  final rxStatus = 'ACTIVE'.obs;

  // ─── Registration ───
  final gstNoController = TextEditingController();
  final rxGstType = 'VAT'.obs;
  final gstRegistrationDateController = TextEditingController();
  final fssaiNoController = TextEditingController();
  final fssaiExpiryDateController = TextEditingController();
  final cinController = TextEditingController();

  // ─── Contact ───
  final phonePrimaryController = TextEditingController();
  final phoneAlternateController = TextEditingController();
  final phoneWhatsappController = TextEditingController();
  final emailController = TextEditingController();
  final websiteController = TextEditingController();

  // ─── Observables ───
  final rxIsSaving = false.obs;
  final rxShowJsonPreview = false.obs;
  final rxJsonPreview = ''.obs;

  static const List<String> appTypeOptions = ['MARKET', 'RESTAURANT'];
  static const List<String> gstTypeOptions = ['VAT', 'GST', 'NON_GST', 'COMPOSITION', 'EXEMPTED'];
  static const List<String> statusOptions = ['ACTIVE', 'INACTIVE'];

  @override
  void onInit() {
    super.onInit();
    _populateFields();
    _setupChangeListeners();
    _updateJsonPreview();
  }

  void _populateFields() {
    if (editingBrand != null) {
      final b = editingBrand!;
      nameEnController.text = b.name.en;
      final upperAppType = b.appType.toUpperCase();
      rxAppType.value = appTypeOptions.contains(upperAppType) ? upperAppType : 'MARKET';
      final upperStatus = b.status.toUpperCase();
      rxStatus.value = statusOptions.contains(upperStatus) ? upperStatus : 'ACTIVE';

      gstNoController.text = b.registration.gstNo;
      final upperGstType = b.registration.gstType.toUpperCase();
      rxGstType.value = gstTypeOptions.contains(upperGstType) ? upperGstType : 'VAT';
      gstRegistrationDateController.text = b.registration.gstRegistrationDate;
      fssaiNoController.text = b.registration.fssaiNo;
      fssaiExpiryDateController.text = b.registration.fssaiExpiryDate;
      cinController.text = b.registration.cin;

      phonePrimaryController.text = b.contact.phones.primary;
      phoneAlternateController.text = b.contact.phones.alternate;
      phoneWhatsappController.text = b.contact.phones.whatsapp;
      emailController.text = b.contact.email;
      websiteController.text = b.contact.website;
    } else {
      // Default initial state
      rxAppType.value = 'MARKET';
      rxStatus.value = 'ACTIVE';
      rxGstType.value = 'VAT';
    }
  }

  void _setupChangeListeners() {
    final controllers = [
      nameEnController,
      gstNoController,
      gstRegistrationDateController,
      fssaiNoController,
      fssaiExpiryDateController,
      cinController,
      phonePrimaryController,
      phoneAlternateController,
      phoneWhatsappController,
      emailController,
      websiteController,
    ];

    for (var c in controllers) {
      c.addListener(_updateJsonPreview);
    }
    ever(rxAppType, (_) => _updateJsonPreview());
    ever(rxStatus, (_) => _updateJsonPreview());
    ever(rxGstType, (_) => _updateJsonPreview());
  }

  void _updateJsonPreview() {
    final brand = buildBrandModel();
    const encoder = JsonEncoder.withIndent('  ');
    rxJsonPreview.value = encoder.convert(brand.toJson());
  }

  void copyPrimaryPhoneToWhatsapp() {
    phoneWhatsappController.text = phonePrimaryController.text.trim();
    _updateJsonPreview();
  }

  ModelBrand buildBrandModel() {
    return ModelBrand(
      id: editingBrand?.id,
      name: BrandName(
        en: nameEnController.text.trim(),
      ),
      registration: BrandRegistration(
        gstNo: gstNoController.text.trim(),
        gstType: rxGstType.value,
        gstRegistrationDate: gstRegistrationDateController.text.trim(),
        fssaiNo: fssaiNoController.text.trim(),
        fssaiExpiryDate: fssaiExpiryDateController.text.trim(),
        cin: cinController.text.trim(),
      ),
      contact: BrandContact(
        phones: BrandPhones(
          primary: phonePrimaryController.text.trim(),
          alternate: phoneAlternateController.text.trim(),
          whatsapp: phoneWhatsappController.text.trim(),
        ),
        email: emailController.text.trim(),
        website: websiteController.text.trim(),
      ),
      appType: rxAppType.value,
      status: rxStatus.value,
    );
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      SnackbarUtil.showError('Please correct the highlighted form errors');
      return;
    }

    rxIsSaving.value = true;

    final brand = buildBrandModel();
    try {
      if (editingBrand != null && editingBrand!.id != null && editingBrand!.id!.isNotEmpty) {
        final (updatedBrand, success, message) = await _repo.updateBrand(
          editingBrand!.id!,
          brand,
        );
        rxIsSaving.value = false;
        if (success) {
          SnackbarUtil.showSuccess('Brand "${updatedBrand?.name.en ?? ''}" updated successfully');
          Get.back(result: updatedBrand);
        } else {
          SnackbarUtil.showWarning(message);
          Get.back(result: updatedBrand);
        }
      } else {
        final (createdBrand, success, message) = await _repo.createBrand(brand);
        rxIsSaving.value = false;
        if (success) {
          SnackbarUtil.showSuccess('Brand "${createdBrand?.name.en ?? ''}" created successfully');
          Get.back(result: createdBrand);
        } else {
          SnackbarUtil.showWarning(message);
          Get.back(result: createdBrand);
        }
      }
    } catch (e) {
      rxIsSaving.value = false;
      SnackbarUtil.showError('Failed to save brand: $e');
    }
  }

  @override
  void onClose() {
    nameEnController.dispose();
    gstNoController.dispose();
    gstRegistrationDateController.dispose();
    fssaiNoController.dispose();
    fssaiExpiryDateController.dispose();
    cinController.dispose();
    phonePrimaryController.dispose();
    phoneAlternateController.dispose();
    phoneWhatsappController.dispose();
    emailController.dispose();
    websiteController.dispose();
    super.onClose();
  }
}
