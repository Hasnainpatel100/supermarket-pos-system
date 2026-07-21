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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Icon(
              Icons.inventory_2_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'add_item_batch'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
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
      body: Center(
        child: SizedBox(
          width: 600,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: controller.formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FormSectionHeader(
                      icon: Icons.qr_code_2_rounded,
                      color: Colors.deepPurple,
                      title: 'batch_details'.tr,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MyTextField(
                            controller: controller.batchNoController,
                            label: "Batch Number",
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MyTextField(
                            controller: controller.quantityController,
                            label: 'quantity'.tr,
                            isNumber: true,
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
                    _FormSectionHeader(
                      icon: Icons.calendar_today_rounded,
                      color: Colors.orange,
                      title: 'expiry_information'.tr,
                    ),
                    const SizedBox(height: 16),
                    MyDatePicker(
                      controller: controller.expiryDateController,
                      label: 'expiry_date'.tr,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Get.back(),
                          child: Text('skip_cancel'.tr),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: controller.saveBatch,
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: Text('save_batch'.tr),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
