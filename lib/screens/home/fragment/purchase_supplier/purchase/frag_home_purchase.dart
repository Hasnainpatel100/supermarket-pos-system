import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../../enums/enum_purchase_status.dart';
import '../../../../../model/entity_purchase.dart';
import '../../../../../util/snackbar_util.dart';
import '../../../../../widget/my_card.dart';
import '../activity_receive_goods.dart';
import 'activity_purchase_form.dart';
import 'controller_home_purchase.dart';

class FragmentHomePurchase extends StatelessWidget {
  const FragmentHomePurchase({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ControllerHomePurchase>()
        ? Get.find<ControllerHomePurchase>()
        : Get.put(ControllerHomePurchase());
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
                  colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.shopping_cart_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Purchases',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Text(
                  'Manage purchase orders',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // ── New Purchase Button ──
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade400,
                  Colors.deepPurple.shade700
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await Get.to(() => const ActivityPurchaseForm());
                  controller.loadPurchases();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: const [
                      Icon(Icons.add_shopping_cart_rounded,
                          size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text('New Purchase',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search by PO number or supplier...',
                hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.deepPurple.shade600, size: 22),
                suffixIcon: Obx(
                      () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: Colors.red.shade400, size: 20),
                    onPressed: controller.clearSearch,
                  )
                      : const SizedBox.shrink(),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 20),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: controller.updateSearch,
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // ── Status Filter Chips ──
          _buildFilterChips(controller),

          // ── Table ──
          Expanded(
            child: Obx(
                  () => controller.rxListPurchase.isEmpty
                  ? _buildEmpty()
                  : MyCard(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 16,
                      horizontalMargin: 16,
                      headingRowColor: WidgetStateProperty.all(
                        colorScheme.primary.withValues(alpha: 0.04),
                      ),
                      headingTextStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                      dividerThickness: 0.5,
                      dataRowMaxHeight: 52,
                      columns: [
                        _col(context, 'PO Number',
                            Icons.tag_rounded, Colors.deepPurple),
                        _col(context, 'Supplier',
                            Icons.local_shipping_rounded, Colors.indigo),
                        _col(context, 'Date',
                            Icons.calendar_today_rounded, Colors.blue),
                        _col(context, 'Status',
                            Icons.toggle_on_rounded, Colors.orange),
                        _col(context, 'Total',
                            Icons.currency_rupee_rounded, Colors.green),
                        _col(context, 'Actions',
                            Icons.settings_rounded, Colors.grey),
                      ],
                      rows: controller.rxListPurchase
                          .map((p) => _buildRow(
                          context, p, controller, colorScheme))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Pagination ──
          Obx(() => _buildPagination(controller)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  FILTER CHIPS
  // ─────────────────────────────────────────────

  Widget _buildFilterChips(ControllerHomePurchase controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Obx(() {
        final selected = controller.filterStatus.value;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip('All', null, selected, controller),
              const SizedBox(width: 8),
              ...PurchaseStatus.values.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(s.label, s, selected, controller),
              )),
            ],
          ),
        );
      }),
    );
  }

