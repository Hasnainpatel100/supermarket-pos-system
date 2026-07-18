import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/entity_item.dart';
import '../../widget/app_dialog_components.dart';
import 'controller_item_batch_form.dart';

class ActivityItemBatchForm extends StatelessWidget {
  const ActivityItemBatchForm({super.key});

  @override
  Widget build(BuildContext context) {
    final EntityItem item = Get.arguments as EntityItem;
    final ControllerItemBatchForm controller = Get.put(
      ControllerItemBatchForm(item),
    );
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialog(
      maxWidth: 500,
      maxHeight: 520,
      header: DialogHeader(
        title: 'Add Item Batch',
        icon: Icons.inventory_2_rounded,
        iconColor: colorScheme.primary,
      ),
      body: DialogBody(
        child: Form(
          key: controller.formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 400;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FormSection(
                    icon: Icons.qr_code_2_rounded,
                    color: Colors.deepPurple,
                    title: 'Batch Details',
                  ),
                  const SizedBox(height: 16),

                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: controller.batchNoController,
                            label: "Batch Number",
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppNumberField(
                            controller: controller.quantityController,
                            label: "Quantity",
                            required: true,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    AppTextField(
                      controller: controller.batchNoController,
                      label: "Batch Number",
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    AppNumberField(
                      controller: controller.quantityController,
                      label: "Quantity",
                      required: true,
                    ),
                  ],

                  const SizedBox(height: 24),

                  const FormSection(
                    icon: Icons.calendar_today_rounded,
                    color: Colors.orange,
                    title: 'Expiry Information',
                  ),
                  const SizedBox(height: 16),

                  AppDatePicker(
                    controller: controller.expiryDateController,
                    label: "Expiry Date",
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        controller.expiryDateController.text =
                            picked.toString().split(' ').first;
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
      footer: DialogFooter(
        onCancel: () => Get.back(),
        onSave: controller.saveBatch,
        saveLabel: "Save Batch",
      ),
    );
  }
}
