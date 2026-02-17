import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/entity_todo.dart';
import '../../objectbox.g.dart';
import '../../service/service_locale.dart';
import '../../service/service_object_box.dart';
import '../../service/service_theme.dart';

class ControllerSample extends GetxController {
  late Box<EntityTodo> _todoBox;
  final ServiceTheme serviceTheme = Get.find();
  final ServiceLocale serviceLocale = Get.find();

  @override
  void onInit() {
    final ob = Get.find<ServiceObjectBox>();
    _todoBox = ob.box<EntityTodo>();
    super.onInit();
  }

  @override
  void onClose() {
    debugPrint('HomeController disposed');
    super.onClose();
  }
}