  Widget _chip(
      String label,
      PurchaseStatus? status,
      PurchaseStatus? selected,
      ControllerHomePurchase controller,
      ) {
    final isSelected = selected == status;
    final color = status != null
        ? Color(status.colorValue)
        : Colors.deepPurple;

    return FilterChip(
      label: Text(label,
          style: TextStyle(
              fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : color)),
      selected: isSelected,
      selectedColor: color,
      onSelected: (_) => controller.setStatusFilter(status),
      backgroundColor: color.withOpacity(0.08),
      side: BorderSide(color: color.withOpacity(0.3)),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  // ─────────────────────────────────────────────
  //  TABLE
  // ─────────────────────────────────────────────

  DataColumn _col(
      BuildContext context, String label, IconData icon, Color color) {
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color.withOpacity(0.8)),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  DataRow _buildRow(
      BuildContext context,
      EntityPurchase p,
      ControllerHomePurchase controller,
      ColorScheme colorScheme,
      ) {
    final status = PurchaseStatus.values[p.status ?? 0];
    final statusColor = Color(status.colorValue);
    final canReceive = status == PurchaseStatus.ordered ||
        status == PurchaseStatus.partial;
    final canCancel = status == PurchaseStatus.ordered ||
        status == PurchaseStatus.draft;

    final date = p.purchaseDateUtcMs != null
        ? DateFormat('dd MMM yyyy').format(
        DateTime.fromMillisecondsSinceEpoch(p.purchaseDateUtcMs!,
            isUtc: true))
        : '-';

    return DataRow(cells: [
      // PO Number
      DataCell(
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            p.purchaseNo ?? '-',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.deepPurple),
          ),
        ),
      ),

      // Supplier
      DataCell(Text(p.supplierName ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w500))),

      // Date
      DataCell(Text(date,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),

      // Status Badge
      DataCell(_statusBadge(status, statusColor)),

      // Total
      DataCell(Text(
        '₹ ${(p.totalAmount ?? 0).toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      )),

      // Actions
      DataCell(
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500),
          tooltip: 'Actions',
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showDetails(context, p, controller);
                break;
              case 'receive':
                _goReceive(p, controller);
                break;
              case 'cancel':
                _confirmCancel(context, p, controller);
                break;
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'view',
              child: Row(children: [
                Icon(Icons.visibility_outlined,
                    size: 20, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                const Text('View Details'),
              ]),
            ),
            if (canReceive)
              PopupMenuItem(
                value: 'receive',
                child: Row(children: [
                  Icon(Icons.move_to_inbox_rounded,
                      size: 20, color: Colors.green.shade600),
                  const SizedBox(width: 12),
                  const Text('Receive Goods'),
                ]),
              ),
            if (canCancel)
              PopupMenuItem(
                value: 'cancel',
                child: Row(children: [
                  Icon(Icons.cancel_outlined,
                      size: 20, color: Colors.red.shade400),
                  const SizedBox(width: 12),
                  const Text('Cancel Purchase',
                      style: TextStyle(color: Colors.red)),
                ]),
              ),
          ],
        ),
      ),
    ]);
  }

  Widget _statusBadge(PurchaseStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7,
              height: 7,
              decoration:
              BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(status.label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  PAGINATION
  // ─────────────────────────────────────────────

  Widget _buildPagination(ControllerHomePurchase controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total: ${controller.totalCount.value} purchases',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Row(children: [
            OutlinedButton.icon(
              onPressed: controller.hasPrev ? controller.prevPage : null,
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
              label: const Text('Prev'),
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Page ${controller.currentPage.value + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple)),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: controller.hasNext ? controller.nextPage : null,
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
              label: const Text('Next'),
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
          ]),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  EMPTY STATE
  // ─────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade100,
                  Colors.indigo.shade100
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Icon(Icons.shopping_cart_rounded,
                size: 64, color: Colors.deepPurple.shade400),
          ),
          const SizedBox(height: 16),
          Text('No purchases found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text('Create a new purchase order to get started',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  DIALOGS / NAVIGATION
  // ─────────────────────────────────────────────

  void _goReceive(
      EntityPurchase purchase, ControllerHomePurchase controller) async {
    await Get.to(() => const ActivityReceiveGoods(), arguments: purchase);
    controller.loadPurchases();
  }

  void _confirmCancel(
      BuildContext context,
      EntityPurchase purchase,
      ControllerHomePurchase controller,
      ) {
    Get.defaultDialog(
      title: 'Cancel Purchase?',
      titleStyle:
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      middleText:
      'Are you sure you want to cancel "${purchase.purchaseNo}"?\nThis action cannot be undone.',
      confirm: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        icon: const Icon(Icons.cancel_outlined, size: 20),
        onPressed: () {
          controller.cancelPurchase(purchase);
          Get.back();
          SnackbarUtil.showSuccess('Purchase ${purchase.purchaseNo} cancelled');
        },
        label: const Text('Cancel Purchase'),
      ),
      cancel: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () => Get.back(),
        child: const Text('Go Back'),
      ),
    );
  }

  void _showDetails(
      BuildContext context,
      EntityPurchase p,
      ControllerHomePurchase controller,
      ) {
    final status = PurchaseStatus.values[p.status ?? 0];
    final statusColor = Color(status.colorValue);
    final items = controller.getItemsForPurchase(p.id);

    Get.dialog(
      Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 640,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Icon(Icons.shopping_cart_rounded,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 10),
                Text('Purchase Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                _statusBadge(status, statusColor),
                const SizedBox(width: 12),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back()),
              ]),
              const Divider(),
              const SizedBox(height: 8),

              // PO Info
              Row(children: [
                Expanded(
                    child: _detailRow('PO Number', p.purchaseNo)),
                Expanded(
                    child: _detailRow('Supplier', p.supplierName)),
              ]),
              Row(children: [
                Expanded(
                    child: _detailRow(
                        'Purchase Date',
                        p.purchaseDateUtcMs != null
                            ? DateFormat('dd MMM yyyy').format(
                            DateTime.fromMillisecondsSinceEpoch(
                                p.purchaseDateUtcMs!,
                                isUtc: true))
                            : '-')),
                Expanded(
                    child: _detailRow(
                        'Expected Delivery',
                        p.expectedDateUtcMs != null
                            ? DateFormat('dd MMM yyyy').format(
                            DateTime.fromMillisecondsSinceEpoch(
                                p.expectedDateUtcMs!,
                                isUtc: true))
                            : '-')),
              ]),
              const SizedBox(height: 16),

              // Items table
              if (items.isNotEmpty) ...[
                Text('Order Items',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      children: ['Item', 'Ordered', 'Received', 'Pending', 'Total']
                          .map((h) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(h,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ))
                          .toList(),
                    ),
                    ...items.map((item) => TableRow(children: [
                      _cell(item.itemName ?? '-'),
                      _cell('${item.orderedQty ?? 0} ${item.itemUnit ?? ''}'),
                      _cell('${item.receivedQty ?? 0}',
                          color: Colors.green.shade700),
                      _cell('${item.pendingQty}',
                          color: item.pendingQty > 0
                              ? Colors.orange.shade700
                              : Colors.grey),
                      _cell(
                          '₹ ${item.lineTotal.toStringAsFixed(2)}'),
                    ])),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: ₹ ${(p.totalAmount ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(value ?? '-',
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 14)),
      ]),
    );
  }

  Widget _cell(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight:
              color != null ? FontWeight.w600 : FontWeight.normal)),
    );
  }
}
