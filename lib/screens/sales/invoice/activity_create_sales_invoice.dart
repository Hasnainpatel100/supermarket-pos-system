import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../model/entity_bill.dart';
import '../../../model/entity_customer.dart';
import '../../../model/entity_item.dart';
import '../../../screens/home/fragment/setting/controller_home_settings.dart';
import '../../../service/service_currency.dart';
import '../../../widget/app_dialog_components.dart';
import '../../../widget/my_card.dart';
import 'controller_create_sales_invoice.dart';
import 'controller_sales_invoices.dart';

class ActivityCreateSalesInvoice extends StatefulWidget {
  final EntityBill? editingBill;

  const ActivityCreateSalesInvoice({super.key, this.editingBill});

  @override
  State<ActivityCreateSalesInvoice> createState() =>
      _ActivityCreateSalesInvoiceState();
}

class _ActivityCreateSalesInvoiceState
    extends State<ActivityCreateSalesInvoice> {
  late final ControllerCreateSalesInvoice controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ControllerCreateSalesInvoice>()) {
      Get.delete<ControllerCreateSalesInvoice>();
    }
    controller = Get.put(
      ControllerCreateSalesInvoice(editingBill: widget.editingBill),
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<ControllerCreateSalesInvoice>()) {
      Get.delete<ControllerCreateSalesInvoice>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeName = Get.isRegistered<ControllerHomeSettings>()
        ? Get.find<ControllerHomeSettings>().rxStoreName.value
        : '';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final currencySymbol = Get.isRegistered<ServiceCurrency>()
        ? Get.find<ServiceCurrency>().rxCurrency.value
        : '₹';
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: currencySymbol,
    );

    final isEditing = widget.editingBill != null;

    return AppDialog(
      maxWidth: 1100,
      maxHeight: 880,
      header: DialogHeader(
        title: isEditing ? 'Edit Sales Invoice'.tr : 'New Sales Invoice'.tr,
        icon: Icons.receipt_long_rounded,
        iconColor: colorScheme.primary,
        actions: [
          OutlinedButton.icon(
            onPressed: () => controller.previewInvoice(),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: Text('Preview'.tr),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DialogBody(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── TOP ROW: Customer / Bill To & Invoice Details ──
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
                        Row(
                          children: [
                            Expanded(
                              child: FormSection(
                                icon: Icons.person_outline_rounded,
                                title: 'Customer Details'.tr,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () =>
                                  _showPartyPickerModal(context, controller),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 16,
                              ),
                              label: Text(
                                '+ Add Customer'.tr,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TypeAheadField<EntityCustomer>(
                          controller: controller.customerNameCtrl,
                          debounceDuration: const Duration(milliseconds: 200),
                          constraints: const BoxConstraints(maxHeight: 280),
                          suggestionsCallback: (pattern) {
                            final q = pattern.trim().toLowerCase();
                            if (q.isEmpty) {
                              return controller.rxAvailableCustomers
                                  .take(20)
                                  .toList();
                            }
                            return controller.rxAvailableCustomers
                                .where((c) {
                                  final name = (c.name ?? '').toLowerCase();
                                  final phone = (c.phone ?? '').toLowerCase();
                                  return name.contains(q) || phone.contains(q);
                                })
                                .take(20)
                                .toList();
                          },
                          builder: (context, textController, focusNode) {
                            return TextField(
                              controller: textController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Customer / Party Name *'.tr,
                                hintText: 'Search by name or phone...'.tr,
                                prefixIcon: const Icon(Icons.person_outline),
                                isDense: true,
                              ),
                            );
                          },
                          itemBuilder: (context, customer) {
                            return ListTile(
                              dense: true,
                              title: Text(
                                customer.name ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(customer.phone ?? ''),
                              trailing: customer.notes?.isNotEmpty == true
                                  ? Text('GST: ${customer.notes}')
                                  : null,
                            );
                          },
                          onSelected: (customer) {
                            controller.selectCustomer(customer);
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller.customerPhoneCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Mobile Number'.tr,
                                  prefixIcon: const Icon(
                                    Icons.phone_outlined,
                                    size: 18,
                                  ),
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
                                  prefixIcon: const Icon(
                                    Icons.badge_outlined,
                                    size: 18,
                                  ),
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
                            prefixIcon: const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                            ),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // ── Invoice Details Card ──
                Expanded(
                  flex: 6,
                  child: MyCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormSection(
                          icon: Icons.receipt_outlined,
                          title: 'Invoice Details'.tr,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller.invoiceNoCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Invoice No. *'.tr,
                                  prefixIcon: const Icon(
                                    Icons.tag_rounded,
                                    size: 18,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: controller.invoiceDateCtrl,
                                readOnly: true,
                                onTap: () => _pickDate(
                                  context,
                                  controller.invoiceDateCtrl,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Invoice Date'.tr,
                                  prefixIcon: const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller.paymentTermsCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Payment Terms (Days)'.tr,
                                  prefixIcon: const Icon(
                                    Icons.timelapse_rounded,
                                    size: 18,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: controller.dueDateCtrl,
                                readOnly: true,
                                onTap: () =>
                                    _pickDate(context, controller.dueDateCtrl),
                                decoration: InputDecoration(
                                  labelText: 'Due Date'.tr,
                                  prefixIcon: const Icon(
                                    Icons.event_available_rounded,
                                    size: 18,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller.poNoCtrl,
                                decoration: InputDecoration(
                                  labelText: 'PO No.'.tr,
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: controller.ewayBillCtrl,
                                decoration: InputDecoration(
                                  labelText: 'E-Way Bill'.tr,
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: controller.vehicleNoCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Vehicle No.'.tr,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
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
                          icon: Icons.shopping_basket_outlined,
                          title: 'Items & Products'.tr,
                          color: Colors.teal.shade600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => controller.addRow(),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: Text('add_item'.tr),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showBarcodeScanDialog(context, controller),
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 18,
                        ),
                        label: Text('Scan Barcode'.tr),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 860,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.06,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '#',
                                    style: _headerStyle(colorScheme),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    'ITEM / SERVICE'.tr,
                                    style: _headerStyle(colorScheme),
                                  ),
                                ),
                                SizedBox(
                                  width: 85,
                                  child: Text(
                                    'HSN'.tr,
                                    style: _headerStyle(colorScheme),
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    'MRP'.tr,
                                    style: _headerStyle(colorScheme),
                                  ),
                                ),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    'QTY'.tr,
                                    style: _headerStyle(colorScheme),
                                  ),
                                ),
                                SizedBox(
                                  width: 95,
                                  child: Text(
                                    'RATE'.tr,
                                    style: _headerStyle(colorScheme),
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    'DISC'.tr,
                                    style: _headerStyle(colorScheme),
                                  ),
                                ),
                                SizedBox(
                                  width: 75,
                                  child: Text(
                                    'TAX %'.tr,
                                    style: _headerStyle(colorScheme),
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    'TOTAL'.tr,
                                    style: _headerStyle(colorScheme),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                if (!isEditing) const SizedBox(width: 40),
                              ],
                            ),
                          ),

                          // Table Rows
                          Obx(
                            () => Column(
                              children: List.generate(controller.rxRows.length, (
                                i,
                              ) {
                                final row = controller.rxRows[i];

                                return Column(
                                  children: [
                                    if (i > 0)
                                      Divider(
                                        height: 1,
                                        color: colorScheme.outline.withValues(
                                          alpha: 0.15,
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 32,
                                            child: Text(
                                              '${i + 1}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          // Item Selector
                                          Expanded(
                                            flex: 4,
                                            child: TypeAheadField<EntityItem>(
                                              controller: row.nameCtrl,
                                              debounceDuration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              constraints: const BoxConstraints(
                                                maxHeight: 280,
                                              ),
                                              suggestionsCallback: (pattern) {
                                                final q = pattern
                                                    .trim()
                                                    .toLowerCase();
                                                if (q.isEmpty) {
                                                  return controller
                                                      .rxAvailableItems
                                                      .take(20)
                                                      .toList();
                                                }
                                                return controller
                                                    .rxAvailableItems
                                                    .where((it) {
                                                      final name =
                                                          (it.name ?? '')
                                                              .toLowerCase();
                                                      final barcode =
                                                          (it.barcode ?? '')
                                                              .toLowerCase();
                                                      return name.contains(q) ||
                                                          barcode.contains(q);
                                                    })
                                                    .take(20)
                                                    .toList();
                                              },
                                              builder:
                                                  (
                                                    context,
                                                    textController,
                                                    focusNode,
                                                  ) {
                                                    return TextField(
                                                      controller:
                                                          textController,
                                                      focusNode: focusNode,
                                                      onChanged: (val) {
                                                        controller
                                                            .calculateTotals();
                                                      },
                                                      decoration: InputDecoration(
                                                        hintText:
                                                            'Search item or enter description...'
                                                                .tr,
                                                        isDense: true,
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 10,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                              itemBuilder: (context, item) {
                                                return ListTile(
                                                  dense: true,
                                                  title: Text(
                                                    item.name ?? '',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    'Price: $currencySymbol${item.sellingPrice ?? 0} | Stock: ${item.totalQty ?? 0}',
                                                  ),
                                                  trailing:
                                                      item
                                                              .hsnCode
                                                              ?.isNotEmpty ==
                                                          true
                                                      ? Text(
                                                          'HSN: ${item.hsnCode}',
                                                        )
                                                      : null,
                                                );
                                              },
                                              onSelected: (item) {
                                                controller.onItemPicked(
                                                  row,
                                                  item,
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // HSN
                                          SizedBox(
                                            width: 85,
                                            child: TextField(
                                              controller: row.hsnCtrl,
                                              decoration: const InputDecoration(
                                                hintText: 'HSN',
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 10,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // MRP
                                          SizedBox(
                                            width: 80,
                                            child: TextField(
                                              controller: row.mrpCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                hintText: '0',
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 10,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // QTY
                                          SizedBox(
                                            width: 70,
                                            child: TextField(
                                              controller: row.qtyCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (_) =>
                                                  controller.calculateTotals(),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 10,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // PRICE
                                          SizedBox(
                                            width: 95,
                                            child: TextField(
                                              controller: row.priceCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (_) =>
                                                  controller.calculateTotals(),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 10,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // DISCOUNT
                                          SizedBox(
                                            width: 80,
                                            child: TextField(
                                              controller: row.discountCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (_) =>
                                                  controller.calculateTotals(),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 10,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // TAX %
                                          SizedBox(
                                            width: 75,
                                            child: TextField(
                                              controller: row.taxRateCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (_) =>
                                                  controller.calculateTotals(),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 10,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // AMOUNT
                                          SizedBox(
                                            width: 100,
                                            child: Text(
                                              currencyFmt.format(row.lineTotal),
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),

                                          // Remove button (only available for new sales invoice creation)
                                          if (!isEditing)
                                            SizedBox(
                                              width: 40,
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () =>
                                                    controller.removeRow(i),
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
                  ),

                  const SizedBox(height: 12),
                  // Subtotal Row
                  Obx(
                    () => Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 48),
                        child: Text(
                          'Subtotal: ${currencyFmt.format(controller.rxSubtotal.value)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── BOTTOM ROW: Notes & Payment Calculations ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notes & Conditions Card
                Expanded(
                  flex: 5,
                  child: MyCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormSection(
                          icon: Icons.note_alt_outlined,
                          title: 'Notes & Terms'.tr,
                          color: Colors.indigo.shade600,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller.notesCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Notes / Remarks'.tr,
                            hintText: 'Enter any instructions or notes...'.tr,
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: controller.termsCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Terms & Conditions'.tr,
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Store Bank Information'.tr,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Account Holder: ${storeName.isNotEmpty ? storeName : "Super Market"}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'Account: 123456789123456 | IFSC: PUNB0188900',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Calculations & Payment Summary Card
                Expanded(
                  flex: 6,
                  child: MyCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FormSection(
                          icon: Icons.payments_outlined,
                          title: 'Payment & Balance'.tr,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Taxable Amount:'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Obx(
                              () => Text(
                                currencyFmt.format(
                                  controller.rxTaxableAmount.value,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Additional Charges:'.tr,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              height: 38,
                              child: TextField(
                                controller: controller.additionalChargesCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                onChanged: (_) => controller.calculateTotals(),
                                decoration: const InputDecoration(
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Extra Discount:'.tr,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              height: 38,
                              child: TextField(
                                controller: controller.extraDiscountCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                onChanged: (_) => controller.calculateTotals(),
                                decoration: const InputDecoration(
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Auto Round Off'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Obx(
                              () => Switch(
                                value: controller.rxAutoRoundOff.value,
                                onChanged: (val) {
                                  controller.rxAutoRoundOff.value = val;
                                  controller.calculateTotals();
                                },
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        // Total Banner
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount:'.tr,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Obx(
                                () => Text(
                                  currencyFmt.format(
                                    controller.rxGrandTotal.value,
                                  ),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Payment Mode Dropdown
                        Row(
                          children: [
                            Text(
                              'Payment Mode:'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Obx(() {
                                final current =
                                    ControllerCreateSalesInvoice.normalizePaymentMode(
                                      controller.rxPaymentMode.value,
                                    );
                                return DropdownButtonFormField<String>(
                                  initialValue: current,
                                  isDense: true,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  onChanged: (v) =>
                                      controller.rxPaymentMode.value =
                                          v ?? 'Cash',
                                  items:
                                      [
                                            'Cash',
                                            'UPI',
                                            'Card',
                                            'Netbanking',
                                            'Credit',
                                          ]
                                          .map(
                                            (m) => DropdownMenuItem(
                                              value: m,
                                              child: Text(
                                                m.tr,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Amount Received
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Amount Received:'.tr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              height: 38,
                              child: TextField(
                                controller: controller.amountReceivedCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                onChanged: controller.onAmountReceivedChanged,
                                decoration: const InputDecoration(
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Fully Paid Checkbox
                        Row(
                          children: [
                            Obx(
                              () => Checkbox(
                                value: controller.rxMarkFullyPaid.value,
                                onChanged: controller.toggleFullyPaid,
                              ),
                            ),
                            Text(
                              'Mark as fully paid'.tr,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        // Balance Due
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Balance Due:'.tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Obx(
                              () => Text(
                                currencyFmt.format(
                                  controller.rxBalanceAmount.value,
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: controller.rxBalanceAmount.value > 0
                                      ? (isDark
                                            ? Colors.red.shade300
                                            : Colors.red.shade700)
                                      : (isDark
                                            ? Colors.green.shade300
                                            : Colors.green.shade700),
                                ),
                              ),
                            ),
                          ],
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
          final ok = await controller.saveInvoice();
          if (ok && context.mounted) {
            final savedNo = controller.invoiceNoCtrl.text.trim();
            Navigator.of(context).pop(true);
            Get.snackbar(
              'Success'.tr,
              'Sales Invoice #$savedNo saved successfully!'.tr,
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white,
            );
          }
        },
        saveLabel: isEditing ? 'Update Invoice'.tr : 'Save Invoice'.tr,
        extraWidget: OutlinedButton.icon(
          onPressed: () async {
            final ok = await controller.saveInvoice();
            if (ok && context.mounted) {
              final savedNo = controller.invoiceNoCtrl.text.trim();
              Navigator.of(context).pop(true);
              Get.snackbar(
                'Success'.tr,
                'Sales Invoice #$savedNo saved successfully!'.tr,
                backgroundColor: Colors.green.shade600,
                colorText: Colors.white,
              );
              if (Get.isRegistered<ControllerSalesInvoices>()) {
                Get.find<ControllerSalesInvoices>().openCreateInvoice();
              }
            }
          },
          icon: const Icon(Icons.add_task_rounded, size: 16),
          label: Text('Save & New'.tr),
        ),
      ),
    );
  }

  static TextStyle _headerStyle(ColorScheme colorScheme) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: colorScheme.onSurfaceVariant,
  );

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController ctrl,
  ) async {
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

  void _showPartyPickerModal(
    BuildContext context,
    ControllerCreateSalesInvoice controller,
  ) {
    final name = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    final gstin = TextEditingController();

    Get.dialog(
      AppDialog(
        maxWidth: 500,
        maxHeight: 480,
        header: DialogHeader(
          title: 'Add New Customer'.tr,
          icon: Icons.person_add_rounded,
        ),
        body: DialogBody(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: 'Customer / Party Name *'.tr,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                decoration: InputDecoration(labelText: 'Phone Number'.tr),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: address,
                decoration: InputDecoration(labelText: 'Address'.tr),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gstin,
                decoration: InputDecoration(labelText: 'GSTIN / Notes'.tr),
              ),
            ],
          ),
        ),
        footer: DialogFooter(
          onCancel: () => Get.back(),
          onSave: () {
            if (name.text.trim().isNotEmpty) {
              controller.customerNameCtrl.text = name.text.trim();
              controller.customerPhoneCtrl.text = phone.text.trim();
              controller.customerAddressCtrl.text = address.text.trim();
              controller.customerGstinCtrl.text = gstin.text.trim();
              Get.back();
            }
          },
          saveLabel: 'Select Party'.tr,
        ),
      ),
    );
  }

  void _showBarcodeScanDialog(
    BuildContext context,
    ControllerCreateSalesInvoice controller,
  ) {
    final barcodeCtrl = TextEditingController();
    Get.dialog(
      AppDialog(
        maxWidth: 420,
        maxHeight: 260,
        header: DialogHeader(
          title: 'Scan Barcode'.tr,
          icon: Icons.qr_code_scanner_rounded,
        ),
        body: DialogBody(
          child: TextField(
            controller: barcodeCtrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Scan or enter barcode'.tr,
              prefixIcon: const Icon(Icons.qr_code_rounded),
            ),
            onSubmitted: (val) {
              final match = controller.rxAvailableItems.firstWhereOrNull(
                (it) => it.barcode == val.trim(),
              );
              if (match != null) {
                controller.addRow();
                controller.onItemPicked(controller.rxRows.last, match);
                Get.back();
              } else {
                Get.snackbar(
                  'Not Found'.tr,
                  'No product matching barcode: $val',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
          ),
        ),
        footer: DialogFooter(
          onCancel: () => Get.back(),
          onSave: () {
            final val = barcodeCtrl.text.trim();
            final match = controller.rxAvailableItems.firstWhereOrNull(
              (it) => it.barcode == val,
            );
            if (match != null) {
              controller.addRow();
              controller.onItemPicked(controller.rxRows.last, match);
              Get.back();
            } else {
              Get.snackbar(
                'Not Found'.tr,
                'No product matching barcode: $val',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
          },
          saveLabel: 'Add Item'.tr,
        ),
      ),
    );
  }
}
