import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../commons/responsive.dart';
import 'activity_main_desktop.dart';
import 'activity_main_mobile.dart';
import 'activity_main_tablet.dart';
import 'controller_sample.dart';

class ActivitySample extends GetView<ControllerSample> {
  const ActivitySample({super.key});

  @override
  Widget build(BuildContext context) {
    return Responsive(
      mobile: ActivitySampleMobile(controller: controller),
      tablet: ActivitySampleTablet(controller: controller),
      desktop: ActivitySampleDesktop(controller: controller),
    );
  }
}
