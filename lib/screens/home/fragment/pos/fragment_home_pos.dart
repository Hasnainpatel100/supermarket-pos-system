import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../model/entity_item.dart';
import '../../../../model/entity_customer.dart';
import 'controller_home_pos.dart';

class FragmentHomePos extends StatelessWidget {
  const FragmentHomePos({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerHomePos());
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: FocusScope(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.f2 ||
                event.logicalKey == LogicalKeyboardKey.f3 ||
                event.logicalKey == LogicalKeyboardKey.f4 ||
                event.logicalKey == LogicalKeyboardKey.f5 ||
                event.logicalKey == LogicalKeyboardKey.delete ||
                (event.logicalKey == LogicalKeyboardKey.keyP &&
                    HardwareKeyboard.instance.isControlPressed) ||
                (event.logicalKey == LogicalKeyboardKey.keyT &&
                    HardwareKeyboard.instance.isControlPressed)) {
              controller.handleShortcut(event.logicalKey);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ── LEFT PANEL (70%) ──
            Expanded(
              flex: 7,
              child: _LeftPanel(controller: controller),
            ),

            /// ── RIGHT PANEL (30%) ──
            Expanded(
              flex: 3,
              child: _RightPanel(controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LEFT PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class _LeftPanel extends StatelessWidget {
  final ControllerHomePos controller;
  const _LeftPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Column(
        children: [
          _TabBar(controller: controller),
          _SearchBar(controller: controller),
          Expanded(child: Obx(() {
            // Force rebuild when active tab changes
            final _ = controller.rxActiveTabIndex.value;
            return _CartDataTable(controller: controller);
          })),
          _ActionBar(controller: controller),
        ],
      ),
    );
  }
}

// ─── Tab Bar ─────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final ControllerHomePos controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              final activeIndex = controller.rxActiveTabIndex.value;
              final tabs = controller.rxBillTabs.toList();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  final session = tabs[index];
                  final isActive = activeIndex == index;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => controller.switchTab(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isActive ? cs.surface : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: isActive ? cs.primary : Colors.transparent,
                              width: 2.5,
                            ),
                            right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 14,
                              color: isActive ? cs.primary : cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              session.id,
                              style: TextStyle(
                                color: isActive ? cs.primary : cs.onSurfaceVariant,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => controller.closeTab(index),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(Icons.close_rounded, size: 14, color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Tooltip(
              message: "New Bill (Ctrl+T)",
              child: TextButton.icon(
                onPressed: controller.addNewTab,
                icon: Icon(Icons.add_rounded, size: 18, color: cs.primary),
                label: Text(
                  "New Bill [Ctrl+T]",
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: cs.primaryContainer.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ──────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final ControllerHomePos controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: RawAutocomplete<EntityItem>(
        textEditingController: controller.searchController,
        focusNode: controller.searchFocusNode,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<EntityItem>.empty();
          }
          final query = textEditingValue.text.toLowerCase();
          return controller.rxListItems.where((item) =>
              (item.name?.toLowerCase().contains(query) ?? false) ||
              (item.sku?.toLowerCase().contains(query) ?? false) ||
              (item.barcode?.toLowerCase().contains(query) ?? false));
        },
        displayStringForOption: (EntityItem option) =>
            "${option.name} | ${option.barcode ?? option.sku ?? ''}",
        onSelected: (EntityItem selection) {
          controller.addToCart(selection);
          // Clear field and keep cursor ready for next scan
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.searchController.clear();
            controller.searchFocusNode.requestFocus();
          });
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              shadowColor: cs.shadow.withValues(alpha: 0.15),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300, maxWidth: 600),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: options.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.search_off_rounded, size: 20, color: cs.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text("No items found", style: TextStyle(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) => Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant.withValues(alpha: 0.2)),
                        itemBuilder: (context, index) {
                          final item = options.elementAt(index);
                          final isHighlighted = AutocompleteHighlightedOption.of(context) == index;
                          return Container(
                            color: isHighlighted
                                ? cs.primaryContainer.withValues(alpha: 0.4)
                                : Colors.transparent,
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: cs.primaryContainer,
                                child: Text(
                                  (item.name ?? '?')[0].toUpperCase(),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
                                ),
                              ),
                              title: Text(item.name ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              subtitle: Text(
                                "Code: ${item.barcode ?? item.sku ?? '-'} • Stock: ${item.totalQty ?? 0}",
                                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                              ),
                              trailing: Text(
                                "₹${(item.sellingPrice ?? 0).toStringAsFixed(2)}",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary),
                              ),
                              onTap: () => onSelected(item),
                            ),
                          );
                        },
                      ),
              ),
            ),
          );
        },
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          return TextField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: "Search by name, code, or barcode…",
              hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: cs.primary, size: 20),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text("Auto-Focus", style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: cs.surfaceContainerHighest,
                  side: BorderSide.none,
                ),
              ),
              filled: true,
              fillColor: cs.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (val) => onFieldSubmitted(),
            onChanged: (val) {
              controller.rxSearchQuery.value = val;
            },
          );
        },
      ),
    );
  }
}

