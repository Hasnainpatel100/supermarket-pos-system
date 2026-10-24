import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../model/entity_item.dart';
import '../../../../model/entity_item_batch.dart';

/// Stock Data / Batch Selection Dialog
/// Displays available batches for an item matching Photo 1.
/// Supports ArrowUp, ArrowDown, PageUp, PageDown, and Enter keyboard navigation.
class DialogSelectBatch extends StatefulWidget {
  final EntityItem item;
  final List<EntityItemBatch> batches;
  final ValueChanged<EntityItemBatch> onBatchSelected;

  const DialogSelectBatch({
    super.key,
    required this.item,
    required this.batches,
    required this.onBatchSelected,
  });

  static Future<EntityItemBatch?> show(
    BuildContext context, {
    required EntityItem item,
    required List<EntityItemBatch> batches,
    required ValueChanged<EntityItemBatch> onBatchSelected,
  }) {
    return Get.dialog<EntityItemBatch>(
      DialogSelectBatch(
        item: item,
        batches: batches,
        onBatchSelected: onBatchSelected,
      ),
      barrierDismissible: true,
    );
  }

  @override
  State<DialogSelectBatch> createState() => _DialogSelectBatchState();
}

class _DialogSelectBatchState extends State<DialogSelectBatch> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<EntityItemBatch> get _batches =>
      widget.batches.where((b) => (b.quantity ?? 0) > 0).toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectCurrent() {
    final list = _batches;
    if (list.isNotEmpty &&
        _selectedIndex >= 0 &&
        _selectedIndex < list.length) {
      final selectedBatch = list[_selectedIndex];
      Get.back();
      widget.onBatchSelected(selectedBatch);
    }
  }

  void _navigate(int delta) {
    final list = _batches;
    if (list.isEmpty) return;
    setState(() {
      _selectedIndex =
          (_selectedIndex + delta).clamp(0, list.length - 1);
    });
    _scrollToSelected();
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    const itemHeight = 44.0;
    final targetOffset = _selectedIndex * itemHeight;
    if (targetOffset < _scrollController.offset) {
      _scrollController.jumpTo(targetOffset);
    } else if (targetOffset + itemHeight >
        _scrollController.offset + _scrollController.position.viewportDimension) {
      _scrollController.jumpTo(
        targetOffset +
            itemHeight -
            _scrollController.position.viewportDimension,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd-MM-yyyy');

    final double gstRate = widget.item.taxRate ?? 0.0;
    final double cgstRate = gstRate / 2.0;
    final double sgstRate = gstRate / 2.0;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.pageDown) {
            _navigate(1);
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.pageUp) {
            _navigate(-1);
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter) {
            _selectCurrent();
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.escape) {
            Get.back();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 1220,
          constraints: const BoxConstraints(maxWidth: 1240, maxHeight: 540),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Bar ("Stock Data") ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_rounded,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Stock Data — Select Batch for: ${widget.item.name ?? "Item"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Use ↑ ↓ PgUp PgDn + ENTER to select',
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      onPressed: () => Get.back(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              // ── Batches Table matching Photo 1 ──
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1180,
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          height: 40,
                          color: const Color(0xFF0F172A),
                          child: const Row(
                            children: [
                              _TableHeaderCell('Product Code', width: 95),
                              _TableHeaderCell('Product Name', width: 170),
                              _TableHeaderCell('HSN Code', width: 75),
                              _TableHeaderCell('Batch No.', width: 85),
                              _TableHeaderCell('Purchase Rate', width: 95),
                              _TableHeaderCell('Sales Rate', width: 90),
                              _TableHeaderCell('Discount', width: 75),
                              _TableHeaderCell('CGST %', width: 70),
                              _TableHeaderCell('SGST %', width: 70),
                              _TableHeaderCell('Expiry Date', width: 95),
                              _TableHeaderCell('Qty. Avail', width: 85),
                              _TableHeaderCell('MRP', width: 80),
                              _TableHeaderCell('Barcode', width: 95),
                            ],
                          ),
                        ),

                        // Table Body
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _batches.length,
                            itemBuilder: (context, index) {
                              final batch = _batches[index];
                              final isSelected = index == _selectedIndex;

                              final purchaseRate = batch.costPrice ?? widget.item.costPrice ?? 0.0;
                              final salesRate = batch.salePrice ?? widget.item.sellingPrice ?? 0.0;
                              final mrp = batch.mrp ?? widget.item.sellingPrice ?? 0.0;
                              final discount = batch.discount ?? 0.0;
                              final qtyAvail = batch.quantity ?? 0;

                              final expiryStr = batch.expiryDateUtcMs != null
                                  ? dateFormat.format(DateTime.fromMillisecondsSinceEpoch(
                                      batch.expiryDateUtcMs!,
                                      isUtc: true,
                                    ).toLocal())
                                  : '-';

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                  _selectCurrent();
                                },
                                onHover: (hovered) {
                                  if (hovered && _selectedIndex != index) {
                                    setState(() {
                                      _selectedIndex = index;
                                    });
                                  }
                                },
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFEF3C7) // Golden highlight as in Photo 1
                                        : (index.isOdd
                                            ? cs.surfaceContainerHighest.withValues(alpha: 0.2)
                                            : Colors.transparent),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: cs.outlineVariant.withValues(alpha: 0.25),
                                        width: 0.8,
                                      ),
                                      left: isSelected
                                          ? const BorderSide(color: Color(0xFFD97706), width: 4)
                                          : BorderSide.none,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _TableCell(
                                        widget.item.sku ?? 'P-${(widget.item.id ?? 0).toString().padLeft(4, '0')}',
                                        width: isSelected ? 91 : 95,
                                        isBold: true,
                                        color: isSelected ? const Color(0xFF78350F) : null,
                                      ),
                                      _TableCell(
                                        widget.item.name ?? '-',
                                        width: 170,
                                        color: isSelected ? const Color(0xFF78350F) : null,
                                      ),
                                      _TableCell(
                                        widget.item.hsnCode ?? '-',
                                        width: 75,
                                        color: isSelected ? const Color(0xFF78350F) : null,
                                      ),
                                      _TableCell(
                                        batch.batchNo ?? '-',
                                        width: 85,
                                        isBold: true,
                                        color: isSelected ? const Color(0xFF92400E) : Colors.blue.shade800,
                                      ),
                                      _TableCell(
                                        purchaseRate.toStringAsFixed(2),
                                        width: 95,
                                        align: TextAlign.right,
                                        color: isSelected ? const Color(0xFF78350F) : null,
                                      ),
                                      _TableCell(
                                        salesRate.toStringAsFixed(2),
                                        width: 90,
                                        align: TextAlign.right,
                                        isBold: true,
                                        color: isSelected ? const Color(0xFF047857) : Colors.teal.shade800,
                                      ),
                                      _TableCell(
                                        discount.toStringAsFixed(2),
                                        width: 75,
                                        align: TextAlign.right,
                                        color: isSelected ? const Color(0xFF78350F) : null,
                                      ),
                                      _TableCell(
                                        cgstRate.toStringAsFixed(1),
                                        width: 70,
                                        align: TextAlign.right,
                                        color: isSelected ? const Color(0xFF78350F) : null,
                                      ),
                                      _TableCell(
                                        sgstRate.toStringAsFixed(1),
                                        width: 70,
                                        align: TextAlign.right,
                                        color: isSelected ? const Color(0xFF78350F) : null,
                                      ),
                                      _TableCell(
                                        expiryStr,
                                        width: 95,
                                        align: TextAlign.center,
                                        color: isSelected ? const Color(0xFF78350F) : null,
                                      ),
                                      _TableCell(
                                        qtyAvail.toStringAsFixed(2),
                                        width: 85,
                                        align: TextAlign.right,
                                        isBold: true,
                                        color: qtyAvail <= 0
                                            ? Colors.red
                                            : (isSelected ? const Color(0xFF78350F) : null),
                                      ),
                                      _TableCell(
                                        mrp.toStringAsFixed(2),
                                        width: 80,
                                        align: TextAlign.right,
                                        color: isSelected ? const Color(0xFF78350F) : null,
                                      ),
                                      _TableCell(
                                        batch.barcode ?? widget.item.barcode ?? '-',
                                        width: 95,
                                        color: isSelected ? const Color(0xFF78350F) : null,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Footer Bar ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Batches: ${widget.batches.length}  •  Press [Enter] to select batch into cart',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel (Esc)'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _selectCurrent,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Select Batch (Enter)'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00796B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  final double width;

  const _TableHeaderCell(this.text, {required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final double width;
  final bool isBold;
  final TextAlign align;
  final Color? color;

  const _TableCell(
    this.text, {
    required this.width,
    this.isBold = false,
    this.align = TextAlign.left,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
