import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/model_branch.dart';
import '../../model/model_brand.dart';
import '../../repository/repo_branch.dart';
import '../../repository/repo_brand.dart';
import '../../util/snackbar_util.dart';

class ControllerBranchForm extends GetxController {
  final ModelBranch? editingBranch;
  ControllerBranchForm({this.editingBranch});

  final RepoBranch _repoBranch = Get.find<RepoBranch>();
  final RepoBrand _repoBrand = Get.find<RepoBrand>();

  final formKey = GlobalKey<FormState>();

  // ── State ─────────────────────────────────────────────────────────────────
  final rxIsSubmitting = false.obs;
  final rxIsLoadingBrands = false.obs;
  final rxBrandList = <ModelBrand>[].obs;
  final rxSelectedBrand = Rx<ModelBrand?>(null);
  final rxSelectedServiceTypes = <String>[].obs;
  final rxAppType = 'MARKET'.obs;
  final rxStatus = 'ACTIVE'.obs;

  static const List<String> appTypeOptions = ['MARKET'];
  static const List<String> statusOptions = ['ACTIVE', 'INACTIVE'];

  // ── Text Controllers ──────────────────────────────────────────────────────
  final tcBranchCode = TextEditingController();
  final tcName = TextEditingController();
  final tcFullAddress = TextEditingController();
  final tcCity = TextEditingController();
  final tcState = TextEditingController();
  final tcCountry = TextEditingController();
  final tcZipCode = TextEditingController();
  final tcLatitude = TextEditingController();
  final tcLongitude = TextEditingController();
  final tcGMapUrl = TextEditingController();
  final tcGMapPlaceId = TextEditingController();
  final tcPrimaryPhone = TextEditingController();
  final tcAlternatePhone = TextEditingController();
  final tcWhatsapp = TextEditingController();
  final tcEmail = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadBrands();
    if (editingBranch != null) _populateForm(editingBranch!);
  }

  Future<void> _loadBrands() async {
    rxIsLoadingBrands.value = true;
    try {
      final (brands, _, errMsg) = await _repoBrand.fetchBrands();
      rxBrandList.assignAll(brands);

      // Pre-select the brand if editing
      if (editingBranch != null && editingBranch!.brandId.isNotEmpty) {
        final match = brands.where((b) => b.id == editingBranch!.brandId).firstOrNull;
        rxSelectedBrand.value = match;
      }
    } finally {
      rxIsLoadingBrands.value = false;
    }
  }

  void _populateForm(ModelBranch branch) {
    tcBranchCode.text = branch.branchCode;
    tcName.text = branch.name.en;
    tcFullAddress.text = branch.address.full;
    tcCity.text = branch.address.city;
    tcState.text = branch.address.state;
    tcCountry.text = branch.address.country;
    tcZipCode.text = branch.address.zipCode;
    tcLatitude.text = branch.address.latitude ?? '';
    tcLongitude.text = branch.address.longitude ?? '';
    tcGMapUrl.text = branch.address.gMapUrl ?? '';
    tcGMapPlaceId.text = branch.address.gMapPlaceId ?? '';
    tcPrimaryPhone.text = branch.contact.phones.primary;
    tcAlternatePhone.text = branch.contact.phones.alternate;
    tcWhatsapp.text = branch.contact.phones.whatsapp;
    tcEmail.text = branch.contact.email;
    rxSelectedServiceTypes.assignAll(branch.serviceTypes);
    rxAppType.value = branch.appType;
    rxStatus.value = branch.status;
  }

  void copyPrimaryToWhatsapp() {
    tcWhatsapp.text = tcPrimaryPhone.text.trim();
  }

  void toggleServiceType(String type) {
    if (rxSelectedServiceTypes.contains(type)) {
      rxSelectedServiceTypes.remove(type);
    } else {
      rxSelectedServiceTypes.add(type);
    }
  }

  ModelBranch _buildBranch() {
    return ModelBranch(
      id: editingBranch?.id,
      brandId: rxSelectedBrand.value?.id ?? '',
      brandName: rxSelectedBrand.value?.name.en,
      branchCode: tcBranchCode.text.trim(),
      name: BranchName(en: tcName.text.trim()),
      address: BranchAddress(
        full: tcFullAddress.text.trim(),
        city: tcCity.text.trim(),
        state: tcState.text.trim(),
        country: tcCountry.text.trim(),
        zipCode: tcZipCode.text.trim(),
        latitude: tcLatitude.text.trim().isEmpty ? null : tcLatitude.text.trim(),
        longitude: tcLongitude.text.trim().isEmpty ? null : tcLongitude.text.trim(),
        gMapUrl: tcGMapUrl.text.trim().isEmpty ? null : tcGMapUrl.text.trim(),
        gMapPlaceId: tcGMapPlaceId.text.trim().isEmpty ? null : tcGMapPlaceId.text.trim(),
      ),
      contact: BranchContact(
        phones: BranchPhones(
          primary: tcPrimaryPhone.text.trim(),
          alternate: tcAlternatePhone.text.trim(),
          whatsapp: tcWhatsapp.text.trim(),
        ),
        email: tcEmail.text.trim(),
      ),
      serviceTypes: List.from(rxSelectedServiceTypes),
      appType: rxAppType.value,
      status: rxStatus.value,
    );
  }

  Future<void> submitForm() async {
    if (!formKey.currentState!.validate()) return;
    if (rxSelectedBrand.value == null) {
      SnackbarUtil.showWarning('Please select a Brand for this branch.');
      return;
    }

    rxIsSubmitting.value = true;
    try {
      final branch = _buildBranch();
      final isEditing = editingBranch != null && editingBranch!.id != null;

      if (isEditing) {
        final (_, success, message) = await _repoBranch.updateBranch(editingBranch!.id!, branch);
        if (success) {
          SnackbarUtil.showSuccess('Branch updated successfully');
          Get.back(result: branch);
        } else {
          SnackbarUtil.showWarning(message);
        }
      } else {
        final (created, success, message) = await _repoBranch.createBranch(branch);
        if (success) {
          SnackbarUtil.showSuccess('Branch created successfully');
          Get.back(result: created);
        } else {
          // Still close with result on local fallback
          SnackbarUtil.showWarning(message);
          if (created != null) Get.back(result: created);
        }
      }
    } finally {
      rxIsSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    tcBranchCode.dispose();
    tcName.dispose();
    tcFullAddress.dispose();
    tcCity.dispose();
    tcState.dispose();
    tcCountry.dispose();
    tcZipCode.dispose();
    tcLatitude.dispose();
    tcLongitude.dispose();
    tcGMapUrl.dispose();
    tcGMapPlaceId.dispose();
    tcPrimaryPhone.dispose();
    tcAlternatePhone.dispose();
    tcWhatsapp.dispose();
    tcEmail.dispose();
    super.onClose();
  }
}
