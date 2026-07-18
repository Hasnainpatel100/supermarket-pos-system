import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../widget/app_dialog_components.dart';
import 'controller_home_pos.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity Split Bill
// ─────────────────────────────────────────────────────────────────────────────

class ActivitySplitBill extends StatefulWidget {
  const ActivitySplitBill({super.key});

  @override
  State<ActivitySplitBill> createState() => _ActivitySplitBillState();
}

class _ActivitySplitBillState extends State<ActivitySplitBill>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _ctrl = Get.find<ControllerHomePos>();

  // ── Person-wise state ──────────────────────────────────────────────────────
  int _personCount = 2;
  final _nameCtrl   = <TextEditingController>[];
  final _amountCtrl = <TextEditingController>[];
  final _modes      = <String>[];

  // ── Item-wise state ────────────────────────────────────────────────────────
  late List<int> _itemPerson; // index = cart-item index, value = person index

  // ── Colour palette per person ──────────────────────────────────────────────
  static const _palette = [
    Color(0xFF2196F3), Color(0xFF4CAF50), Color(0xFFFF9800), Color(0xFF9C27B0),
    Color(0xFF009688), Color(0xFFF44336), Color(0xFFE91E63), Color(0xFFFFC107),
    Color(0xFF3F51B5), Color(0xFF00BCD4),
  ];

  // ── Payment modes ──────────────────────────────────────────────────────────
  static const _payModes = ['Cash', 'UPI'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
    _itemPerson =
        List.filled(_ctrl.activeSession.rxCartItems.length, 0);
    _initPersons(2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _nameCtrl)   c.dispose();
    for (final c in _amountCtrl) c.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _initPersons(int n) {
    for (final c in _nameCtrl)   c.dispose();
    for (final c in _amountCtrl) c.dispose();
    _nameCtrl.clear();
    _amountCtrl.clear();
    _modes.clear();
    _personCount = n;

    final total = _ctrl.activeSession.rxGrandTotal.value;
    final share = n > 0 ? total / n : 0.0;
    for (int i = 0; i < n; i++) {
      _nameCtrl.add(TextEditingController(text: 'Person ${i + 1}'));
      _amountCtrl.add(TextEditingController(text: share.toStringAsFixed(2)));
      _modes.add('Cash');
    }
    // Resize item assignment if person count decreased
    if (_itemPerson.isNotEmpty) {
      _itemPerson = _itemPerson.map((p) => p >= n ? 0 : p).toList();
    }
    setState(() {});
  }

  double get _pwTotal =>
      _amountCtrl.fold(0.0, (s, c) => s + (double.tryParse(c.text) ?? 0));

  double _iwPersonTotal(int p) {
    final items = _ctrl.activeSession.rxCartItems;
    double t = 0;
    for (int i = 0; i < items.length; i++) {
      if (i < _itemPerson.length && _itemPerson[i] == p) {
        t += items[i].total ?? 0;
      }
    }
    return t;
  }

  // ── Generate Bill ─────────────────────────────────────────────────────────

  void _generate() {
    final session = _ctrl.activeSession;
    final grand   = session.rxGrandTotal.value;
    final byPerson = _tabController.index == 0;

    if (byPerson) {
      final diff = (grand - _pwTotal).abs();
      if (diff > 0.01) {
        Get.snackbar(
          'Incomplete Split',
          'Allocated ${_ctrl.serviceCurrency.rxCurrency.value}'
          '${_pwTotal.toStringAsFixed(2)} ≠ '
          'Grand Total ${_ctrl.serviceCurrency.rxCurrency.value}'
          '${grand.toStringAsFixed(2)}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }
    }

    // Populate BillSession split fields
    session.rxPaymentMode.value = 'Split';
    session.rxSplitCount.value  = _personCount;
    for (final c in session.splitControllers) c.dispose();
    session.splitControllers.clear();
    session.rxSplitAmounts.clear();
    session.rxSplitModes.clear();

    for (int i = 0; i < _personCount; i++) {
      final amt = byPerson
          ? (double.tryParse(_amountCtrl[i].text) ?? 0)
          : _iwPersonTotal(i);
      session.rxSplitAmounts.add(amt.obs);
      session.rxSplitModes.add((byPerson ? _modes[i] : 'Cash').obs);
      session.splitControllers
          .add(TextEditingController(text: amt.toStringAsFixed(2)));
    }

    // Mark fully paid so no due amount triggers
    session.rxAmountReceived.value = grand;
    session.amountController.text  = grand.toStringAsFixed(2);
    _ctrl.calculateChange();

    Get.back();         // close split screen
    _ctrl.settleBill(); // settle & print
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final currency = _ctrl.serviceCurrency.rxCurrency.value;

    return AppDialog(
      maxWidth: 900,
      maxHeight: 750,
      header: DialogHeader(
        title: 'Split Bill',
        icon: Icons.call_split_rounded,
        iconColor: cs.primary,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TabBar header
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.people_alt_rounded), text: 'Person Wise'),
              Tab(icon: Icon(Icons.checklist_rounded),  text: 'Item Wise'),
            ],
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            indicatorColor: cs.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          // TabBar content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0 – Person Wise
                _PersonWiseTab(
                  personCount:  _personCount,
                  names:        _nameCtrl,
                  amounts:      _amountCtrl,
                  modes:        _modes,
                  currency:     currency,
                  grandTotal:   _ctrl.activeSession.rxGrandTotal.value,
                  cs:           cs,
                  palette:      _palette,
                  payModes:     _payModes,
                  onCount:  (n) => _initPersons(n),
                  onMode:   (i, m) => setState(() => _modes[i] = m),
                  onAmount: () => setState(() {}),
                ),
                // Tab 1 – Item Wise
                _ItemWiseTab(
                  controller:  _ctrl,
                  personCount: _personCount,
                  names:       _nameCtrl,
                  itemPerson:  _itemPerson,
                  currency:    currency,
                  cs:          cs,
                  palette:     _palette,
                  onAssign: (ii, pi) => setState(() => _itemPerson[ii] = pi),
                  personTotal: _iwPersonTotal,
                ),
              ],
            ),
          ),
        ],
      ),
      footer: _BottomBar(
        isPersonWise:  _tabController.index == 0,
        pwTotal:       _pwTotal,
        grandTotal:    _ctrl.activeSession.rxGrandTotal.value,
        currency:      currency,
        cs:            cs,
        onGenerate:    _generate,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isPersonWise,
    required this.pwTotal,
    required this.grandTotal,
    required this.currency,
    required this.cs,
    required this.onGenerate,
  });

  final bool        isPersonWise;
  final double      pwTotal;
  final double      grandTotal;
  final String      currency;
  final ColorScheme cs;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final diff = (grandTotal - pwTotal).abs();
    final ok   = diff < 0.01 || !isPersonWise;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
        boxShadow: [
          BoxShadow(
              color: cs.shadow.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Allocation warning
          if (isPersonWise && !ok) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Remaining: $currency${diff.toStringAsFixed(2)}  '
                      '(Allocated: $currency${pwTotal.toStringAsFixed(2)} '
                      '/ $currency${grandTotal.toStringAsFixed(2)})',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Generate button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.receipt_long_rounded, size: 20),
              label: const Text('Generate Bill',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                backgroundColor: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PERSON-WISE TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _PersonWiseTab extends StatelessWidget {
  const _PersonWiseTab({
    required this.personCount,
    required this.names,
    required this.amounts,
    required this.modes,
    required this.currency,
    required this.grandTotal,
    required this.cs,
    required this.palette,
    required this.payModes,
    required this.onCount,
    required this.onMode,
    required this.onAmount,
  });

  final int                           personCount;
  final List<TextEditingController>   names;
  final List<TextEditingController>   amounts;
  final List<String>                  modes;
  final String                        currency;
  final double                        grandTotal;
  final ColorScheme                   cs;
  final List<Color>                   palette;
  final List<String>                  payModes;
  final void Function(int)            onCount;
  final void Function(int, String)    onMode;
  final VoidCallback                  onAmount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Person Count Selector ────────────────────────────────────────────
        _CountCard(
          personCount: personCount,
          cs:          cs,
          onChanged:   onCount,
        ),
        const SizedBox(height: 16),

        // ── Per-Person Entry Cards ───────────────────────────────────────────
        ...List.generate(personCount, (i) => _PersonCard(
          index:    i,
          nameCtrl: names[i],
          amtCtrl:  amounts[i],
          mode:     modes[i],
          color:    palette[i % palette.length],
          currency: currency,
          cs:       cs,
          payModes: payModes,
          onMode:   (m) => onMode(i, m),
          onAmount: onAmount,
        )),
      ],
    );
  }
}

