// utils/get_service.dart
import 'package:get/get.dart';

class ServiceGetOrPut {
  static T serviceGetOrPut<T extends GetxService>(T Function() createFn) {
    try {
      return Get.find<T>();
    } catch (e) {
      return Get.put<T>(createFn());
    }
  }
}
