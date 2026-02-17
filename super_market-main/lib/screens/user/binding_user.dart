import 'package:get/get.dart';
import 'controller_user.dart';

class BindingUser extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ControllerUser>(() => ControllerUser());
  }
}