// ─── Cart Data Table ─────────────────────────────────────────────────────────

class _CartDataTable extends StatelessWidget {
  final ControllerHomePos controller;
  const _CartDataTable({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      final session = controller.activeSession;
      if (session.rxCartItems.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shopping_cart_outlined, size: 48, color: cs.primary.withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 16),
              Text(
                "Cart is empty",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                "Search items above to add them to the bill",
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
              ),
            ],
          ),
        );
      }
      return ListView(
        children: [
          DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStateProperty.resolveWith((_) => cs.surfaceContainerHighest),
            headingTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: cs.onSurface, letterSpacing: 0.3),
            dataRowMinHeight: 42,
            dataRowMaxHeight: 48,
            horizontalMargin: 16,
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text("#")),
              DataColumn(label: Text("CODE")),
              DataColumn(label: Text("ITEM NAME")),
              DataColumn(label: Text("QTY"), numeric: true),
              DataColumn(label: Text("UNIT")),
              DataColumn(label: Text("PRICE/UNIT(₹)"), numeric: true),
              DataColumn(label: Text("DISC(₹)"), numeric: true),
              DataColumn(label: Text("TOTAL(₹)"), numeric: true),
            ],
            rows: List.generate(session.rxCartItems.length, (index) {
              final item = session.rxCartItems[index];
              final isSelected = session.rxSelectedCartIndex.value == index;
              final isEven = index.isEven;

              return DataRow(
                selected: isSelected,
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return cs.primaryContainer.withValues(alpha: 0.45);
                  }
                  return isEven ? cs.surfaceContainerLowest : cs.surface;
                }),
                onSelectChanged: (_) {
                  session.rxSelectedCartIndex.value = index;
                },
                cells: [
                  DataCell(Text("${index + 1}", style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12))),
                  DataCell(Text(item.itemBarcode ?? '-', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: cs.onSurfaceVariant))),
                  DataCell(Text(item.itemName ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  DataCell(Text("${item.qty}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary))),
                  DataCell(Text(item.unit ?? '-', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))),
                  DataCell(Text((item.price ?? 0).toStringAsFixed(2), style: const TextStyle(fontSize: 12))),
                  DataCell(Text(
                    (item.discount ?? 0).toStringAsFixed(2),
                    style: TextStyle(fontSize: 12, color: (item.discount ?? 0) > 0 ? Colors.red.shade400 : cs.onSurfaceVariant),
                  )),
                  DataCell(Text(
                    (item.total ?? 0).toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  )),
                ],
              );
            }),
          ),
        ],
      );
    });
  }
}

// ─── Action Bar ──────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final ControllerHomePos controller;
  const _ActionBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _ActionChip(icon: Icons.pin_rounded, label: "Qty [F2]", onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f2)),
          _ActionChip(icon: Icons.discount_outlined, label: "Item Disc [F3]", onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f3)),
          _ActionChip(icon: Icons.delete_outline_rounded, label: "Remove [DEL]", onPressed: () => controller.handleShortcut(LogicalKeyboardKey.delete), isDestructive: true),
          _ActionChip(icon: Icons.percent_rounded, label: "Bill Disc [F4]", onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f4)),
          _ActionChip(icon: Icons.note_alt_outlined, label: "Remarks [F5]", onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f5)),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isDestructive ? Colors.red.shade400 : cs.primary;
    final bgColor = isDestructive ? Colors.red.withValues(alpha: 0.08) : cs.primaryContainer.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RIGHT PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class _RightPanel extends StatelessWidget {
  final ControllerHomePos controller;
  const _RightPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      // Force rebuild when active tab changes
      final _ = controller.rxActiveTabIndex.value;
      return Container(
        color: cs.surfaceContainerLow,
        child: Column(
          children: [
            // ── Date & Customer ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DateBadge(),
                  const SizedBox(height: 14),
                  _CustomerSection(controller: controller),
                ],
              ),
            ),

            // ── Summary ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _SummaryCard(controller: controller),
            ),

            // ── Payment ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: _PaymentSection(controller: controller),
              ),
            ),

            // ── Settle Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: _SettleButtons(controller: controller),
            ),
          ],
        ),
      );
    });
  }
}

// ─── Date Badge ──────────────────────────────────────────────────────────────

