import 'package:get/get.dart';

import 'controller_sample.dart';

class BindingSample extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ControllerSample>(() => ControllerSample()); // auto-dispose on pop
  }
}