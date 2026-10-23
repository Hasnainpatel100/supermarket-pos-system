import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../../../model/entity_item.dart';
import '../../../../model/entity_customer.dart';
import '../../../../model/entity_bill.dart';
import '../../../../util/snackbar_util.dart';
import '../account/controller_home_account.dart';
import '../account/dialog_start_day_shift.dart';
import '../setting/controller_home_settings.dart';
import '../bills/dialog_bill_print_preview.dart';
import 'activity_split_bill.dart';
import 'controller_home_pos.dart';
import 'dialog_parked_bills.dart';

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
              final key = event.logicalKey;

              // Do NOT intercept typing or deletion keys if any EditableText is focused
              final primaryFocus = FocusManager.instance.primaryFocus;
              final isEditingText = primaryFocus != null &&
                  primaryFocus.context != null &&
                  primaryFocus.context!.findAncestorWidgetOfExactType<EditableText>() != null;

              if (isEditingText && (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.backspace)) {
                return KeyEventResult.ignored;
              }

              if (key == LogicalKeyboardKey.f1 ||
                  key == LogicalKeyboardKey.f2 ||
                  key == LogicalKeyboardKey.f3 ||
                  key == LogicalKeyboardKey.f4 ||
                  key == LogicalKeyboardKey.f5 ||
                  key == LogicalKeyboardKey.f6 ||
                  key == LogicalKeyboardKey.f7 ||
                  key == LogicalKeyboardKey.f8 ||
                  key == LogicalKeyboardKey.f9 ||
                  key == LogicalKeyboardKey.f10 ||
                  key == LogicalKeyboardKey.f11 ||
                  key == LogicalKeyboardKey.delete ||
                  (key == LogicalKeyboardKey.keyP &&
                      HardwareKeyboard.instance.isControlPressed) ||
                  (key == LogicalKeyboardKey.keyT &&
                      HardwareKeyboard.instance.isControlPressed)) {
                controller.handleShortcut(key);
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
            padding: const EdgeInsets.only(right: 6),
            child: Tooltip(
              message: 'Hold / Suspend Current Order (F5)',
              child: OutlinedButton.icon(
                onPressed: controller.parkCurrentBill,
                icon: const Icon(Icons.pause_rounded, size: 16),
                label: const Text('Hold (F5)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
          Obx(() {
            final count = controller.rxParkedBills.length;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Tooltip(
                message: 'View & Recall Parked Orders (F6)',
                child: FilledButton.tonalIcon(
                  onPressed: () => DialogParkedBills.show(context, controller),
                  icon: Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    backgroundColor: Colors.amber.shade900,
                    child: const Icon(Icons.inventory_2_outlined, size: 16),
                  ),
                  label: Text('Parked ($count)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: count > 0 ? Colors.amber.withValues(alpha: 0.2) : cs.surfaceContainerHighest,
                    foregroundColor: count > 0 ? Colors.amber.shade900 : cs.onSurface,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            );
          }),
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

class _SearchBar extends StatefulWidget {
  final ControllerHomePos controller;
  const _SearchBar({required this.controller});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();
  final ScrollController _listScrollController = ScrollController();

  List<PosSearchOption> _options = [];
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.searchController.addListener(_onSearchChanged);
    widget.controller.searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.searchController.removeListener(_onSearchChanged);
    widget.controller.searchFocusNode.removeListener(_onFocusChanged);
    _listScrollController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!widget.controller.searchFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted && !widget.controller.searchFocusNode.hasFocus) {
          _overlayController.hide();
        }
      });
    } else if (widget.controller.searchController.text.trim().isNotEmpty && _options.isNotEmpty) {
      _overlayController.show();
    }
  }

  void _onSearchChanged() {
    final text = widget.controller.searchController.text.trim();
    if (text.isEmpty) {
      if (_overlayController.isShowing) {
        _overlayController.hide();
      }
      setState(() {
        _options = [];
        _highlightedIndex = 0;
      });
      return;
    }

    final results = widget.controller.searchOptions(text);
    setState(() {
      _options = results;
      _highlightedIndex = _highlightedIndex.clamp(0, results.isEmpty ? 0 : results.length - 1);
    });

    if (results.isNotEmpty && widget.controller.searchFocusNode.hasFocus) {
      if (!_overlayController.isShowing) {
        _overlayController.show();
      }
    } else {
      if (_overlayController.isShowing) {
        _overlayController.hide();
      }
    }
  }

  void _selectOption(PosSearchOption option) {
    _overlayController.hide();
    setState(() {
      _options = [];
      _highlightedIndex = 0;
    });
    if (option.hasBatch) {
      widget.controller.addBatchToCart(option.item, option.batch!);
    } else {
      widget.controller.addToCart(option.item);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.searchController.clear();
      widget.controller.rxSearchQuery.value = '';
      widget.controller.searchFocusNode.requestFocus();
    });
  }

  void _navigateOptions(int delta) {
    if (_options.isEmpty) return;
    setState(() {
      _highlightedIndex = (_highlightedIndex + delta).clamp(0, _options.length - 1);
    });
    _scrollToHighlighted();
  }

  void _scrollToHighlighted() {
    if (!_listScrollController.hasClients) return;
    const itemHeight = 56.0;
    final targetOffset = _highlightedIndex * itemHeight;
    if (targetOffset < _listScrollController.offset) {
      _listScrollController.jumpTo(targetOffset);
    } else if (targetOffset + itemHeight >
        _listScrollController.offset + _listScrollController.position.viewportDimension) {
      _listScrollController.jumpTo(
        targetOffset + itemHeight - _listScrollController.position.viewportDimension,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: (context) {
            return CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  shadowColor: Colors.black.withValues(alpha: 0.25),
                  child: Container(
                    width: 620,
                    constraints: const BoxConstraints(maxHeight: 330),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Hint header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_options.length} item${_options.length == 1 ? '' : 's'} found',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: cs.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                                    ),
                                    child: const Text('↑', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: cs.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                                    ),
                                    child: const Text('↓', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: cs.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                                    ),
                                    child: const Text('PgUp', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: cs.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                                    ),
                                    child: const Text('PgDn', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'to navigate • [Enter] to select',
                                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Options List
                        Flexible(
                          child: ListView.separated(
                            controller: _listScrollController,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shrinkWrap: true,
                            itemCount: _options.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: cs.outlineVariant.withValues(alpha: 0.18),
                            ),
                            itemBuilder: (context, index) {
                              final option = _options[index];
                              final isHighlighted = index == _highlightedIndex;

                              return InkWell(
                                onTap: () => _selectOption(option),
                                onHover: (hovered) {
                                  if (hovered && _highlightedIndex != index) {
                                    setState(() {
                                      _highlightedIndex = index;
                                    });
                                  }
                                },
                                child: Container(
                                  color: isHighlighted
                                      ? cs.primaryContainer.withValues(alpha: 0.5)
                                      : Colors.transparent,
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: option.hasBatch
                                          ? (isHighlighted ? Colors.amber.shade800 : Colors.amber.shade100)
                                          : (isHighlighted ? cs.primary : cs.primaryContainer),
                                      child: option.hasBatch
                                          ? Icon(
                                              Icons.qr_code_2_rounded,
                                              size: 16,
                                              color: isHighlighted ? Colors.white : Colors.amber.shade900,
                                            )
                                          : Text(
                                              (option.displayName)[0].toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isHighlighted ? cs.onPrimary : cs.onPrimaryContainer,
                                              ),
                                            ),
                                    ),
                                    title: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            option.displayName,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        if (option.hasBatch) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.5)),
                                            ),
                                            child: Text(
                                              'Batch: ${option.batchNo}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(
                                      option.hasBatch
                                          ? "Stock: ${option.availableQty}${option.expiryDate != null && option.expiryDate!.isNotEmpty ? ' • Exp: ${option.expiryDate}' : ''}${option.mrp > 0 ? ' • MRP: ₹${option.mrp.toStringAsFixed(2)}' : ''} • Barcode: ${option.item.barcode ?? '-'}"
                                          : "Code: ${option.item.barcode ?? option.item.sku ?? '-'} • Stock: ${option.availableQty}",
                                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "₹${option.price.toStringAsFixed(2)}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isHighlighted ? cs.primary : cs.onSurface,
                                          ),
                                        ),
                                        if (isHighlighted) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: cs.primary,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Enter ↵',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: cs.onPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
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
            );
          },
          child: Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                final key = event.logicalKey;
                final isShowing = _overlayController.isShowing && _options.isNotEmpty;

                if (key == LogicalKeyboardKey.arrowDown && isShowing) {
                  _navigateOptions(1);
                  return KeyEventResult.handled;
                } else if (key == LogicalKeyboardKey.arrowUp && isShowing) {
                  _navigateOptions(-1);
                  return KeyEventResult.handled;
                } else if (key == LogicalKeyboardKey.pageDown && isShowing) {
                  _navigateOptions(5);
                  return KeyEventResult.handled;
                } else if (key == LogicalKeyboardKey.pageUp && isShowing) {
                  _navigateOptions(-5);
                  return KeyEventResult.handled;
                } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
                  if (isShowing && _highlightedIndex >= 0 && _highlightedIndex < _options.length) {
                    _selectOption(_options[_highlightedIndex]);
                    return KeyEventResult.handled;
                  } else if (widget.controller.searchController.text.trim().isNotEmpty) {
                    _overlayController.hide();
                    widget.controller.handleBarcodeScan(widget.controller.searchController.text.trim());
                    return KeyEventResult.handled;
                  }
                } else if (key == LogicalKeyboardKey.escape && isShowing) {
                  _overlayController.hide();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: widget.controller.searchController,
              focusNode: widget.controller.searchFocusNode,
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
              onSubmitted: (val) {
                if (_overlayController.isShowing &&
                    _options.isNotEmpty &&
                    _highlightedIndex >= 0 &&
                    _highlightedIndex < _options.length) {
                  _selectOption(_options[_highlightedIndex]);
                } else if (val.trim().isNotEmpty) {
                  _overlayController.hide();
                  widget.controller.handleBarcodeScan(val.trim());
                }
              },
              onChanged: (val) {
                widget.controller.rxSearchQuery.value = val;
              },
            ),
          ),
        ),
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
        spacing: 6,
        runSpacing: 6,
        children: [
          _ActionChip(icon: Icons.pin_rounded, label: 'qty_f2'.tr, onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f2)),
          _ActionChip(icon: Icons.discount_outlined, label: 'item_disc_f3'.tr, onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f3)),
          _ActionChip(icon: Icons.person_search_rounded, label: 'Customer (F4)', onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f4)),
          _ActionChip(icon: Icons.pause_circle_outline_rounded, label: 'Hold (F5)', onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f5)),
          _ActionChip(icon: Icons.inventory_2_outlined, label: 'Parked (F6)', onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f6)),
          _ActionChip(icon: Icons.percent_rounded, label: 'Discount (F7)', onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f7)),
          _ActionChip(icon: Icons.flash_on_rounded, label: 'Quick Cash (F8)', onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f8)),
          _ActionChip(icon: Icons.call_split_rounded, label: 'Split (F9)', onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f9)),
          _ActionChip(icon: Icons.note_alt_outlined, label: 'Remarks (F11)', onPressed: () => controller.handleShortcut(LogicalKeyboardKey.f11)),
          _ActionChip(icon: Icons.delete_outline_rounded, label: 'Remove (Del)', onPressed: () => controller.handleShortcut(LogicalKeyboardKey.delete), isDestructive: true),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
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
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DateBadge(),
                  const SizedBox(height: 6),
                  _CustomerSection(controller: controller),
                ],
              ),
            ),

            // ── Summary ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: RepaintBoundary(
                child: _SummaryCard(controller: controller),
              ),
            ),

            // ── Payment ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
                child: _PaymentSection(controller: controller),
              ),
            ),

            // ── Settle Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            DateFormat('EEEE, dd MMM yyyy').format(now),
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: cs.onSurface),
          ),
          const Spacer(),
          Text(
            DateFormat('hh:mm a').format(now),
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: cs.primary,
                child: Text(
                  (selected.name ?? '?')[0].toUpperCase(),
                  style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selected.name ?? 'unknown'.tr,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: cs.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [selected.phone, selected.city].where((s) => s != null && s.isNotEmpty).join(' • '),
                      style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 16, color: cs.onSurfaceVariant),
                onPressed: () => session.rxSelectedCustomer.value = null,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        );
      }

      TextEditingController? searchFieldCtrl;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
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
                          borderRadius: BorderRadius.circular(10),
                          shadowColor: cs.shadow.withValues(alpha: 0.15),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                            ),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder: (_, _) => Divider(height: 1, indent: 12, endIndent: 12, color: cs.outlineVariant.withValues(alpha: 0.2)),
                              itemBuilder: (context, index) {
                                final c = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                  leading: CircleAvatar(
                                    radius: 13,
                                    backgroundColor: cs.secondaryContainer,
                                    child: Text(
                                      (c.name ?? '?')[0].toUpperCase(),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSecondaryContainer),
                                    ),
                                  ),
                                  title: Text(c.name ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5)),
                                  subtitle: Text(c.phone ?? '-', style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant)),
                                  onTap: () => onSelected(c),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                      searchFieldCtrl = textController;
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'search_customer_hint'.tr,
                          hintStyle: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                          prefixIcon: Icon(Icons.person_search_rounded, size: 16, color: cs.primary),
                          prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          suffixIcon: textController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 14),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    textController.clear();
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: cs.primary, width: 1.5),
                          ),
                          filled: true,
                          fillColor: cs.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 38,
                width: 38,
                child: IconButton.filledTonal(
                  onPressed: () {
                    final typedName = searchFieldCtrl?.text.trim();
                    controller.openCustomerForm(
                      initialName: typedName?.isNotEmpty == true ? typedName : null,
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  tooltip: 'add_new_customer'.tr.isNotEmpty ? 'add_new_customer'.tr : 'Add New Customer',
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Quick Entry Fields with Quick Save to Customer Master
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    style: const TextStyle(fontSize: 11.5),
                    decoration: InputDecoration(
                      hintText: 'customer_name'.tr,
                      hintStyle: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (val) => session.rxQuickCustomerName.value = val,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    style: const TextStyle(fontSize: 11.5),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'phone_number'.tr,
                      hintStyle: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (val) => session.rxQuickCustomerPhone.value = val,
                  ),
                ),
              ),
              Obx(() {
                final hasName = session.rxQuickCustomerName.value.trim().isNotEmpty;
                if (!hasName) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: SizedBox(
                    height: 34,
                    width: 34,
                    child: IconButton.filled(
                      onPressed: controller.saveQuickCustomerToMaster,
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                      tooltip: 'Save to Customer Master & Map to Cart',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                );
              }),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primaryContainer.withValues(alpha: 0.35), cs.primaryContainer.withValues(alpha: 0.12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Items/Qty summary on left, Auto Round Off toggle chip on right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        "$totalItems ${'items_label'.tr} ($totalQty ${'qty_label'.tr})",
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // Auto Round Toggle Pill
                InkWell(
                  onTap: () => controller.toggleAutoRoundOff(),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: session.rxAutoRoundOff.value
                          ? cs.primary.withValues(alpha: 0.12)
                          : cs.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: session.rxAutoRoundOff.value
                            ? cs.primary.withValues(alpha: 0.3)
                            : cs.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          session.rxAutoRoundOff.value ? Icons.auto_fix_high_rounded : Icons.auto_fix_off_rounded,
                          size: 11,
                          color: session.rxAutoRoundOff.value ? cs.primary : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Auto Round',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: session.rxAutoRoundOff.value ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                        if (session.rxAutoRoundOff.value && session.rxRoundOffAmount.value.abs() > 0.001) ...[
                          const SizedBox(width: 3),
                          Text(
                            "${session.rxRoundOffAmount.value >= 0 ? '+' : ''}₹${session.rxRoundOffAmount.value.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Subtotal / Discounts / Round off summary row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'subtotal'.tr}: $currency${session.rxSubTotal.value.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
                ),
                if (session.rxDiscountAmount.value > 0)
                  Text(
                    "-Disc: $currency${session.rxDiscountAmount.value.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                  )
                else if (session.rxRoundOffAmount.value.abs() > 0.001)
                  Text(
                    "Round: ${session.rxRoundOffAmount.value >= 0 ? '+' : ''}$currency${session.rxRoundOffAmount.value.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: session.rxRoundOffAmount.value > 0 ? Colors.teal.shade700 : Colors.indigo.shade600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),

            // Grand Total Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'grand_total'.tr.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    "$currency${session.rxGrandTotal.value.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                      letterSpacing: -0.5,
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
}

// ─── UPI Helper Dialog & Current Bill Preview ──────────────────────────────

void _showCustomUpiDialog(BuildContext context, BillSession session) {
  final textController = TextEditingController(text: session.rxCustomUpiId.value);
  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.edit_note_rounded, color: Colors.purple),
          SizedBox(width: 8),
          Text('Custom / Alternate UPI ID', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter an alternate UPI ID (VPA) for this transaction. The dynamic QR code will update immediately.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: textController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Alternate UPI ID / VPA',
              hintText: 'e.g. patelhusnain@okhdfcbank',
              prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final val = textController.text.trim();
            if (val.isNotEmpty) {
              session.rxCustomUpiId.value = val;
              session.rxSelectedUpiType.value = 'custom';
            }
            Get.back();
          },
          child: const Text('Use this UPI ID'),
        ),
      ],
    ),
  );
}

