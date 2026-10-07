import 'package:flutter/material.dart';
import 'package:get/get.dart';


class MyCheckBox extends StatelessWidget {
  final RxBool isActive;

  const MyCheckBox({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Obx(() => CheckboxListTile(
      value: isActive.value,
      onChanged: (v) {
        isActive.value = v ?? false;
      },
      title: Text('active'.tr),
      controlAffinity: ListTileControlAffinity.leading,
    ));
  }
}