// ── Count Selector Card ───────────────────────────────────────────────────────

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.personCount,
    required this.cs,
    required this.onChanged,
  });

  final int             personCount;
  final ColorScheme     cs;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: cs.shadow.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.group_rounded, color: cs.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Number of Persons',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: cs.onSurface)),
                Text('Bill will be split among $personCount person(s)',
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          // Stepper
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _StepBtn(
                  icon:    Icons.remove_rounded,
                  enabled: personCount > 2,
                  cs:      cs,
                  onTap:   () => onChanged(personCount - 1),
                ),
                SizedBox(
                  width: 44,
                  child: Center(
                    child: Text('$personCount',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: cs.primary)),
                  ),
                ),
                _StepBtn(
                  icon:    Icons.add_rounded,
                  enabled: personCount < 10,
                  cs:      cs,
                  onTap:   () => onChanged(personCount + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.cs,
    required this.onTap,
  });
  final IconData   icon;
  final bool       enabled;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Icon(icon,
            size: 18,
            color: enabled
                ? cs.onSurface
                : cs.onSurfaceVariant.withOpacity(0.3)),
      ),
    );
  }
}

// ── Per-Person Card ────────────────────────────────────────────────────────────

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.index,
    required this.nameCtrl,
    required this.amtCtrl,
    required this.mode,
    required this.color,
    required this.currency,
    required this.cs,
    required this.payModes,
    required this.onMode,
    required this.onAmount,
  });

  final int                         index;
  final TextEditingController       nameCtrl;
  final TextEditingController       amtCtrl;
  final String                      mode;
  final Color                       color;
  final String                      currency;
  final ColorScheme                 cs;
  final List<String>                payModes;
  final void Function(String)       onMode;
  final VoidCallback                onAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: cs.shadow.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          // ── Header bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: nameCtrl,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: cs.onSurface),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Enter name…',
                    ),
                  ),
                ),
                Icon(Icons.edit_rounded, size: 14, color: color.withOpacity(0.5)),
              ],
            ),
          ),
          // ── Amount + Mode ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Amount
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount to Pay',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: amtCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: color),
                        decoration: InputDecoration(
                          isDense: true,
                          prefix: Text(
                            '$currency ',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: color),
                          ),
                          enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: color.withOpacity(0.3),
                                      width: 2)),
                          focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: color, width: 2)),
                          contentPadding:
                              const EdgeInsets.only(bottom: 4),
                        ),
                        onChanged: (_) => onAmount(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Payment mode
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Mode',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: mode,
                        isDense: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: cs.outlineVariant.withOpacity(0.4)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          filled: true,
                          fillColor: cs.surfaceContainerLow,
                        ),
                        items: payModes
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m,
                                      style:
                                          const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (m) {
                          if (m != null) onMode(m);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ITEM-WISE TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _ItemWiseTab extends StatelessWidget {
  const _ItemWiseTab({
    required this.controller,
    required this.personCount,
    required this.names,
    required this.itemPerson,
    required this.currency,
    required this.cs,
    required this.palette,
    required this.onAssign,
    required this.personTotal,
  });

  final ControllerHomePos                   controller;
  final int                                 personCount;
  final List<TextEditingController>         names;
  final List<int>                           itemPerson;
  final String                              currency;
  final ColorScheme                         cs;
  final List<Color>                         palette;
  final void Function(int itemIdx, int pIdx) onAssign;
  final double Function(int pIdx)           personTotal;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.activeSession.rxCartItems;
      if (items.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 48,
                  color: cs.onSurfaceVariant.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text('No items in cart',
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontSize: 15)),
            ],
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Person Summary Row ─────────────────────────────────────────────
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: personCount,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final col   = palette[i % palette.length];
                final pName = names.length > i
                    ? names[i].text
                    : 'Person ${i + 1}';
                final pTotal = personTotal(i);
                return Container(
                  width: 130,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: col.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: col.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                                color: col, shape: BoxShape.circle),
                            child: Center(
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(pName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text('$currency${pTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: col)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Section title ──────────────────────────────────────────────────
          Text(
            'Assign Items to Person',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface),
          ),
          const SizedBox(height: 10),

          // ── Item rows ─────────────────────────────────────────────────────
          ...List.generate(items.length, (i) {
            final item     = items[i];
            final assigned = i < itemPerson.length ? itemPerson[i] : 0;
            final col      = palette[assigned % palette.length];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: col.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                      color: cs.shadow.withOpacity(0.04),
                      blurRadius: 6)
                ],
              ),
              child: Row(
                children: [
                  // Item info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.itemName ?? '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(
                          'Qty: ${item.qty}  ×  '
                          '$currency${(item.price ?? 0).toStringAsFixed(2)}'
                          '  =  '
                          '$currency${(item.total ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Person dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: col.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: col.withOpacity(0.3)),
                    ),
                    child: DropdownButton<int>(
                      value: assigned,
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      dropdownColor: cs.surface,
                      items: List.generate(personCount, (p) {
                        final pName = names.length > p
                            ? names[p].text
                            : 'Person ${p + 1}';
                        final pCol = palette[p % palette.length];
                        return DropdownMenuItem(
                          value: p,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: pCol,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(pName,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }),
                      onChanged: (p) {
                        if (p != null) onAssign(i, p);
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    });
  }
}