void _showCustomerUpiQrDialog(
  BuildContext context,
  String upiUrl,
  double amount,
  String upiId,
  String storeName,
) {
  final cs = Theme.of(context).colorScheme;
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, color: Colors.purple, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Scan & Pay via UPI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(storeName, style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                ],
              ),
              child: BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: upiUrl,
                width: 210,
                height: 210,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text('AMOUNT TO PAY', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.purple.shade700, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.purple.shade900)),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: upiId));
                      SnackbarUtil.showSuccess('UPI ID copied to clipboard');
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('UPI VPA: $upiId', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.purple.shade800)),
                          const SizedBox(width: 4),
                          Icon(Icons.copy_rounded, size: 12, color: Colors.purple.shade800),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Accepts Google Pay, PhonePe, Paytm, BHIM & any UPI App',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 17),
                label: const Text('Close QR'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _previewCurrentBill(ControllerHomePos controller, ControllerHomeSettings settings) {
  final session = controller.activeSession;
  if (session.rxCartItems.isEmpty) {
    SnackbarUtil.showError('Cart is empty. Add items to preview receipt.');
    return;
  }
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  final todayDate = DateFormat('d/MM/yyyy').format(DateTime.now());
  final tempBill = EntityBill(
    billNo: "PREVIEW-${session.id.replaceAll(' ', '')}",
    customerName: session.rxSelectedCustomer.value?.name ??
        (session.rxQuickCustomerName.value.isNotEmpty ? session.rxQuickCustomerName.value : "Walk-in"),
    customerPhone: session.rxSelectedCustomer.value?.phone ?? session.rxQuickCustomerPhone.value,
    totalAmount: session.rxSubTotal.value,
    discount: session.rxDiscountAmount.value,
    tax: session.rxTaxAmount.value,
    roundOff: session.rxRoundOffAmount.value,
    grandTotal: session.rxGrandTotal.value,
    status: session.rxDueAmount.value > 0.01 ? "DUE" : "PAID",
    paymentMode: session.rxPaymentMode.value,
    amountReceived: session.rxAmountReceived.value,
    changeReturned: session.rxChangeReturned.value,
    utrNumber: session.rxUtrNumber.value,
    billDate: todayDate,
    createdAtUtcMs: now,
  );
  for (var ci in session.rxCartItems) {
    tempBill.items.add(ci);
  }
  Get.dialog(
    DialogBillPrintPreview(
      bill: tempBill,
      initialPaperSize: settings.rxThermalPaperSize.value.isNotEmpty ? settings.rxThermalPaperSize.value : '80mm',
    ),
    barrierDismissible: true,
  );
}

// ─── Payment Section ─────────────────────────────────────────────────────────

class _PaymentSection extends StatelessWidget {
  final ControllerHomePos controller;
  const _PaymentSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = Get.isRegistered<ControllerHomeSettings>()
        ? Get.find<ControllerHomeSettings>()
        : Get.put(ControllerHomeSettings());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Payment Mode
        Text(
          'payment_mode'.tr.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10.5, letterSpacing: 0.6, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 5),
        Obx(() {
          final session = controller.activeSession;
          final mode = session.rxPaymentMode.value;

          return Container(
            height: 36,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                _buildModeChip('Cash', Icons.payments_outlined, mode == 'Cash', () {
                  session.rxPaymentMode.value = 'Cash';
                  session.rxAmountReceived.value = session.rxGrandTotal.value;
                  session.amountController.text = session.rxGrandTotal.value.toStringAsFixed(2);
                  controller.calculateChange();
                }, cs),
                const SizedBox(width: 3),
                _buildModeChip('UPI', Icons.qr_code_2_rounded, mode == 'UPI', () {
                  session.rxPaymentMode.value = 'UPI';
                  session.rxAmountReceived.value = session.rxGrandTotal.value;
                  controller.calculateChange();
                }, cs),
                const SizedBox(width: 3),
                _buildModeChip('Card', Icons.credit_card_rounded, mode == 'Card', () {
                  session.rxPaymentMode.value = 'Card';
                  session.rxAmountReceived.value = session.rxGrandTotal.value;
                  controller.calculateChange();
                }, cs),
                const SizedBox(width: 3),
                _buildModeChip('Split', Icons.call_split_rounded, mode == 'Split', () {
                  if (session.rxCartItems.isEmpty) {
                    Get.snackbar('cart_empty_title'.tr, 'add_items_before_split'.tr,
                        snackPosition: SnackPosition.TOP);
                    return;
                  }
                  Get.dialog(
                    const ActivitySplitBill(),
                    barrierDismissible: false,
                  );
                }, cs),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),

        // Dynamic Payment Content based on Mode
        Expanded(
          child: SingleChildScrollView(
            child: Obx(() {
              final session = controller.activeSession;
              final mode = session.rxPaymentMode.value;
              final grandTotal = session.rxGrandTotal.value;

              if (mode == 'Split') {
                return const SizedBox.shrink();
              }

              if (mode == 'UPI') {
                final storeUpi = session.getEffectiveUpi(settings);
                final storeName = settings.rxStoreName.value.trim().isNotEmpty
                    ? settings.rxStoreName.value.trim()
                    : 'Super Market';
                final upiUrl =
                    'upi://pay?pa=$storeUpi&pn=${Uri.encodeComponent(storeName)}&am=${grandTotal.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent("Bill ${session.id}")}';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.shade700.withValues(alpha: 0.08),
                        Colors.indigo.shade700.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _showCustomerUpiQrDialog(
                              context,
                              upiUrl,
                              grandTotal,
                              storeUpi,
                              storeName,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.purple.shade200),
                              ),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  BarcodeWidget(
                                    barcode: Barcode.qrCode(),
                                    data: upiUrl,
                                    width: 68,
                                    height: 68,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.purple,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.fullscreen_rounded, size: 10, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Scan & Pay (UPI)',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade900,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _showCustomerUpiQrDialog(
                                        context,
                                        upiUrl,
                                        grandTotal,
                                        storeUpi,
                                        storeName,
                                      ),
                                      child: Text(
                                        'Enlarge ↗',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: cs.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  storeUpi,
                                  style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () {
                                    session.rxUpiVerified.value = true;
                                    session.rxAmountReceived.value = grandTotal;
                                    session.amountController.text = grandTotal.toStringAsFixed(2);
                                    controller.calculateChange();
                                    SnackbarUtil.showSuccess('UPI Payment Verified');
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: session.rxUpiVerified.value
                                          ? Colors.green.shade600
                                          : Colors.purple.shade700,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          session.rxUpiVerified.value
                                              ? Icons.check_circle_rounded
                                              : Icons.check_rounded,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          session.rxUpiVerified.value ? 'Paid Verified ✓' : 'Mark as Paid',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Alternate & Custom UPI Account Switcher Chips
                      const SizedBox(height: 8),
                      Obx(() {
                        final primaryUpi = settings.rxStoreUpiId.value.trim().isNotEmpty
                            ? settings.rxStoreUpiId.value.trim()
                            : 'patelhusnain02-1@oksbi';
                        final altUpi = settings.rxStoreAlternateUpiId.value.trim();
                        final selectedType = session.rxSelectedUpiType.value;

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => session.rxSelectedUpiType.value = 'primary',
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: selectedType == 'primary' ? Colors.purple.shade700 : cs.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: selectedType == 'primary' ? Colors.purple.shade700 : Colors.purple.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_user_outlined, size: 11, color: selectedType == 'primary' ? Colors.white : Colors.purple),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Primary ($primaryUpi)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: selectedType == 'primary' ? FontWeight.bold : FontWeight.w500,
                                          color: selectedType == 'primary' ? Colors.white : Colors.purple.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (altUpi.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => session.rxSelectedUpiType.value = 'alternate',
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: selectedType == 'alternate' ? Colors.purple.shade700 : cs.surface,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: selectedType == 'alternate' ? Colors.purple.shade700 : Colors.purple.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.swap_horiz_rounded, size: 11, color: selectedType == 'alternate' ? Colors.white : Colors.purple),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Alternate ($altUpi)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: selectedType == 'alternate' ? FontWeight.bold : FontWeight.w500,
                                            color: selectedType == 'alternate' ? Colors.white : Colors.purple.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _showCustomUpiDialog(context, session),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: selectedType == 'custom' ? Colors.purple.shade700 : cs.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: selectedType == 'custom' ? Colors.purple.shade700 : Colors.purple.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_note_rounded, size: 11, color: selectedType == 'custom' ? Colors.white : Colors.purple),
                                      const SizedBox(width: 4),
                                      Text(
                                        selectedType == 'custom' && session.rxCustomUpiId.value.isNotEmpty
                                            ? 'Custom: ${session.rxCustomUpiId.value}'
                                            : '+ Alternate / Custom UPI',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: selectedType == 'custom' ? FontWeight.bold : FontWeight.w500,
                                          color: selectedType == 'custom' ? Colors.white : Colors.purple.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      TextField(
                        controller: session.utrController,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'UPI Ref / UTR No. (optional)',
                          labelStyle: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                          hintText: 'e.g. 427819034812',
                          hintStyle: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                          prefixIcon: const Icon(Icons.tag_rounded, size: 16, color: Colors.purple),
                          filled: true,
                          fillColor: cs.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.purple.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.purple, width: 1.5),
                          ),
                        ),
                        onChanged: (val) {
                          session.rxUtrNumber.value = val.trim();
                        },
                      ),
                    ],
                  ),
                );
              }

              // Default Cash Mode
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: session.amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'amount_received'.tr,
                              labelStyle: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                              prefixText: "${controller.serviceCurrency.rxCurrency.value} ",
                              prefixStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary),
                              filled: true,
                              fillColor: cs.surface,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: cs.primary, width: 1.5),
                              ),
                            ),
                            onChanged: controller.onAmountChanged,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 38,
                        child: FilledButton.tonal(
                          onPressed: () {
                            session.rxAmountReceived.value = grandTotal;
                            session.amountController.text = grandTotal.toStringAsFixed(2);
                            controller.calculateChange();
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Exact', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Quick tender chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _quickTenderBtn(session, '₹100', 100, controller, cs),
                        const SizedBox(width: 4),
                        _quickTenderBtn(session, '₹200', 200, controller, cs),
                        const SizedBox(width: 4),
                        _quickTenderBtn(session, '₹500', 500, controller, cs),
                        const SizedBox(width: 4),
                        _quickTenderBtn(session, '₹2000', 2000, controller, cs),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),

        const SizedBox(height: 6),

        // Due / Change
        Obx(() {
          final session = controller.activeSession;
          final currency = controller.serviceCurrency.rxCurrency.value;
          final isDue = session.rxDueAmount.value > 0.001;
          final isChange = session.rxChangeReturned.value > 0.001;
          final isBalanced = !isDue && !isChange && session.rxAmountReceived.value > 0;
          final amount = isDue ? session.rxDueAmount.value : session.rxChangeReturned.value;

          Color bg;
          Color border;
          Color fg;
          IconData icon;
          String title;

          if (isDue) {
            bg = Colors.orange.withValues(alpha: 0.08);
            border = Colors.orange.withValues(alpha: 0.3);
            fg = Colors.orange.shade800;
            icon = Icons.warning_amber_rounded;
            title = 'amount_due'.tr;
          } else if (isChange) {
            bg = Colors.green.withValues(alpha: 0.08);
            border = Colors.green.withValues(alpha: 0.3);
            fg = Colors.green.shade800;
            icon = Icons.check_circle_outline_rounded;
            title = 'change_to_return'.tr;
          } else if (isBalanced) {
            bg = Colors.teal.withValues(alpha: 0.08);
            border = Colors.teal.withValues(alpha: 0.3);
            fg = Colors.teal.shade800;
            icon = Icons.done_all_rounded;
            title = 'Paid in Full';
          } else {
            bg = cs.surfaceContainerHighest.withValues(alpha: 0.3);
            border = cs.outlineVariant.withValues(alpha: 0.25);
            fg = cs.onSurfaceVariant;
            icon = Icons.info_outline_rounded;
            title = 'amount_due'.tr;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                const Spacer(),
                Text(
                  "$currency${(isDue || isChange ? amount : (isBalanced ? session.rxAmountReceived.value : session.rxGrandTotal.value)).toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildModeChip(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    ColorScheme cs,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickTenderBtn(
    BillSession session,
    String label,
    double value,
    ControllerHomePos controller,
    ColorScheme cs,
  ) {
    return InkWell(
      onTap: () {
        session.rxAmountReceived.value = value;
        session.amountController.text = value.toStringAsFixed(2);
        controller.calculateChange();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: cs.primary),
        ),
      ),
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
    final settings = Get.isRegistered<ControllerHomeSettings>()
        ? Get.find<ControllerHomeSettings>()
        : Get.put(ControllerHomeSettings());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary Action: Save & Print Bill (Ctrl+P)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade800],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: controller.settleBill,
            icon: const Icon(Icons.print_rounded, size: 18, color: Colors.white),
            label: Text(
              'save_print_bill'.tr,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Quick Utilities Bar: Quick Cash (F8), Hold (F5), Preview Receipt, Paper Format Switcher
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 34,
                child: FilledButton.tonalIcon(
                  onPressed: controller.quickCashSettle,
                  icon: const Icon(Icons.flash_on_rounded, size: 14),
                  label: const Text('Quick Cash (F8)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                    foregroundColor: const Color(0xFF047857),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 34,
              child: OutlinedButton.icon(
                onPressed: controller.parkCurrentBill,
                icon: const Icon(Icons.pause_circle_outline_rounded, size: 14),
                label: const Text('Hold (F5)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Preview Receipt
            SizedBox(
              height: 34,
              child: Tooltip(
                message: 'Preview Receipt',
                child: OutlinedButton(
                  onPressed: () => _previewCurrentBill(controller, settings),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
                  ),
                  child: Icon(Icons.visibility_outlined, size: 16, color: cs.primary),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Paper Size Quick Indicator / Switch
            Obx(() {
              final paperSize = settings.rxThermalPaperSize.value.isNotEmpty ? settings.rxThermalPaperSize.value : '80mm';
              final is80 = paperSize.toLowerCase() == '80mm';
              return Tooltip(
                message: 'Active Print Paper Format (Click to toggle 80mm / 56mm)',
                child: InkWell(
                  onTap: () {
                    settings.rxThermalPaperSize.value = is80 ? '58mm' : '80mm';
                    settings.savePrinterSettings();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      is80 ? '80mm' : '56mm',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
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
                    Text('person_n'.trParams({'n': '${index + 1}'}), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: cs.onSurfaceVariant)),
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
                            initialValue: session.rxSplitModes[index].value,
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
                    isValid ? 'split_amounts_match'.tr : 'difference_amount'.trParams({'currency': currency, 'amount': diff.toStringAsFixed(2)}),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isValid ? Colors.green.shade700 : Colors.red.shade700),
                  ),
                  Text(
                    'total_split'.trParams({'currency': currency, 'amount': totalSplit.toStringAsFixed(2)}),
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
    final settings = Get.isRegistered<ControllerHomeSettings>()
        ? Get.find<ControllerHomeSettings>()
        : Get.put(ControllerHomeSettings());

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

                  // Round Off Row if applicable
                  if (session.rxRoundOffAmount.value.abs() > 0.001) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Round Off',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                        Text(
                          "${session.rxRoundOffAmount.value >= 0 ? '+' : ''}₹${session.rxRoundOffAmount.value.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: session.rxRoundOffAmount.value > 0 ? const Color(0xFF16A34A) : Colors.teal.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Auto Round Off Toggle Row
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            session.rxAutoRoundOff.value ? Icons.auto_fix_high_rounded : Icons.auto_fix_off_rounded,
                            size: 14,
                            color: session.rxAutoRoundOff.value ? const Color(0xFF006D77) : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Auto Round Off',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: session.rxAutoRoundOff.value ? const Color(0xFF006D77) : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: controller.toggleAutoRoundOff,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: session.rxAutoRoundOff.value
                                ? const Color(0xFF006D77).withValues(alpha: 0.12)
                                : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: session.rxAutoRoundOff.value
                                  ? const Color(0xFF006D77)
                                  : cs.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            session.rxAutoRoundOff.value
                                ? 'ON (±₹${session.rxRoundOffAmount.value.abs().toStringAsFixed(2)})'
                                : 'OFF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: session.rxAutoRoundOff.value ? const Color(0xFF006D77) : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                        onTap: () {
                          session.rxPaymentMode.value = 'Card';
                          session.rxAmountReceived.value = grandTotal;
                          controller.calculateChange();
                        },
                        cs: cs,
                      ),
                      const SizedBox(width: 4),
                      _buildPaymentChip(
                        mode: 'UPI',
                        icon: Icons.qr_code_2_rounded,
                        isSelected: paymentMode.toLowerCase() == 'upi',
                        onTap: () {
                          session.rxPaymentMode.value = 'UPI';
                          session.rxAmountReceived.value = grandTotal;
                          controller.calculateChange();
                        },
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

                  // Modern Dynamic UPI Card in Catalog View
                  if (paymentMode.toLowerCase() == 'upi' && cartItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Builder(builder: (context) {
                      final storeUpi = session.getEffectiveUpi(settings);
                      final storeName = settings.rxStoreName.value.trim().isNotEmpty
                          ? settings.rxStoreName.value.trim()
                          : 'Super Market';
                      final upiUrl =
                          'upi://pay?pa=$storeUpi&pn=${Uri.encodeComponent(storeName)}&am=${grandTotal.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent("Bill ${session.id}")}';

                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade700.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => _showCustomerUpiQrDialog(
                                    context,
                                    upiUrl,
                                    grandTotal,
                                    storeUpi,
                                    storeName,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.purple.shade200),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        BarcodeWidget(
                                          barcode: Barcode.qrCode(),
                                          data: upiUrl,
                                          width: 54,
                                          height: 54,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(1.5),
                                          decoration: const BoxDecoration(
                                            color: Colors.purple,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.fullscreen_rounded, size: 8, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Scan & Pay (UPI)',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple.shade900,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => _showCustomerUpiQrDialog(
                                              context,
                                              upiUrl,
                                              grandTotal,
                                              storeUpi,
                                              storeName,
                                            ),
                                            child: Text(
                                              'Enlarge ↗',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: cs.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        storeUpi,
                                        style: TextStyle(fontSize: 9.5, color: cs.onSurfaceVariant),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: upiUrl));
                                              SnackbarUtil.showSuccess('UPI Link Copied');
                                            },
                                            borderRadius: BorderRadius.circular(4),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: cs.surface,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.copy_rounded, size: 9, color: cs.onSurfaceVariant),
                                                  const SizedBox(width: 2),
                                                  Text('Copy', style: TextStyle(fontSize: 8.5, color: cs.onSurfaceVariant)),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () {
                                                session.rxUpiVerified.value = true;
                                                session.rxAmountReceived.value = grandTotal;
                                                session.amountController.text = grandTotal.toStringAsFixed(2);
                                                controller.calculateChange();
                                                SnackbarUtil.showSuccess('UPI Payment Verified');
                                              },
                                              borderRadius: BorderRadius.circular(4),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: session.rxUpiVerified.value
                                                      ? Colors.green.shade600
                                                      : Colors.purple.shade700,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      session.rxUpiVerified.value
                                                          ? Icons.check_circle_rounded
                                                          : Icons.check_rounded,
                                                      size: 10,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      session.rxUpiVerified.value ? 'Verified ✓' : 'Mark Paid',
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Catalog View UPI Account Switcher Chips
                            const SizedBox(height: 6),
                            Obx(() {
                              final primaryUpi = settings.rxStoreUpiId.value.trim().isNotEmpty
                                  ? settings.rxStoreUpiId.value.trim()
                                  : 'patelhusnain02-1@oksbi';
                              final altUpi = settings.rxStoreAlternateUpiId.value.trim();
                              final selectedType = session.rxSelectedUpiType.value;

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () => session.rxSelectedUpiType.value = 'primary',
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: selectedType == 'primary' ? Colors.purple.shade700 : cs.surface,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: selectedType == 'primary' ? Colors.purple.shade700 : Colors.purple.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          'Primary: $primaryUpi',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: selectedType == 'primary' ? FontWeight.bold : FontWeight.w500,
                                            color: selectedType == 'primary' ? Colors.white : Colors.purple.shade900,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (altUpi.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () => session.rxSelectedUpiType.value = 'alternate',
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: selectedType == 'alternate' ? Colors.purple.shade700 : cs.surface,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: selectedType == 'alternate' ? Colors.purple.shade700 : Colors.purple.shade200,
                                            ),
                                          ),
                                          child: Text(
                                            'Alt: $altUpi',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: selectedType == 'alternate' ? FontWeight.bold : FontWeight.w500,
                                              color: selectedType == 'alternate' ? Colors.white : Colors.purple.shade900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _showCustomUpiDialog(context, session),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: selectedType == 'custom' ? Colors.purple.shade700 : cs.surface,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: selectedType == 'custom' ? Colors.purple.shade700 : Colors.purple.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          selectedType == 'custom' && session.rxCustomUpiId.value.isNotEmpty
                                              ? 'Custom: ${session.rxCustomUpiId.value}'
                                              : '+ Custom',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: selectedType == 'custom' ? FontWeight.bold : FontWeight.w500,
                                            color: selectedType == 'custom' ? Colors.white : Colors.purple.shade900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 6),
                            TextField(
                              controller: session.utrController,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: 'UPI Ref / UTR No. (optional)',
                                labelStyle: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                                hintText: 'e.g. 427819034812',
                                hintStyle: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                                prefixIcon: const Icon(Icons.tag_rounded, size: 13, color: Colors.purple),
                                filled: true,
                                fillColor: cs.surface,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: Colors.purple.withValues(alpha: 0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: Colors.purple, width: 1.2),
                                ),
                              ),
                              onChanged: (val) {
                                session.rxUtrNumber.value = val.trim();
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 10),

                  // ── 6. Complete & Print Bill & Preview Row ──
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: FilledButton.icon(
                            onPressed: cartItems.isEmpty
                                ? null
                                : () async {
                                    await controller.settleBill();
                                  },
                            icon: const Icon(Icons.print_rounded, size: 18),
                            label: Text(
                              'COMPLETE & PRINT (₹${grandTotal.toStringAsFixed(0)})',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
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
                      ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Preview Bill Receipt',
                        child: SizedBox(
                          height: 44,
                          width: 44,
                          child: OutlinedButton(
                            onPressed: cartItems.isEmpty
                                ? null
                                : () => _previewCurrentBill(controller, settings),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(
                                color: const Color(0xFF005963).withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Icon(
                              Icons.visibility_outlined,
                              size: 19,
                              color: Color(0xFF005963),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Paper Size Toggle Pill
                      Obx(() {
                        final paperSize = settings.rxThermalPaperSize.value.isNotEmpty
                            ? settings.rxThermalPaperSize.value
                            : '80mm';
                        final is80 = paperSize.toLowerCase() == '80mm';
                        return Tooltip(
                          message: 'Print Paper Size: $paperSize (Tap to toggle 80mm / 56mm)',
                          child: InkWell(
                            onTap: () {
                              settings.rxThermalPaperSize.value = is80 ? '58mm' : '80mm';
                              settings.savePrinterSettings();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 7),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: cs.outlineVariant.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                is80 ? '80mm' : '56mm',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF005963),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
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
