import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../../../model/entity_item.dart';
import '../../../../../model/entity_supplier.dart';
import '../../../../../util/snackbar_util.dart';
import '../../../../../widget/my_card.dart';
import '../supplier/activity_supplier_form.dart';
import '../supplier/controller_home_supplier.dart';
import 'controller_home_purchase.dart';

class ActivityPurchaseForm extends StatefulWidget {
  const ActivityPurchaseForm({super.key});

  @override
  State<ActivityPurchaseForm> createState() => _ActivityPurchaseFormState();
}

class _ActivityPurchaseFormState extends State<ActivityPurchaseForm> {
  late final ControllerHomePurchase _controller;

  EntitySupplier? _selectedSupplier;
  DateTime _purchaseDate = DateTime.now();
  DateTime? _expectedDate;

  final List<_ItemRow> _rows = [];
  List<EntitySupplier> _suppliers = [];
  List<EntityItem> _items = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ControllerHomePurchase>()
        ? Get.find<ControllerHomePurchase>()
        : Get.put(ControllerHomePurchase());
    _suppliers = _controller.getAllActiveSuppliers();
    _items = _controller.getAllActiveItems();
    _addRow(); // start with one empty row
  }

  void _addRow() {
    setState(() => _rows.add(_ItemRow()));
  }

  void _removeRow(int index) {
    if (_rows.length > 1) {
      setState(() => _rows.removeAt(index));
    }
  }

  double get _totalAmount => _rows.fold(
      0,
          (sum, r) =>
      sum +
          (double.tryParse(r.qtyCtrl.text) ?? 0) *
              (double.tryParse(r.costCtrl.text) ?? 0));

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _pickExpectedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDate ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _expectedDate = picked);
  }

  void _save() {
    if (_selectedSupplier == null) {
      SnackbarUtil.showError('Please select a supplier'.tr);
      return;
    }

    final validRows = _rows
        .where((r) =>
    r.selectedItem != null &&
        (double.tryParse(r.qtyCtrl.text) ?? 0) > 0 &&
        (double.tryParse(r.costCtrl.text) ?? 0) > 0)
        .toList();

    if (validRows.isEmpty) {
      SnackbarUtil.showError(
          'Add at least one item with valid qty and cost'.tr);
      return;
    }

    final inputs = validRows
        .map((r) => PurchaseItemInput(
      itemId: r.selectedItem!.id!,
      itemName: r.selectedItem!.name ?? '',
      itemUnit: r.selectedItem!.unit,
      orderedQty: double.parse(r.qtyCtrl.text),
      unitCost: double.parse(r.costCtrl.text),
    ))
        .toList();

    setState(() => _isSaving = true);

    final error = _controller.createPurchase(
      supplierId: _selectedSupplier!.id!,
      supplierName: _selectedSupplier!.name ?? '',
      purchaseDate: _purchaseDate,
      expectedDate: _expectedDate,
      items: inputs,
    );

    setState(() => _isSaving = false);

    if (error != null) {
      SnackbarUtil.showError(error);
      return;
    }

    SnackbarUtil.showSuccess('Purchase order created!'.tr);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade700
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.add_shopping_cart_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('New Purchase Order'.tr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: Purchase Info ──
            MyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                      'Purchase Information'.tr, Icons.info_outline_rounded),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Supplier Dropdown + Add Supplier button
                      Expanded(
                        flex: 2,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: DropdownSearch<EntitySupplier>(
                                selectedItem: _selectedSupplier,
                                items: _suppliers,
                                itemAsString: (s) => s?.name ?? '',
                                popupProps: PopupProps.menu(
                                  showSearchBox: true, // 🔥 THIS ENABLES SEARCH
                                  searchFieldProps: TextFieldProps(
                                    autofocus: true, // ✅ focus search box on first tap
                                    decoration: InputDecoration(
                                      hintText: 'Search supplier...'.tr,
                                      prefixIcon: Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: 'Supplier *'.tr,
                                    prefixIcon: Icon(Icons.local_shipping_rounded),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                onChanged: (val) => setState(() => _selectedSupplier = val),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // ── Add Supplier icon button ──
                            Tooltip(
                              message: 'Add new supplier'.tr,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () async {
                                  if (!Get.isRegistered<ControllerHomeSupplier>()) {
                                    Get.put(ControllerHomeSupplier());
                                  }
                                  await Get.to(
                                          () => const ActivitySupplierForm());
                                  final oldIds =
                                  _suppliers.map((s) => s.id).toSet();
                                  final updated =
                                  _controller.getAllActiveSuppliers();
                                  final newSupplier = updated
                                      .where((s) => !oldIds.contains(s.id))
                                      .firstOrNull;
                                  setState(() {
                                    _suppliers = updated;
                                    if (newSupplier != null) {
                                      _selectedSupplier = newSupplier;
                                    }
                                  });
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.indigo.shade200),
                                  ),
                                  child: Icon(Icons.add_rounded,
                                      size: 20,
                                      color: Colors.indigo.shade600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Purchase Date
                      Expanded(
                        child: InkWell(
                          onTap: _pickPurchaseDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Purchase Date *'.tr,
                              prefixIcon: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 20),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            child: Text(
                              DateFormat('dd MMM yyyy')
                                  .format(_purchaseDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Expected Date
                      Expanded(
                        child: InkWell(
                          onTap: _pickExpectedDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Expected Delivery'.tr,
                              prefixIcon: const Icon(
                                  Icons.event_available_rounded,
                                  size: 20),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            child: Text(
                              _expectedDate != null
                                  ? DateFormat('dd MMM yyyy')
                                  .format(_expectedDate!)
                                  : 'Not set'.tr,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: _expectedDate != null
                                      ? null
                                      : Colors.grey.shade400),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Section 2: Items ──
            MyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _sectionHeader(
                              'Order Items'.tr, Icons.inventory_2_rounded)),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.teal.shade400,
                            Colors.teal.shade700
                          ]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _addRow,
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              child: Row(children: [
                                const Icon(Icons.add_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                Text('Add Item'.tr,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Header row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Expanded(
                          flex: 4,
                          child: Text('Item'.tr,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                  fontSize: 13))),
                      Expanded(
                          flex: 2,
                          child: Text('Qty'.tr,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                  fontSize: 13))),
                      Expanded(
                          flex: 2,
                          child: Text('Unit Cost (₹)'.tr,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                  fontSize: 13))),
                      Expanded(
                          flex: 2,
                          child: Text('Total (₹)'.tr,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                  fontSize: 13))),
                      const SizedBox(width: 36),
                    ]),
                  ),
                  const SizedBox(height: 8),

                  // Item rows
                  ...List.generate(
                    _rows.length,
                        (i) => _buildItemRow(i),
                  ),

                  const Divider(height: 24),

                  // Total footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Total Order Amount:'.tr,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              fontSize: 14)),
                      const SizedBox(width: 12),
                      Text(
                        '₹ ${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.deepPurple),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Action Buttons ──
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                  onPressed: () => Get.back(),
                  child: Text('Cancel'.tr),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.deepPurple.shade400,
                      Colors.deepPurple.shade700
                    ]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSaving ? null : _save,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        child: Row(children: [
                          _isSaving
                              ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.save_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text('Create Purchase Order'.tr,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final row = _rows[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: StatefulBuilder(
        builder: (context, setRowState) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Item Dropdown
            Expanded(
              flex: 4,
              child: DropdownSearch<EntityItem>(
                selectedItem: row.selectedItem,
                items: _items,
                itemAsString: (item) =>
                '${item?.name ?? ''} (${item?.unit ?? ''})',

                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    autofocus: true, // ✅ focus search box on first tap
                    decoration: InputDecoration(
                      hintText: 'Search item...'.tr,
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    hintText: 'Select item'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                ),

                onChanged: (val) {
                  setRowState(() => row.selectedItem = val);
                  if (val?.costPrice != null) {
                    row.costCtrl.text =
                        val!.costPrice!.toStringAsFixed(2);
                  }
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 8),

            // Qty
            Expanded(
              flex: 2,
              child: TextField(
                controller: row.qtyCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '0',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Unit Cost
            Expanded(
              flex: 2,
              child: TextField(
                controller: row.costCtrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Line Total (read-only)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
                ),
                child: Text(
                  '₹ ${((double.tryParse(row.qtyCtrl.text) ?? 0) * (double.tryParse(row.costCtrl.text) ?? 0)).toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.deepPurple),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Remove button
            IconButton(
              onPressed: () => _removeRow(index),
              icon: Icon(Icons.remove_circle_outline_rounded,
                  color: _rows.length > 1
                      ? Colors.red.shade400
                      : Colors.grey.shade300),
              tooltip: 'Remove item'.tr,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 20, color: Colors.deepPurple.shade500),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700)),
    ]);
  }
}

/// Internal state for each item row in the form
class _ItemRow {
  EntityItem? selectedItem;
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController costCtrl = TextEditingController();
}
