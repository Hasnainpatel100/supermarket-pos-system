import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../model/entity_item.dart';
import '../../../../model/entity_customer.dart';
import '../../../../util/snackbar_util.dart';
import '../account/controller_home_account.dart';
import '../account/dialog_start_day_shift.dart';
import 'activity_split_bill.dart';
import 'controller_home_pos.dart';

class FragmentHomePos extends StatelessWidget {
  const FragmentHomePos({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerHomeAccount accountCtrl = Get.isRegistered<ControllerHomeAccount>()
        ? Get.find<ControllerHomeAccount>()
        : Get.put(ControllerHomeAccount(), permanent: true);

    return Obx(() {
      if (!accountCtrl.isShiftOpen) {
        final bool isDayOpen = accountCtrl.isDayOpen;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    color: Color(0xFFF59E0B),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isDayOpen ? 'Shift Not Started' : 'Day & Shift Not Started',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  isDayOpen
                      ? 'You must start your shift before taking orders, collecting payments, and dispensing change.'
                      : 'The business day has not been started yet. You must start the day and your shift before operating the POS terminal.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    DialogStartDayShift.show(context, isShiftOnly: isDayOpen);
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text(
                    isDayOpen ? 'Start Shift' : 'Start Day & Shift',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        );
      }

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
              /// ── LEFT PANEL (65%): ITEM LIST & CATALOG ──
              Expanded(
                flex: 65,
                child: Obx(() {
                  if (controller.rxViewMode.value == PosViewMode.catalogGrid ||
                      controller.rxViewMode.value == PosViewMode.photoGrid) {
                    return _CatalogLeftPanel(controller: controller);
                  }
                  return _LeftPanel(controller: controller);
                }),
              ),

              /// ── RIGHT PANEL (35%): SELECTED ITEM DETAILS & BILLING ──
              Expanded(
                flex: 35,
                child: Obx(() {
                  if (controller.rxViewMode.value == PosViewMode.catalogGrid ||
                      controller.rxViewMode.value == PosViewMode.photoGrid) {
                    return _CatalogSelectedItemsPanel(controller: controller);
                  }
                  return _RightPanel(controller: controller);
                }),
              ),
            ],
          ),
        ),
      );
    });
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
              message: 'new_bill_ctrl_t'.tr,
              child: TextButton.icon(
                onPressed: controller.addNewTab,
                icon: Icon(Icons.add_rounded, size: 18, color: cs.primary),
                label: Text(
                  'new_bill_ctrl_t'.tr,
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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _ViewModeSwitcherButton(controller: controller),
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
          return controller.searchOptions(textEditingValue.text);
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
                            Text('no_items_found'.tr, style: TextStyle(color: cs.onSurfaceVariant)),
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
              hintText: 'search_name_code_barcode'.tr,
              hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: cs.primary, size: 20),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text('auto_focus'.tr, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
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
                'cart_is_empty'.tr,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                'search_items_to_add'.tr,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
              ),
            ],
          ),
        );
      }
      return RepaintBoundary(
        child: ListView(
          children: [
            DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStateProperty.resolveWith((_) => cs.surfaceContainerHighest),
            headingTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: cs.onSurface, letterSpacing: 0.3),
            dataRowMinHeight: 42,
            dataRowMaxHeight: 48,
            horizontalMargin: 16,
            columnSpacing: 20,
            columns: [
              DataColumn(label: Text('col_hash'.tr)),
              DataColumn(label: Text('col_code'.tr)),
              DataColumn(label: Text('col_item_name'.tr)),
              DataColumn(label: Text('col_qty'.tr), numeric: true),
              DataColumn(label: Text('col_unit'.tr)),
              DataColumn(label: Text('col_price_unit'.tr), numeric: true),
              DataColumn(label: Text('col_disc'.tr), numeric: true),
              DataColumn(label: Text('col_total'.tr), numeric: true),
              const DataColumn(label: Text("")),
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
                  DataCell(
                    InkWell(
                      onTap: () => controller.handleShortcut(LogicalKeyboardKey.f2),
                      child: Text("${item.qty}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
                    ),
                  ),
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
                  DataCell(
                    InkWell(
                      onTap: () {
                        controller.removeFromCart(index);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
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
          _ActionChip(icon: Icons.pin_rounded, label: 'qty_f2'.tr, onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f2)),
          _ActionChip(icon: Icons.discount_outlined, label: 'item_disc_f3'.tr, onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f3)),
          _ActionChip(icon: Icons.delete_outline_rounded, label: 'remove_del'.tr, onPressed: () => controller.handleShortcut(LogicalKeyboardKey.delete), isDestructive: true),
          _ActionChip(icon: Icons.percent_rounded, label: 'bill_disc_f4'.tr, onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f4)),
          _ActionChip(icon: Icons.note_alt_outlined, label: 'remarks_f5'.tr, onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f5)),
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
              child: RepaintBoundary(
                child: _SummaryCard(controller: controller),
              ),
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
                      selected.name ?? 'unknown'.tr,
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

      // Not selected — show quick entry + autocomplete
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Autocomplete<EntityCustomer>(
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
                        hintText: 'search_customer_hint'.tr,
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
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: controller.openCustomerForm,
                icon: const Icon(Icons.add_rounded, size: 20),
                tooltip: 'full_customer_form'.tr,
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick Entry Fields
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'customer_name'.tr,
                    labelStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) => session.rxQuickCustomerName.value = val,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  style: const TextStyle(fontSize: 12),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'phone_number'.tr,
                    labelStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) => session.rxQuickCustomerPhone.value = val,
                ),
              ),
            ],
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
                _SummaryChip(icon: Icons.inventory_2_outlined, label: "$totalItems ${'items_label'.tr}", cs: cs),
                const SizedBox(width: 10),
                _SummaryChip(icon: Icons.add_shopping_cart_rounded, label: "$totalQty ${'qty_label'.tr}", cs: cs),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
            const SizedBox(height: 12),

            // Subtotal
            _SummaryRow(label: 'subtotal'.tr, value: "$currency${session.rxSubTotal.value.toStringAsFixed(2)}", cs: cs),
            if (session.rxTaxAmount.value > 0) ...[
              const SizedBox(height: 6),
              _SummaryRow(label: 'tax'.tr, value: "+$currency${session.rxTaxAmount.value.toStringAsFixed(2)}", cs: cs, valueColor: Colors.orange.shade600),
            ],
            if (session.rxDiscountAmount.value > 0) ...[
              const SizedBox(height: 6),
              _SummaryRow(label: 'discount'.tr, value: "-$currency${session.rxDiscountAmount.value.toStringAsFixed(2)}", cs: cs, valueColor: Colors.green.shade600),
            ],
            const SizedBox(height: 10),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
            const SizedBox(height: 10),

            // Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('grand_total'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface)),
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
        Text('payment_mode'.tr, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Obx(() {
          final session = controller.activeSession;
          return SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'Cash', label: Text('cash'.tr), icon: const Icon(Icons.payments_outlined, size: 16)),
              ButtonSegment(value: 'UPI', label: Text('upi'.tr), icon: const Icon(Icons.qr_code_rounded, size: 16)),
              ButtonSegment(value: 'Split', label: Text('split'.tr), icon: const Icon(Icons.call_split_rounded, size: 16)),
            ],
            selected: {session.rxPaymentMode.value},
            onSelectionChanged: (selected) {
              if (selected.first == 'Split') {
                if (session.rxCartItems.isEmpty) {
                  Get.snackbar('cart_empty_title'.tr, 'add_items_before_split'.tr,
                      snackPosition: SnackPosition.TOP);
                  return;
                }
                Get.dialog(
                  const ActivitySplitBill(),
                  barrierDismissible: false,
                );
                return;
              }
              session.rxPaymentMode.value = selected.first;
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


        // Amount Received (hidden when Split mode)
        Obx(() {
          final session = controller.activeSession;
          if (session.rxPaymentMode.value == 'Split') return const SizedBox.shrink();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('amount_received'.tr, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: cs.onSurfaceVariant)),
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
                        isDue ? 'amount_due'.tr : 'change_to_return'.tr,
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
            label: Text(
              'save_print_bill'.tr,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
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
            'other_credit_payments'.tr,
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

class SplitPaymentSection extends StatelessWidget {
  final ControllerHomePos controller;
  const SplitPaymentSection({super.key, required this.controller});

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
              Text('split_between'.tr, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: cs.onSurfaceVariant)),
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
                    Text("${'person_n'.trParams({'n': '${index + 1}'})}", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: cs.onSurfaceVariant)),
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
                            items:[
                              DropdownMenuItem(value: 'Cash', child: Text('cash'.tr, style: const TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'UPI', child: Text('upi'.tr, style: const TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'Card', child: Text('card'.tr, style: const TextStyle(fontSize: 12))),
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
                    isValid ? 'split_amounts_match'.tr : "${'difference_amount'.trParams({'currency': currency, 'amount': diff.toStringAsFixed(2)})}",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isValid ? Colors.green.shade700 : Colors.red.shade700),
                  ),
                  Text(
                    "${'total_split'.trParams({'currency': currency, 'amount': totalSplit.toStringAsFixed(2)})}",
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

// ═══════════════════════════════════════════════════════════════════════════════
// ALTERNATE VIEW OPTION: PHOTO CATALOG GRID WITH CATEGORY SIDEBAR
// ═══════════════════════════════════════════════════════════════════════════════

class _CatalogLeftPanel extends StatelessWidget {
  final ControllerHomePos controller;
  const _CatalogLeftPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          right: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category Sidebar on Left ──
          _CategorySidebar(controller: controller),

          // ── Main Catalog Grid Area on Right ──
          Expanded(
            child: Container(
              color: cs.surfaceContainerLowest,
              child: Column(
                children: [
                  _CatalogHeaderBar(controller: controller),
                  Expanded(
                    child: Obx(() {
                      if (controller.rxListItems.isEmpty) {
                        return _CatalogEmptyState(controller: controller);
                      }
                      if (controller.rxViewMode.value == PosViewMode.photoGrid) {
                        return _FoodPhotoCardGrid(controller: controller);
                      }
                      return _MarketCatalogGrid(controller: controller);
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Sidebar (Matching Photo) ───────────────────────────────────────

class _CategorySidebar extends StatelessWidget {
  final ControllerHomePos controller;
  const _CategorySidebar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 145,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          right: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header: Category Icon + "categories"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 17,
                  color: const Color(0xFF005963),
                ),
                const SizedBox(width: 8),
                const Text(
                  'categories',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Color(0xFF005963),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // Category List
          Expanded(
            child: Obx(() {
              final categories = controller.rxCategories.toList();
              final selected = controller.rxSelectedCategory.value;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected =
                      cat.toLowerCase() == selected.toLowerCase();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.5),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => controller.selectCategory(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF005963)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            cat,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : cs.onSurface.withValues(alpha: 0.85),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Catalog Header Bar (Search & View Switcher Only) ────────────────────────

class _CatalogHeaderBar extends StatelessWidget {
  final ControllerHomePos controller;
  const _CatalogHeaderBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Search Input
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: controller.searchController,
                focusNode: controller.searchFocusNode,
                onChanged: (val) => controller.rxSearchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'search_item_hint'.tr.isEmpty
                      ? 'Search Items...'
                      : 'search_item_hint'.tr,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 19,
                    color: cs.primary,
                  ),
                  suffixIcon: Obx(() {
                    if (controller.rxSearchQuery.value.isNotEmpty) {
                      return IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          controller.searchController.clear();
                          controller.rxSearchQuery.value = '';
                          controller.loadItems();
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Alternate View Switcher
          _ViewModeSwitcherButton(controller: controller),
        ],
      ),
    );
  }
}

// ─── Market Catalog Grid (Matching Photo Cards) ─────────────────────────────

class _MarketCatalogGrid extends StatelessWidget {
  final ControllerHomePos controller;
  const _MarketCatalogGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsively allocate 2 to 4 columns based on width
        final colCount = (constraints.maxWidth / 240).floor().clamp(2, 4);

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: colCount,
            childAspectRatio: 2.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: controller.rxListItems.length,
          itemBuilder: (context, index) {
            final item = controller.rxListItems[index];
            return _MarketCatalogCard(
              item: item,
              onTap: () => controller.addToCart(item),
            );
          },
        );
      },
    );
  }
}

// ─── Market Catalog Card (Matching Photo) ───────────────────────────────────

class _MarketCatalogCard extends StatelessWidget {
  final EntityItem item;
  final VoidCallback onTap;

  const _MarketCatalogCard({
    required this.item,
    required this.onTap,
  });

  String _getItemSku() {
    if (item.barcode != null && item.barcode!.isNotEmpty) {
      return item.barcode!;
    }
    return 'SKU${item.id.toString().padLeft(4, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sku = _getItemSku();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color(0xFF005963).withValues(alpha: 0.05),
        splashColor: const Color(0xFF005963).withValues(alpha: 0.12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 3,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Squarish Teal Icon Container with Green Corner Indicator
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B8F9A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 22,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    // Small Green Dot in Top-Right Corner
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Title and SKU Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name ?? 'Item',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F0F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sku,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005963),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Price in Bold Teal
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  '₹${(item.sellingPrice ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF007580),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State for Catalog ────────────────────────────────────────────────

class _CatalogEmptyState extends StatelessWidget {
  final ControllerHomePos controller;
  const _CatalogEmptyState({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 52,
            color: cs.onSurfaceVariant.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            'No items found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Category: ${controller.rxSelectedCategory.value}',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              controller.selectCategory('All');
              controller.searchController.clear();
              controller.rxSearchQuery.value = '';
              controller.loadItems();
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Show All Items'),
          ),
        ],
      ),
    );
  }
}

// ─── Food Photo Card Grid (3rd View Feature with Background Images) ──────────

class _FoodPhotoCardGrid extends StatelessWidget {
  final ControllerHomePos controller;
  const _FoodPhotoCardGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Allocate 2 to 6 columns based on available 65% width
        // ~175px minimum per card to fit photo + SKU + veg dot + title + price
        final colCount = (constraints.maxWidth / 175).floor().clamp(2, 6);

        return Obx(() {
          final items = controller.rxListItems.toList();
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: colCount,
              childAspectRatio: 0.80,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _FoodPhotoCard(
                item: item,
                controller: controller,
                onTap: () => controller.addToCart(item),
              );
            },
          );
        });
      },
    );
  }
}

// ─── Food Photo Card ─────────────────────────────────────────────────────────

class _FoodPhotoCard extends StatefulWidget {
  final EntityItem item;
  final ControllerHomePos controller;
  final VoidCallback onTap;

  const _FoodPhotoCard({
    required this.item,
    required this.controller,
    required this.onTap,
  });

  @override
  State<_FoodPhotoCard> createState() => _FoodPhotoCardState();
}

class _FoodPhotoCardState extends State<_FoodPhotoCard> {
  bool _isHovered = false;

  String _getItemSku() {
    if (widget.item.barcode != null && widget.item.barcode!.isNotEmpty) {
      return widget.item.barcode!;
    }
    if (widget.item.sku != null && widget.item.sku!.isNotEmpty) {
      return widget.item.sku!;
    }
    return 'F${(widget.item.id ?? 0).toString().padLeft(3, '0')}';
  }

  bool _isVeg() {
    final name = (widget.item.name ?? '').toLowerCase();
    final cat = (widget.item.category ?? '').toLowerCase();
    const nonVegWords = [
      'chicken', 'mutton', 'beef', 'pork', 'fish', 'prawn', 'shrimp',
      'crab', 'meat', 'egg', 'seafood', 'bacon', 'ham', 'lamb', 'duck',
      'satay', 'empanada', 'tempura'
    ];
    for (final w in nonVegWords) {
      if (name.contains(w) || cat.contains(w)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sku = _getItemSku();
    final isVeg = _isVeg();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFF005963).withValues(alpha: 0.6)
                : cs.outlineVariant.withValues(alpha: 0.4),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.03),
              blurRadius: _isHovered ? 10 : 4,
              offset: Offset(0, _isHovered ? 3 : 1.5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              splashColor: const Color(0xFF005963).withValues(alpha: 0.12),
              hoverColor: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Upper Section: Image / Background Dish Container ──
                  Expanded(
                    flex: 12,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image or default teal culinary container
                        Obx(() {
                          final imgPath = widget.controller.getItemImage(widget.item.id);
                          return _buildImageBackground(imgPath);
                        }),

                        // Top-Left Pill Badge: SKU / Item Code
                        Positioned(
                          top: 7,
                          left: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sku,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),

                        // Top-Right: Veg / Non-Veg Square Indicator Badge
                        Positioned(
                          top: 7,
                          right: 7,
                          child: _VegBadge(isVeg: isVeg),
                        ),

                        // Bottom-Right: Camera / Image Upload Icon Button
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Tooltip(
                            message: 'Set Card Image',
                            child: Material(
                              color: Colors.black.withValues(alpha: _isHovered ? 0.65 : 0.35),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _showImageUploadDialog(context, widget.item, widget.controller),
                                child: const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Lower Section: Item Name & Teal Bold Price ──
                  Expanded(
                    flex: 9,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.item.name ?? 'Item',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                              height: 1.2,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${widget.controller.serviceCurrency.rxCurrency.value}${(widget.item.sellingPrice ?? 0.0).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF005963),
                                ),
                              ),
                              if (widget.item.totalQty != null && widget.item.totalQty! > 0)
                                Text(
                                  '${widget.item.totalQty}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageBackground(String? imgPath) {
    if (imgPath != null && imgPath.trim().isNotEmpty) {
      final trimmed = imgPath.trim();
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return Image.network(
          trimmed,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _fallbackTealContainer(),
        );
      } else {
        final file = File(trimmed);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => _fallbackTealContainer(),
          );
        }
      }
    }
    return _fallbackTealContainer();
  }

  Widget _fallbackTealContainer() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF53949D), Color(0xFF45838B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.soup_kitchen_rounded,
          size: 42,
          color: Colors.white.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

// ─── Veg / Non-Veg Dot Badge ────────────────────────────────────────────────

class _VegBadge extends StatelessWidget {
  final bool isVeg;
  const _VegBadge({required this.isVeg});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ─── Image Upload Dialog (Directly Add/Change Background Image) ──────────────

void _showImageUploadDialog(
  BuildContext context,
  EntityItem item,
  ControllerHomePos controller,
) {
  final cs = Theme.of(context).colorScheme;
  final urlController = TextEditingController();
  final currentImg = controller.getItemImage(item.id);
  if (currentImg != null &&
      (currentImg.startsWith('http://') || currentImg.startsWith('https://'))) {
    urlController.text = currentImg;
  }

  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005963).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: Color(0xFF005963),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set Card Background Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.name ?? 'Item',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Option 1: File Picker from Computer
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005963),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.upload_file_rounded, size: 19),
                label: const Text(
                  'Choose Image from Computer',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () async {
                  Get.back();
                  if (item.id != null) {
                    await controller.pickAndSetItemImage(item.id!);
                  }
                },
              ),
            ),
            const SizedBox(height: 14),

            // Divider "OR"
            Row(
              children: [
                Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'OR PASTE WEB URL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5))),
              ],
            ),
            const SizedBox(height: 14),

            // Option 2: Image URL input
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: urlController,
                      decoration: InputDecoration(
                        hintText: 'https://example.com/food.jpg',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        prefixIcon: const Icon(Icons.link_rounded, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005963),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final url = urlController.text.trim();
                      if (url.isNotEmpty && item.id != null) {
                        await controller.setItemImage(item.id!, url);
                        Get.back();
                        SnackbarUtil.showSuccess('Card background image updated successfully');
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),

            if (currentImg != null && currentImg.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Remove Custom Image'),
                  onPressed: () async {
                    if (item.id != null) {
                      await controller.removeItemImage(item.id!);
                      Get.back();
                      SnackbarUtil.showInfo('Reverted to default card background');
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

// ─── View Mode Switcher Button ───────────────────────────────────────────────

class _ViewModeSwitcherButton extends StatelessWidget {
  final ControllerHomePos controller;
  const _ViewModeSwitcherButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Obx(() {
      final currentMode = controller.rxViewMode.value;
      final tooltip = controller.nextViewModeTooltip;
      final icon = controller.currentViewModeIcon;

      return Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: PopupMenuButton<PosViewMode>(
            initialValue: currentMode,
            tooltip: tooltip,
            onSelected: (mode) => controller.setViewMode(mode),
            offset: const Offset(0, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: PosViewMode.classicTable,
                child: Row(
                  children: [
                    Icon(
                      Icons.table_chart_rounded,
                      size: 18,
                      color: currentMode == PosViewMode.classicTable
                          ? const Color(0xFF005963)
                          : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '1. Table View (Scanner & List)',
                      style: TextStyle(
                        fontWeight: currentMode == PosViewMode.classicTable
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: currentMode == PosViewMode.classicTable
                            ? const Color(0xFF005963)
                            : cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: PosViewMode.catalogGrid,
                child: Row(
                  children: [
                    Icon(
                      Icons.view_compact_rounded,
                      size: 18,
                      color: currentMode == PosViewMode.catalogGrid
                          ? const Color(0xFF005963)
                          : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '2. Compact Cards View',
                      style: TextStyle(
                        fontWeight: currentMode == PosViewMode.catalogGrid
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: currentMode == PosViewMode.catalogGrid
                            ? const Color(0xFF005963)
                            : cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: PosViewMode.photoGrid,
                child: Row(
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 18,
                      color: currentMode == PosViewMode.photoGrid
                          ? const Color(0xFF005963)
                          : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '3. Photo Cards View (Images)',
                      style: TextStyle(
                        fontWeight: currentMode == PosViewMode.photoGrid
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: currentMode == PosViewMode.photoGrid
                            ? const Color(0xFF005963)
                            : cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF005963).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF005963).withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: const Color(0xFF005963),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 35% RIGHT PANEL: SELECTED ITEM DETAILS & BILLING IN CATALOG VIEW
// ═══════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════════
// 35% RIGHT PANEL: MODERN & ATTRACTIVE CART & BILLING PANEL
// ═══════════════════════════════════════════════════════════════════════════════

class _CatalogSelectedItemsPanel extends StatelessWidget {
  final ControllerHomePos controller;
  const _CatalogSelectedItemsPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Obx(() {
      final session = controller.activeSession;
      final cartItems = session.rxCartItems.toList();
      final grandTotal = session.rxGrandTotal.value;
      final subTotal = session.rxSubTotal.value;
      final discount = session.rxDiscountAmount.value;
      final tax = session.rxTaxAmount.value;
      final paymentMode = session.rxPaymentMode.value;
      final changeReturned = session.rxChangeReturned.value;
      final tabs = controller.rxBillTabs.toList();
      final activeTabIndex = controller.rxActiveTabIndex.value;
      final totalQty = cartItems.fold<int>(0, (sum, item) => sum + (item.qty ?? 1));

      return Container(
        color: cs.surfaceContainerLow,
        child: Column(
          children: [
            // ── 1. Top Bar: Multi-Bill Tabs & Session Actions ──
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Horizontal list of bill tabs
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...List.generate(tabs.length, (index) {
                            final tab = tabs[index];
                            final isSelected = index == activeTabIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => controller.switchTab(index),
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF005963)
                                          : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF005963)
                                            : cs.outlineVariant.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.receipt_rounded,
                                          size: 13,
                                          color: isSelected ? Colors.white : cs.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          tab.id,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? Colors.white : cs.onSurface,
                                          ),
                                        ),
                                        if (tabs.length > 1) ...[
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () => controller.closeTab(index),
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 13,
                                              color: isSelected ? Colors.white.withValues(alpha: 0.8) : cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          // Add New Bill Button
                          InkWell(
                            onTap: controller.addNewTab,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, size: 14, color: cs.primary),
                                  const SizedBox(width: 2),
                                  Text(
                                    'New',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Order Remark / Note Action
                  Tooltip(
                    message: session.rxRemark.value.isEmpty ? 'Add Bill Remark (F5)' : 'Remark: ${session.rxRemark.value}',
                    child: IconButton(
                      icon: Icon(
                        session.rxRemark.value.isEmpty ? Icons.note_alt_outlined : Icons.note_alt_rounded,
                        size: 18,
                        color: session.rxRemark.value.isEmpty ? cs.onSurfaceVariant : const Color(0xFF005963),
                      ),
                      onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f5),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(5),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),

                  // Clear Cart Action
                  if (cartItems.isNotEmpty)
                    Tooltip(
                      message: 'Clear Cart',
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_sweep_rounded,
                          size: 19,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _confirmClearCart(context, controller),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(5),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── 2. Customer Section (Clean, Compact) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: _CustomerSection(controller: controller),
            ),

            // ── 3. Selected Items Header & Cart Items List ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
              child: Row(
                children: [
                  Text(
                    'Order Items (${cartItems.length})',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const Spacer(),
                  if (cartItems.isNotEmpty)
                    Text(
                      '$totalQty total units',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),

            // Scrollable List of Cart Items
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF005963).withValues(alpha: 0.08),
                                    const Color(0xFF007580).withValues(alpha: 0.18),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 34,
                                  color: Color(0xFF005963),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Your cart is empty',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Tap any item from the catalog on the left to add it to this bill',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded, size: 14, color: cs.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Barcode scanner active',
                                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemCount: cartItems.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final qty = item.qty ?? 1;
                        final price = item.price ?? 0;
                        final itemDiscount = item.discount ?? 0;
                        final lineTotal = item.total ?? ((price * qty) - itemDiscount);
                        final sku = item.itemBarcode ?? 'ITM${item.id}';

                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top Row: Thumbnail + Item Name + SKU + Line Total
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Mini Item Avatar / Icon
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF005963).withValues(alpha: 0.09),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        size: 18,
                                        color: Color(0xFF005963),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Name, SKU, & Price
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.itemName ?? 'Item',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 5,
                                                vertical: 1.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE2F0F0),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                sku,
                                                style: const TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF005963),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '₹${price.toStringAsFixed(0)} ea',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                            if (itemDiscount > 0) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: Text(
                                                  '-₹${itemDiscount.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF16A34A),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Line Total in Bold Teal
                                  Text(
                                    '₹${lineTotal.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF005963),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Bottom Row: Segmented Stepper (- Qty +) & Action Chips
                              Row(
                                children: [
                                  // Modern Segmented Stepper Pill
                                  Container(
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: cs.outlineVariant.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // If qty == 1, show red-tinted trash icon for immediate deletion
                                        InkWell(
                                          onTap: () {
                                            if (qty <= 1) {
                                              controller.removeFromCart(index);
                                            } else {
                                              controller.updateQty(index, -1);
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(20),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                            child: Icon(
                                              qty <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                                              size: 15,
                                              color: qty <= 1 ? Colors.red.shade400 : cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            '$qty',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => controller.updateQty(index, 1),
                                          borderRadius: BorderRadius.circular(20),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                            child: Icon(
                                              Icons.add_rounded,
                                              size: 15,
                                              color: Color(0xFF005963),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),

                                  // Quick Discount Button
                                  InkWell(
                                    onTap: () {
                                      session.rxSelectedCartIndex.value = index;
                                      controller.handleShortcut(LogicalKeyboardKey.f3);
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: cs.outlineVariant.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.discount_outlined,
                                            size: 12,
                                            color: cs.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            itemDiscount > 0 ? 'Edit Disc' : 'Discount',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Remove Item Button
                                  InkWell(
                                    onTap: () => controller.removeFromCart(index),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 17,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // ── 4. Financial Breakdown & Totals Banner ──
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Subtotal Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '₹${subTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),

                  // Discount Row with Add/Edit button
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bill Discount',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: discount > 0 ? const Color(0xFF16A34A) : cs.onSurfaceVariant,
                              fontWeight: discount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => controller.handleShortcut(LogicalKeyboardKey.f4),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              child: Text(
                                discount > 0 ? 'Edit' : '+ Add',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        discount > 0 ? '- ₹${discount.toStringAsFixed(2)}' : '₹0.00',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: discount > 0 ? const Color(0xFF16A34A) : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  // Tax Row if applicable
                  if (tax > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tax (${session.rxTaxRate.value}%)',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                        Text(
                          '+ ₹${tax.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),

                  // ── Grand Total Banner (Deep Teal Gradient) ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF004D54), Color(0xFF006D77)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF004D54).withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL PAYABLE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${cartItems.length} items • $totalQty units',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₹${grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── 5. Payment Mode Selector Chips ──
                  Row(
                    children: [
                      _buildPaymentChip(
                        mode: 'Cash',
                        icon: Icons.payments_rounded,
                        isSelected: paymentMode.toLowerCase() == 'cash',
                        onTap: () {
                          session.rxPaymentMode.value = 'Cash';
                          session.rxAmountReceived.value = grandTotal;
                          session.amountController.text = grandTotal.toStringAsFixed(2);
                          controller.calculateChange();
                        },
                        cs: cs,
                      ),
                      const SizedBox(width: 4),
                      _buildPaymentChip(
                        mode: 'Card',
                        icon: Icons.credit_card_rounded,
                        isSelected: paymentMode.toLowerCase() == 'card',
                        onTap: () => session.rxPaymentMode.value = 'Card',
                        cs: cs,
                      ),
                      const SizedBox(width: 4),
                      _buildPaymentChip(
                        mode: 'UPI',
                        icon: Icons.qr_code_2_rounded,
                        isSelected: paymentMode.toLowerCase() == 'upi',
                        onTap: () => session.rxPaymentMode.value = 'UPI',
                        cs: cs,
                      ),
                      const SizedBox(width: 4),
                      _buildPaymentChip(
                        mode: 'Due',
                        icon: Icons.account_balance_wallet_rounded,
                        isSelected: paymentMode.toLowerCase() == 'due',
                        onTap: () => session.rxPaymentMode.value = 'Due',
                        cs: cs,
                      ),
                    ],
                  ),

                  // Quick Cash Tender & Change Live Preview
                  if (paymentMode.toLowerCase() == 'cash' && cartItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _quickCashChip(session, 'Exact', grandTotal, controller),
                        const SizedBox(width: 4),
                        _quickCashChip(session, '₹100', 100, controller),
                        const SizedBox(width: 4),
                        _quickCashChip(session, '₹200', 200, controller),
                        const SizedBox(width: 4),
                        _quickCashChip(session, '₹500', 500, controller),
                        const SizedBox(width: 4),
                        _quickCashChip(session, '₹2000', 2000, controller),
                      ],
                    ),
                    if (changeReturned > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Change to Return:',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                            Text(
                              '₹${changeReturned.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 10),

                  // ── 6. Complete & Print Bill Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: cartItems.isEmpty
                          ? null
                          : () async {
                              await controller.settleBill();
                            },
                      icon: const Icon(Icons.print_rounded, size: 19),
                      label: Text(
                        'COMPLETE & PRINT BILL (₹${grandTotal.toStringAsFixed(0)})',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF005963),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPaymentChip({
    required String mode,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(vertical: 7),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF005963)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF005963)
                    : cs.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? Colors.white : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  mode,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickCashChip(
    BillSession session,
    String label,
    double amount,
    ControllerHomePos controller,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () {
          session.rxAmountReceived.value = amount;
          session.amountController.text = amount.toStringAsFixed(2);
          controller.calculateChange();
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF005963).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFF005963).withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005963),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmClearCart(BuildContext context, ControllerHomePos controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text('Clear Cart?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove all items from this bill?',
          style: TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.clearCart();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
