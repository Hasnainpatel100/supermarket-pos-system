import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/entity_item.dart';
import '../../widget/my_date_picker.dart';
import '../../widget/my_text_field.dart';
import 'controller_item_batch_form.dart';

class ActivityItemBatchForm extends StatelessWidget {
  const ActivityItemBatchForm({super.key});

  @override
  Widget build(BuildContext context) {
    final EntityItem item = Get.arguments as EntityItem;
    // ensure unique controller if multiple batch forms could open, though unlikely.
    // putting tag just in case? No, simple put is fine for now.
    final ControllerItemBatchForm controller = Get.put(
      ControllerItemBatchForm(item),
    );
    final colorScheme = Theme.of(context).colorScheme;

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
                            label: 'batch_number'.tr,
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
          ),
        ),
      ),
    );
  }
}

class _FormSectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  const _FormSectionHeader({
    required this.icon,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(height: 1, color: color.withValues(alpha: 0.2)),
        ),
      ],
    );
  }
}
