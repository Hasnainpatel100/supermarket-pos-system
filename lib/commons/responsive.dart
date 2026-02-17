import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final w = Get.width;
    if (w >= 1024 && desktop != null) return desktop!;
    if (w >= 600 && tablet != null) return tablet!;
    return mobile;
  }
}
