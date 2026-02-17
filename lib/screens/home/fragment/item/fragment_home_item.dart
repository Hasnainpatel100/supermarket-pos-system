import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/item_form/activity_item_form.dart';

class FragmentHomeItem extends StatelessWidget {
  const FragmentHomeItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Fragment item")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(ActivityItemForm());
        },
        child: const Icon(Icons.add),
      ),

    );
  }
}