class _DateBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 16, color: cs.primary),
          const SizedBox(width: 10),
          Text(
            DateFormat('EEEE, dd MMM yyyy').format(now),
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface),
          ),
          const Spacer(),
          Text(
            DateFormat('hh:mm a').format(now),
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── Customer Section ────────────────────────────────────────────────────────

class _CustomerSection extends StatelessWidget {
  final ControllerHomePos controller;
  const _CustomerSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      final session = controller.activeSession;
      final selected = session.rxSelectedCustomer.value;

      if (selected != null) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primary,
                child: Text(
                  (selected.name ?? '?')[0].toUpperCase(),
                  style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected.name ?? "Unknown",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [selected.phone, selected.city].where((s) => s != null && s.isNotEmpty).join(' • '),
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: cs.onSurfaceVariant),
                onPressed: () => session.rxSelectedCustomer.value = null,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        );
      }

      // Not selected — show autocomplete
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Autocomplete<EntityCustomer>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) return const Iterable<EntityCustomer>.empty();
              return controller.rxListCustomers.where((c) =>
                  (c.name?.toLowerCase().contains(textEditingValue.text.toLowerCase()) ?? false) ||
                  (c.phone?.contains(textEditingValue.text) ?? false));
            },
            displayStringForOption: (EntityCustomer option) => "${option.name} | ${option.phone ?? ''}",
            onSelected: (EntityCustomer selection) {
              session.rxSelectedCustomer.value = selection;
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  shadowColor: cs.shadow.withValues(alpha: 0.15),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 250, maxWidth: 380),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, __) => Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant.withValues(alpha: 0.2)),
                      itemBuilder: (context, index) {
                        final c = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: CircleAvatar(
                            radius: 15,
                            backgroundColor: cs.secondaryContainer,
                            child: Text(
                              (c.name ?? '?')[0].toUpperCase(),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSecondaryContainer),
                            ),
                          ),
                          title: Text(c.name ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          subtitle: Text(c.phone ?? '-', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                          onTap: () => onSelected(c),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
              return TextField(
                controller: textController,
                focusNode: focusNode,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Search customer…",
                  hintStyle: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.person_search_rounded, size: 18, color: cs.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: cs.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: controller.openCustomerForm,
              icon: Icon(Icons.person_add_alt_1_rounded, size: 16, color: cs.primary),
              label: Text("Add New Customer", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ─── Summary Card ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final ControllerHomePos controller;
  const _SummaryCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      final session = controller.activeSession;
      final currency = controller.serviceCurrency.rxCurrency.value;
      int totalItems = session.rxCartItems.length;
      int totalQty = session.rxCartItems.fold(0, (sum, item) => sum + (item.qty ?? 0));

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primaryContainer.withValues(alpha: 0.35), cs.primaryContainer.withValues(alpha: 0.15)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            // Items / Qty summary
            Row(
              children: [
                _SummaryChip(icon: Icons.inventory_2_outlined, label: "$totalItems items", cs: cs),
                const SizedBox(width: 10),
                _SummaryChip(icon: Icons.add_shopping_cart_rounded, label: "$totalQty qty", cs: cs),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
            const SizedBox(height: 12),

            // Subtotal
            _SummaryRow(label: "Subtotal", value: "$currency${session.rxSubTotal.value.toStringAsFixed(2)}", cs: cs),
            if (session.rxTaxAmount.value > 0) ...[
              const SizedBox(height: 6),
              _SummaryRow(label: "Tax", value: "+$currency${session.rxTaxAmount.value.toStringAsFixed(2)}", cs: cs, valueColor: Colors.orange.shade600),
            ],
            if (session.rxDiscountAmount.value > 0) ...[
              const SizedBox(height: 6),
              _SummaryRow(label: "Discount", value: "-$currency${session.rxDiscountAmount.value.toStringAsFixed(2)}", cs: cs, valueColor: Colors.green.shade600),
            ],
            const SizedBox(height: 10),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
            const SizedBox(height: 10),

            // Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Grand Total", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface)),
                Text(
                  "$currency${session.rxGrandTotal.value.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cs.primary),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  const _SummaryChip({required this.icon, required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, required this.cs, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? cs.onSurface)),
      ],
    );
  }
}

// ─── Payment Section ─────────────────────────────────────────────────────────

class _PaymentSection extends StatelessWidget {
  final ControllerHomePos controller;
  const _PaymentSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Payment Mode
        Text("Payment Mode", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Obx(() {
          final session = controller.activeSession;
          return SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Cash', label: Text('Cash'), icon: Icon(Icons.payments_outlined, size: 16)),
              ButtonSegment(value: 'UPI', label: Text('UPI'), icon: Icon(Icons.qr_code_rounded, size: 16)),
              ButtonSegment(value: 'Card', label: Text('Card'), icon: Icon(Icons.credit_card_rounded, size: 16)),
              ButtonSegment(value: 'Split', label: Text('Split'), icon: Icon(Icons.call_split_rounded, size: 16)),
            ],
            selected: {session.rxPaymentMode.value},
            onSelectionChanged: (selected) {
              session.rxPaymentMode.value = selected.first;
              if (selected.first == 'Split') {
                session.initSplitPayment(2, session.rxGrandTotal.value);
              }
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              padding: WidgetStatePropertyAll(const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          );
        }),

        const SizedBox(height: 16),

        // Split Payment Section
        Obx(() {
          final session = controller.activeSession;
          if (session.rxPaymentMode.value != 'Split') return const SizedBox.shrink();
          
          return _SplitPaymentSection(controller: controller);
        }),

        // Amount Received (hidden when Split mode)
        Obx(() {
          final session = controller.activeSession;
          if (session.rxPaymentMode.value == 'Split') return const SizedBox.shrink();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Amount Received", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              TextField(
                controller: session.amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixText: "${controller.serviceCurrency.rxCurrency.value} ",
                  prefixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.primary),
                  filled: true,
                  fillColor: cs.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                onChanged: controller.onAmountChanged,
              ),
            ],
          );
        }),

        const Spacer(),

        // Due / Change
        Obx(() {
          final session = controller.activeSession;
          final currency = controller.serviceCurrency.rxCurrency.value;
          final isDue = session.rxDueAmount.value > 0;
          final amount = isDue ? session.rxDueAmount.value : session.rxChangeReturned.value;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDue ? Colors.orange.withValues(alpha: 0.08) : Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDue ? Colors.orange.withValues(alpha: 0.25) : Colors.green.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDue ? Colors.orange : Colors.green).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDue ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: isDue ? Colors.orange.shade700 : Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDue ? "Amount Due" : "Change to Return",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDue ? Colors.orange.shade700 : Colors.green.shade700),
                      ),
                      Text(
                        "$currency${amount.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDue ? Colors.orange.shade800 : Colors.green.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Settle Buttons ──────────────────────────────────────────────────────────

class _SettleButtons extends StatelessWidget {
  final ControllerHomePos controller;
  const _SettleButtons({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade500, Colors.green.shade700],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.green.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: controller.settleBill,
            icon: const Icon(Icons.print_rounded, size: 18, color: Colors.white),
            label: const Text(
              "Save & Print Bill [Ctrl+P]",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {},
          icon: Icon(Icons.account_balance_wallet_outlined, size: 16, color: cs.primary),
          label: Text(
            "Other / Credit Payments",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
        ),
      ],
    );
  }
}

