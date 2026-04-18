import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/screens/home/fragment/purchase_supplier/supplier/activity_supplier_form.dart';
import '../../../../../model/entity_supplier.dart';
import '../../../../../util/snackbar_util.dart';
import '../../../../../widget/my_card.dart';
import 'controller_home_supplier.dart';

class FragmentHomeSupplier extends StatelessWidget {
  const FragmentHomeSupplier({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ControllerHomeSupplier>()
        ? Get.find<ControllerHomeSupplier>()
        : Get.put(ControllerHomeSupplier());
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
                  colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suppliers',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Manage your vendor base',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await Get.to(() => const ActivitySupplierForm());
                  controller.loadSuppliers();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: const [
                      Icon(Icons.add_business_rounded,
                          size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'New Supplier',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
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
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone or code...',
                hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.indigo.shade600, size: 22),
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
                  borderSide: BorderSide.none,
                ),
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

      // ── Body ──
      body: Column(
        children: [
          // Table
          Expanded(
            child: Obx(
                  () => controller.rxListSupplier.isEmpty
                  ? _buildEmpty()
                  : MyCard(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                        _col(context, 'Code', Icons.tag_rounded,
                            Colors.indigo),
                        _col(context, 'Name',
                            Icons.person_outline_rounded, Colors.blue),
                        _col(context, 'Phone', Icons.phone_rounded,
                            Colors.green),
                        _col(context, 'GST',
                            Icons.receipt_long_rounded, Colors.orange),
                        _col(context, 'Outstanding',
                            Icons.account_balance_wallet_rounded, Colors.red),
                        _col(context, 'Status',
                            Icons.toggle_on_rounded, Colors.purple),
                        _col(context, 'Actions',
                            Icons.settings_rounded, Colors.grey),
                      ],
                      rows: controller.rxListSupplier
                          .map((s) => _buildRow(
                          context, s, controller, colorScheme))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Pagination Footer ──
          Obx(() => _buildPagination(controller)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TABLE HELPERS
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
                  color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  DataRow _buildRow(
      BuildContext context,
      EntitySupplier s,
      ControllerHomeSupplier controller,
      ColorScheme colorScheme,
      ) {
    final isActive = s.isActive ?? true;

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((_) {
        if (!isActive) return Colors.grey.withValues(alpha: 0.05);
        return null;
      }),
      cells: [
        // Code
        DataCell(
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              s.supplierCode ?? '-',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.indigo),
            ),
          ),
        ),

        // Name
        DataCell(Text(
          s.name ?? '-',
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? null : Colors.grey,
          ),
        )),

        // Phone
        DataCell(Text(
          s.phone ?? '-',
          style: TextStyle(
              fontSize: 13,
              color: isActive ? Colors.grey.shade800 : Colors.grey),
        )),

        // GST
        DataCell(Text(
          s.gstNumber ?? '-',
          style: TextStyle(
              fontSize: 13,
              color: isActive ? Colors.grey.shade700 : Colors.grey),
        )),

        // Outstanding balance
        DataCell(_buildOutstandingCell(s)),

        // Status badge
        DataCell(_statusBadge(isActive)),

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
                  _showDetails(context, s);
                  break;
                case 'edit':
                  _onEdit(s, controller);
                  break;
                case 'toggle':
                  _confirmToggle(context, s, controller);
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
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined,
                      size: 20, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  const Text('Edit'),
                ]),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(children: [
                  Icon(
                    isActive
                        ? Icons.toggle_off_rounded
                        : Icons.toggle_on_rounded,
                    size: 22,
                    color: isActive
                        ? Colors.orange.shade400
                        : Colors.green.shade500,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isActive ? 'Deactivate' : 'Activate',
                    style: TextStyle(
                        color: isActive
                            ? Colors.orange.shade500
                            : Colors.green.shade600),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOutstandingCell(EntitySupplier s) {
    final amount = s.totalOutstanding ?? 0;
    if (amount <= 0.001) {
      return Text('—',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '₹ ${amount.toStringAsFixed(2)}',
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700),
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade600 : Colors.red.shade500,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  PAGINATION
  // ─────────────────────────────────────────────

  Widget _buildPagination(ControllerHomeSupplier controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${controller.totalCount.value} suppliers',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed:
                controller.hasPrev ? controller.prevPage : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                label: const Text('Prev'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Page ${controller.currentPage.value + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed:
                controller.hasNext ? controller.nextPage : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: const Text('Next'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
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
                colors: [Colors.indigo.shade100, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.local_shipping_rounded,
                size: 64, color: Colors.indigo.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            'No suppliers found',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a new supplier to get started',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  DIALOGS / NAVIGATION
  // ─────────────────────────────────────────────

  void _onEdit(
      EntitySupplier supplier, ControllerHomeSupplier controller) async {
    await Get.to(() => const ActivitySupplierForm(), arguments: supplier);
    controller.loadSuppliers();
  }

  void _confirmToggle(
      BuildContext context,
      EntitySupplier supplier,
      ControllerHomeSupplier controller,
      ) {
    final isActive = supplier.isActive ?? true;
    Get.defaultDialog(
      title: isActive ? 'Deactivate Supplier?' : 'Activate Supplier?',
      titleStyle:
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      middleText:
      'Are you sure you want to ${isActive ? "deactivate" : "activate"} "${supplier.name}"?',
      confirm: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor:
          isActive ? Colors.orange.shade400 : Colors.green.shade500,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        icon: Icon(
          isActive
              ? Icons.toggle_off_rounded
              : Icons.toggle_on_rounded,
          size: 20,
        ),
        onPressed: () {
          controller.toggleActive(supplier);
          Get.back();
          SnackbarUtil.showSuccess(
            '${supplier.name} ${!isActive ? "activated" : "deactivated"}',
          );
        },
        label: Text(isActive ? 'Deactivate' : 'Activate'),
      ),
      cancel: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
      ),
    );
  }

  void _showDetails(BuildContext context, EntitySupplier s) {
    Get.dialog(
      Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 540,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_shipping_rounded,
                      color: Theme.of(context).primaryColor),
                  const SizedBox(width: 10),
                  Text(
                    'Supplier Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back()),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              _detailRow('Code', s.supplierCode),
              _detailRow('Name', s.name),
              _detailRow('Contact Person', s.contactPerson),
              _detailRow('Phone', s.phone),
              _detailRow('Email', s.email),
              _detailRow('GST Number', s.gstNumber),
              _detailRow('Address', s.address),
              const SizedBox(height: 16),

              // ── Outstanding Balance ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (s.totalOutstanding ?? 0) > 0.001
                      ? Colors.red.withOpacity(0.06)
                      : Colors.green.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (s.totalOutstanding ?? 0) > 0.001
                        ? Colors.red.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Row(children: [
                  Icon(
                    (s.totalOutstanding ?? 0) > 0.001
                        ? Icons.account_balance_wallet_rounded
                        : Icons.check_circle_rounded,
                    color: (s.totalOutstanding ?? 0) > 0.001
                        ? Colors.red.shade600
                        : Colors.green.shade600,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Outstanding',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500)),
                      Text(
                        (s.totalOutstanding ?? 0) > 0.001
                            ? '₹ ${s.totalOutstanding!.toStringAsFixed(2)}'
                            : 'No dues — fully settled',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (s.totalOutstanding ?? 0) > 0.001
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ]),
              ),

              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value?.isNotEmpty == true ? value! : '-',
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
