import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller_splash.dart';

class ActivitySplash extends GetView<ControllerSplash> {
  const ActivitySplash({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ControllerSplash());
    return Scaffold(body: Center(child: Text("Welcome to Super Market")));
  }
}
