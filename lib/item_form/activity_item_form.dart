import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/entity_item.dart';
import '../service/service_item.dart';
import '../service/service_object_box.dart';
import '../widget/app_button.dart';
import '../widget/my_text_field.dart';
import 'controller_item_form.dart';

class ActivityItemForm extends StatelessWidget {
  const ActivityItemForm({super.key});

  @override
  Widget build(BuildContext context) {
    final itemService = ItemService(
      Get.find<ServiceObjectBox>().box<EntityItem>(),
    );

    final ControllerItemForm controller = Get.put(
      ControllerItemForm(itemService),
    );

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 500,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: controller.formKey,

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Item Form",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    SizedBox(height: 20),

                    MyTextField(
                      controller: controller.nameController,
                      label: "Item Name",
                      required: true,
                    ),

                    SizedBox(height: 12),

                    MyTextField(
                      controller: controller.barcodeController,
                      label: "Barcode",
                      required: true,
                    ),

                    SizedBox(height: 12),

                    MyTextField(
                      controller: controller.skuController,
                      label: "SKU",
                    ),

                    SizedBox(height: 12),

                    MyTextField(
                      controller: controller.unitController,
                      label: "Unit (pcs / kg)",
                    ),

                    SizedBox(height: 12),

                    MyTextField(
                      controller: controller.costController,
                      label: "Cost Price",
                      isNumber: true,
                    ),

                    SizedBox(height: 12),

                    MyTextField(
                      controller: controller.priceController,
                      label: "Selling Price",
                      required: true,
                      isNumber: true,
                    ),

                    SizedBox(height: 12),

                    Obx(
                      () => SwitchListTile(
                        title: Text("Has Expiry"),
                        value: controller.hasExpiry.value,
                        onChanged: (val) => controller.hasExpiry.value = val,
                      ),
                    ),

                    SizedBox(height: 10),

                    AppButton(title: "Save Item", onTap: controller.saveItem),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
