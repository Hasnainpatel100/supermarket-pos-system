import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../service/service_locale.dart';
import '../../service/service_object_box.dart';
import '../../service/service_theme.dart';

class ControllerSample extends GetxController {
  final ServiceTheme serviceTheme = Get.find();
  final ServiceLocale serviceLocale = Get.find();

  @override
  void onInit() {
    Get.find<ServiceObjectBox>();
    super.onInit();
  }

  @override
  void onClose() {
    debugPrint('HomeController disposed');
    super.onClose();
  }
}
