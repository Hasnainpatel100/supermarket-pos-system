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
      maxWidth: 540,
      maxHeight: 580,
      header: DialogHeader(
        title: 'add_item_batch'.tr,
        icon: Icons.inventory_2_rounded,
        iconColor: colorScheme.primary,
      ),
      body: DialogBody(
        child: Form(
          key: controller.formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FormSection(
                    icon: Icons.qr_code_2_rounded,
                    color: Colors.deepPurple.shade600,
                    title: 'batch_details'.tr,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: controller.batchNoController,
                          label: 'batch_number'.tr,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppNumberField(
                          controller: controller.quantityController,
                          label: 'quantity'.tr,
                          required: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppNumberField(
                          controller: controller.mrpController,
                          label: 'Cost',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppNumberField(
                          controller: controller.salePriceController,
                          label: 'Sales Rate / Price',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  FormSection(
                    icon: Icons.calendar_today_rounded,
                    color: Colors.orange.shade700,
                    title: 'Dates & Expiry',
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: AppDatePicker(
                          controller: controller.mfgDateController,
                          label: 'Mfg. Date',
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                            );
                            if (picked != null) {
                              controller.mfgDateController.text =
                                  picked.toString().split(' ').first;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppDatePicker(
                          controller: controller.expiryDateController,
                          label: 'expiry_date'.tr,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 180)),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                            );
                            if (picked != null) {
                              controller.expiryDateController.text =
                                  picked.toString().split(' ').first;
                            }
                          },
                        ),
                      ),
                    ],
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
        saveLabel: 'save_batch'.tr,
      ),
    );
  }
}
