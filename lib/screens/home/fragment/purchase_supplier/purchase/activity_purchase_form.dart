import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../../../model/entity_item.dart';
import '../../../../../model/entity_supplier.dart';
import '../../../../../util/snackbar_util.dart';
import '../../../../../widget/app_dialog_components.dart';
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
      SnackbarUtil.showError('Please select a supplier');
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
          'Add at least one item with valid qty and cost');
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

    SnackbarUtil.showSuccess('Purchase order created!');
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialog(
      maxWidth: 950,
      maxHeight: 750,
      header: const DialogHeader(
        title: 'New Purchase Order',
        icon: Icons.add_shopping_cart_rounded,
        iconColor: Colors.deepPurple,
      ),
      body: DialogBody(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 650;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Section 1: Purchase Info ──
                const FormSection(
                  icon: Icons.info_outline_rounded,
                  color: Colors.deepPurple,
                  title: 'Purchase Information',
                ),
                const SizedBox(height: 16),

                if (isWide)
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
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: "Search supplier...",
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: 'Supplier *',
                                    prefixIcon: const Icon(Icons.local_shipping_rounded),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    isDense: true,
                                  ),
                                ),
                                onChanged: (val) => setState(() => _selectedSupplier = val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Add Supplier button
                            Tooltip(
                              message: 'Add new supplier',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () async {
                                  if (!Get.isRegistered<ControllerHomeSupplier>()) {
                                    Get.put(ControllerHomeSupplier());
                                  }
                                  await Get.dialog(
                                    const ActivitySupplierForm(),
                                    barrierDismissible: false,
                                  );
                                  final oldIds = _suppliers.map((s) => s.id).toSet();
                                  final updated = _controller.getAllActiveSuppliers();
                                  final newSupplier = updated.where((s) => !oldIds.contains(s.id)).firstOrNull;
                                  setState(() {
                                    _suppliers = updated;
                                    if (newSupplier != null) {
                                      _selectedSupplier = newSupplier;
                                    }
                                  });
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.indigo.shade200),
                                  ),
                                  child: Icon(Icons.add_rounded, size: 20, color: Colors.indigo.shade600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Purchase Date
                      Expanded(
                        child: AppDatePicker(
                          controller: TextEditingController(text: DateFormat('dd MMM yyyy').format(_purchaseDate)),
                          label: 'Purchase Date *',
                          onTap: _pickPurchaseDate,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Expected Date
                      Expanded(
                        child: AppDatePicker(
                          controller: TextEditingController(
                            text: _expectedDate != null ? DateFormat('dd MMM yyyy').format(_expectedDate!) : '',
                          ),
                          label: 'Expected Delivery',
                          onTap: _pickExpectedDate,
                        ),
                      ),
                    ],
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: DropdownSearch<EntitySupplier>(
                          selectedItem: _selectedSupplier,
                          items: _suppliers,
                          itemAsString: (s) => s?.name ?? '',
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: "Search supplier...",
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: 'Supplier *',
                              prefixIcon: const Icon(Icons.local_shipping_rounded),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              isDense: true,
                            ),
                          ),
                          onChanged: (val) => setState(() => _selectedSupplier = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Add new supplier',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            if (!Get.isRegistered<ControllerHomeSupplier>()) {
                              Get.put(ControllerHomeSupplier());
                            }
                            await Get.dialog(
                              const ActivitySupplierForm(),
                              barrierDismissible: false,
                            );
                            final oldIds = _suppliers.map((s) => s.id).toSet();
                            final updated = _controller.getAllActiveSuppliers();
                            final newSupplier = updated.where((s) => !oldIds.contains(s.id)).firstOrNull;
                            setState(() {
                              _suppliers = updated;
                              if (newSupplier != null) {
                                _selectedSupplier = newSupplier;
                              }
                            });
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.indigo.shade200),
                            ),
                            child: Icon(Icons.add_rounded, size: 20, color: Colors.indigo.shade600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppDatePicker(
                    controller: TextEditingController(text: DateFormat('dd MMM yyyy').format(_purchaseDate)),
                    label: 'Purchase Date *',
                    onTap: _pickPurchaseDate,
                  ),
                  const SizedBox(height: 16),
                  AppDatePicker(
                    controller: TextEditingController(
                      text: _expectedDate != null ? DateFormat('dd MMM yyyy').format(_expectedDate!) : '',
                    ),
                    label: 'Expected Delivery',
                    onTap: _pickExpectedDate,
                  ),
                ],

                const SizedBox(height: 24),

                // ── Section 2: Items ──
                Row(
                  children: [
                    const Expanded(
                      child: FormSection(
                        icon: Icons.inventory_2_rounded,
                        color: Colors.deepPurple,
                        title: 'Order Items',
                      ),
                    ),
                    const SizedBox(width: 8),
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
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.add_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Header row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Item',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Qty',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Unit Cost (₹)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Total (₹)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 44), // matches close button space
                    ],
                  ),
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
                    Text('Total Order Amount:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 14)),
                    const SizedBox(width: 12),
                    Text(
                      '₹ ${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.deepPurple),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      footer: DialogFooter(
        onCancel: () => Get.back(),
        onSave: _save,
        saveLabel: 'Create Purchase Order',
        isSaving: _isSaving,
        saveButtonColor: Colors.deepPurple.shade700,
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
                itemAsString: (item) => '${item?.name ?? ''} (${item?.unit ?? ''})',
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Search item...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    hintText: 'Select item',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                ),
                onChanged: (val) {
                  setRowState(() => row.selectedItem = val);
                  if (val?.costPrice != null) {
                    row.costCtrl.text = val!.costPrice!.toStringAsFixed(2);
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Line Total (read-only)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
                ),
                child: Text(
                  '₹ ${((double.tryParse(row.qtyCtrl.text) ?? 0) * (double.tryParse(row.costCtrl.text) ?? 0)).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.deepPurple),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Remove button
            IconButton(
              onPressed: () => _removeRow(index),
              icon: Icon(Icons.remove_circle_outline_rounded,
                  color: _rows.length > 1 ? Colors.red.shade400 : Colors.grey.shade300),
              tooltip: 'Remove item',
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow {
  EntityItem? selectedItem;
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController costCtrl = TextEditingController();
}
