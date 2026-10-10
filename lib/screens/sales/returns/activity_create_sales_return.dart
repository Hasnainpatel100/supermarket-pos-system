import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../model/entity_bill.dart';
import '../../../model/entity_item.dart';
import '../../../service/service_currency.dart';
import '../../../widget/app_dialog_components.dart';
import '../../../widget/my_card.dart';
import 'controller_create_sales_return.dart';

class ActivityCreateSalesReturn extends StatefulWidget {
  final EntityBill? linkedBill;

  const ActivityCreateSalesReturn({super.key, this.linkedBill});

  @override
  State<ActivityCreateSalesReturn> createState() => _ActivityCreateSalesReturnState();
}

class _ActivityCreateSalesReturnState extends State<ActivityCreateSalesReturn> {
  late final ControllerCreateSalesReturn controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ControllerCreateSalesReturn>()) {
      Get.delete<ControllerCreateSalesReturn>();
    }
    controller = Get.put(ControllerCreateSalesReturn(linkedBill: widget.linkedBill));
  }

  @override
  void dispose() {
    if (Get.isRegistered<ControllerCreateSalesReturn>()) {
      Get.delete<ControllerCreateSalesReturn>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final currencySymbol = Get.isRegistered<ServiceCurrency>()
        ? Get.find<ServiceCurrency>().rxCurrency.value
        : '₹';
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: currencySymbol);

    return AppDialog(
      maxWidth: 1020,
      maxHeight: 820,
      header: DialogHeader(
        title: 'New Sales Return / Credit Note'.tr,
        icon: Icons.assignment_return_rounded,
        iconColor: isDark ? Colors.red.shade400 : Colors.red.shade700,
      ),
      body: DialogBody(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── TOP ROW: Customer & Return Details ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Customer Card ──
                Expanded(
                  flex: 5,
                  child: MyCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormSection(
                          icon: Icons.person_outline_rounded,
                          title: 'Customer Details'.tr,
                          color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller.customerNameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Customer Name *'.tr,
                            prefixIcon: const Icon(Icons.person_outline),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller.customerPhoneCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Mobile Number'.tr,
                                  prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: controller.customerGstinCtrl,
                                decoration: InputDecoration(
                                  labelText: 'GSTIN (Optional)'.tr,
                                  prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller.customerAddressCtrl,
                          decoration: InputDecoration(
                            labelText: 'Billing Address'.tr,
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // ── Return Information Card ──
                Expanded(
                  flex: 5,
                  child: MyCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormSection(
                          icon: Icons.assignment_return_outlined,
                          title: 'Return Details'.tr,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(height: 12),
                        // Link to Invoice Field
                        TypeAheadField<EntityBill>(
                          controller: controller.originalBillNoCtrl,
                          debounceDuration: const Duration(milliseconds: 200),
                          constraints: const BoxConstraints(maxHeight: 280),
                          suggestionsCallback: (pattern) {
                            final q = pattern.trim().toLowerCase();
                            if (q.isEmpty) {
                              return controller.rxAvailableBills.take(20).toList();
                            }
                            return controller.rxAvailableBills.where((b) {
                              final no = (b.billNo ?? '').toLowerCase();
                              final name = (b.customerName ?? '').toLowerCase();
                              return no.contains(q) || name.contains(q);
                            }).take(20).toList();
                          },
                          builder: (context, textController, focusNode) {
                            return TextField(
                              controller: textController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Link to Invoice (Optional)'.tr,
                                hintText: 'Search invoice by number or customer...'.tr,
                                prefixIcon: const Icon(Icons.receipt_long_rounded),
                                isDense: true,
                              ),
                            );
                          },
                          itemBuilder: (context, bill) {
                            return ListTile(
                              dense: true,
                              title: Text(bill.billNo ?? '#${bill.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${bill.customerName ?? "Cash"} | Total: $currencySymbol${bill.grandTotal ?? 0}'),
                              trailing: Text(bill.billDate ?? ''),
                            );
                          },
                          onSelected: (bill) {
                            controller.onBillSelected(bill);
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller.returnNoCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Return No. *'.tr,
                                  prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: controller.returnDateCtrl,
                                readOnly: true,
                                onTap: () => _pickDate(context, controller.returnDateCtrl),
                                decoration: InputDecoration(
                                  labelText: 'Return Date'.tr,
                                  prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller.returnReasonCtrl,
                          decoration: InputDecoration(
                            labelText: 'Return Reason'.tr,
                            hintText: 'e.g. Defective, Expired, Customer Request'.tr,
                            prefixIcon: const Icon(Icons.help_outline_rounded, size: 18),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── ITEMS TABLE CARD ──
            MyCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FormSection(
                          icon: Icons.assignment_return_rounded,
                          title: 'Returned Items'.tr,
                          color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => controller.addRow(),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: Text('add_item'.tr),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? Colors.red.shade300 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.red.shade400 : Colors.red.shade700).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 32, child: Text('#', style: _headerStyle(colorScheme))),
                        Expanded(flex: 4, child: Text('ITEM / PRODUCT'.tr, style: _headerStyle(colorScheme))),
                        SizedBox(width: 90, child: Text('QTY'.tr, style: _headerStyle(colorScheme))),
                        SizedBox(width: 110, child: Text('REFUND RATE'.tr, style: _headerStyle(colorScheme))),
                        SizedBox(width: 90, child: Text('TAX %'.tr, style: _headerStyle(colorScheme))),
                        SizedBox(width: 120, child: Text('TOTAL REFUND'.tr, style: _headerStyle(colorScheme), textAlign: TextAlign.right)),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),

                  // Rows
                  Obx(
                    () => Column(
                      children: List.generate(controller.rxRows.length, (i) {
                        final row = controller.rxRows[i];

                        return Column(
                          children: [
                            if (i > 0)
                              Divider(
                                height: 1,
                                color: colorScheme.outline.withValues(alpha: 0.15),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: TypeAheadField<EntityItem>(
                                      controller: row.nameCtrl,
                                      debounceDuration: const Duration(milliseconds: 200),
                                      constraints: const BoxConstraints(maxHeight: 280),
                                      suggestionsCallback: (pattern) {
                                        final q = pattern.trim().toLowerCase();
                                        if (q.isEmpty) {
                                          return controller.rxAvailableItems.take(20).toList();
                                        }
                                        return controller.rxAvailableItems.where((it) {
                                          final name = (it.name ?? '').toLowerCase();
                                          return name.contains(q);
                                        }).take(20).toList();
                                      },
                                      builder: (context, textController, focusNode) {
                                        return TextField(
                                          controller: textController,
                                          focusNode: focusNode,
                                          onChanged: (val) {
                                            controller.calculateTotals();
                                          },
                                          decoration: InputDecoration(
                                            hintText: 'Search product...'.tr,
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          ),
                                        );
                                      },
                                      itemBuilder: (context, item) {
                                        return ListTile(
                                          dense: true,
                                          title: Text(item.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text('Price: $currencySymbol${item.sellingPrice ?? 0}'),
                                        );
                                      },
                                      onSelected: (item) {
                                        controller.onItemPicked(row, item);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // QTY
                                  SizedBox(
                                    width: 90,
                                    child: TextField(
                                      controller: row.qtyCtrl,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => controller.calculateTotals(),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // RATE
                                  SizedBox(
                                    width: 110,
                                    child: TextField(
                                      controller: row.priceCtrl,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => controller.calculateTotals(),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // TAX %
                                  SizedBox(
                                    width: 90,
                                    child: TextField(
                                      controller: row.taxRateCtrl,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => controller.calculateTotals(),
                                      decoration: const InputDecoration(
                                        hintText: '0',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // TOTAL
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      currencyFmt.format(row.lineTotal),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                                      ),
                                    ),
                                  ),

                                  // Delete button
                                  SizedBox(
                                    width: 40,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                      onPressed: () => controller.removeRow(i),
                                      tooltip: 'remove'.tr,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── BOTTOM ROW: Notes & Refund Summary ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notes Card
                Expanded(
                  flex: 5,
                  child: MyCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormSection(
                          icon: Icons.note_alt_outlined,
                          title: 'Return Notes'.tr,
                          color: Colors.indigo.shade600,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller.notesCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Return Remarks'.tr,
                            hintText: 'Enter reason for return or notes...'.tr,
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Refund Summary Card
                Expanded(
                  flex: 5,
                  child: MyCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FormSection(
                          icon: Icons.payments_outlined,
                          title: 'Refund Summary'.tr,
                          color: isDark ? Colors.red.shade400 : Colors.red.shade700,
                        ),
                        const SizedBox(height: 14),

                        // Payment Mode
                        Row(
                          children: [
                            Text('Refund Mode:'.tr, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: controller.rxRefundMode.value,
                                isDense: true,
                                decoration: const InputDecoration(isDense: true),
                                onChanged: (v) => controller.rxRefundMode.value = v ?? 'Cash',
                                items: ['Cash', 'UPI', 'Card', 'Store Credit']
                                    .map((m) => DropdownMenuItem(value: m, child: Text(m.tr)))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Total Refund Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.red.shade400 : Colors.red.shade700).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Refund:'.tr,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                              ),
                              Obx(
                                () => Text(
                                  currencyFmt.format(controller.rxRefundTotal.value),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      footer: DialogFooter(
        onCancel: () => Navigator.of(context).pop(false),
        onSave: () async {
          final ok = await controller.saveReturn();
          if (ok && context.mounted) {
            final savedNo = controller.returnNoCtrl.text.trim();
            Navigator.of(context).pop(true);
            Get.snackbar(
              'Return Processed'.tr,
              'Sales Return #$savedNo completed and items returned to stock!'.tr,
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white,
            );
          }
        },
        saveLabel: 'Save Return'.tr,
        saveButtonColor: isDark ? Colors.red.shade600 : Colors.red.shade700,
      ),
    );
  }

  static TextStyle _headerStyle(ColorScheme colorScheme) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurfaceVariant,
      );

  Future<void> _pickDate(BuildContext context, TextEditingController ctrl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }
}