// ─── Split Payment Section ───────────────────────────────────────────────────

class _SplitPaymentSection extends StatelessWidget {
  final ControllerHomePos controller;
  const _SplitPaymentSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = controller.activeSession;
    final currency = controller.serviceCurrency.rxCurrency.value;

    return Obx(() {
      final splitCount = session.rxSplitCount.value;
      final grandTotal = session.rxGrandTotal.value;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Split count selector
          Row(
            children: [
              Text("Split between", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: cs.onSurfaceVariant)),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: splitCount > 2 ? () {
                        session.initSplitPayment(splitCount - 1, grandTotal);
                      } : null,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("$splitCount", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cs.primary)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: splitCount < 10 ? () {
                        session.initSplitPayment(splitCount + 1, grandTotal);
                      } : null,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Split entries
          ...List.generate(splitCount, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Person ${index + 1}", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Amount field
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: session.splitControllers[index],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              prefixText: "$currency ",
                              prefixStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary),
                              filled: true,
                              fillColor: cs.surfaceContainerLow,
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            onChanged: (val) {
                              final amount = double.tryParse(val) ?? 0;
                              session.updateSplitAmount(index, amount);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Payment mode dropdown
                        Expanded(
                          flex: 2,
                          child: Obx(() => DropdownButtonFormField<String>(
                            value: session.rxSplitModes[index].value,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: cs.surfaceContainerLow,
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Cash', child: Text('Cash', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'UPI', child: Text('UPI', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Card', child: Text('Card', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) {
                              if (val != null) session.updateSplitMode(index, val);
                            },
                          )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          
          // Total check
          Obx(() {
            double totalSplit = 0;
            for (var rx in session.rxSplitAmounts) {
              totalSplit += rx.value;
            }
            final diff = grandTotal - totalSplit;
            final isValid = diff.abs() < 0.01;
            
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isValid ? Colors.green.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isValid ? "Split amounts match total" : "Difference: $currency${diff.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isValid ? Colors.green.shade700 : Colors.red.shade700),
                  ),
                  Text(
                    "Total: $currency${totalSplit.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      );
    });
  }
}
