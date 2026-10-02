import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../model/model_branch.dart';
import '../../../../service/service_brand_context.dart';
import '../../../../util/snackbar_util.dart';
import '../../../../widget/dialog_plan_expiry.dart';
import '../../../brand/dialog_brand_api_config.dart';
import 'controller_home_branch.dart';

class FragmentHomeBranch extends StatelessWidget {
  const FragmentHomeBranch({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerHomeBranch());
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
                    color: Colors.deepPurple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.add_business_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Branch Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(
                  'Manage branches linked to your brands',
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // API Server Settings
          IconButton(
            tooltip: 'API Server Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              final updated = await Get.dialog<bool>(
                const DialogBrandApiConfig(),
                barrierDismissible: true,
              );
              if (updated == true) {
                controller.loadBranches(forceRefresh: true);
              }
            },
          ),
          // Sync button
          IconButton(
            tooltip: 'Sync with API Server',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () => controller.loadBranches(forceRefresh: true),
          ),
          // View Toggle
          Obx(() => IconButton(
                tooltip: controller.rxIsGridView.value ? 'Switch to Table View' : 'Switch to Grid View',
                icon: Icon(controller.rxIsGridView.value ? Icons.table_rows_rounded : Icons.grid_view_rounded),
                onPressed: () => controller.rxIsGridView.value = !controller.rxIsGridView.value,
              )),
          const SizedBox(width: 8),
          // New Branch button
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: controller.openCreateDialog,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('New Branch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.rxIsLoading.value && controller.rxBranchList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.rxHasError.value && controller.rxBranchList.isEmpty) {
          return _buildErrorState(controller);
        }

        return Column(
          children: [
            // KPI Cards
            _buildMetricCards(controller, colorScheme),
            // Filter Bar
            _buildFilterBar(controller, colorScheme),
            // Branch List
            Expanded(
              child: controller.filteredBranches.isEmpty
                  ? _buildEmptyState(controller, colorScheme)
                  : controller.rxIsGridView.value
                      ? _buildGridView(controller, colorScheme)
                      : _buildTableView(controller, colorScheme),
            ),
          ],
        );
      }),
    );
  }

  // ── Metric Cards ───────────────────────────────────────────────────────────

  Widget _buildMetricCards(ControllerHomeBranch controller, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _metricTile(
              title: 'Total Branches',
              value: '${controller.totalBranchCount}',
              icon: Icons.add_business_rounded,
              gradient: [Colors.deepPurple.shade500, Colors.deepPurple.shade800],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metricTile(
              title: 'Active Branches',
              value: '${controller.activeBranchCount}',
              icon: Icons.check_circle_rounded,
              gradient: [Colors.teal.shade500, Colors.teal.shade800],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metricTile(
              title: 'Brands with Branches',
              value: '${controller.uniqueBrandCount}',
              icon: Icons.branding_watermark_rounded,
              gradient: [Colors.indigo.shade500, Colors.indigo.shade800],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metricTileActiveContext(controller, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: gradient.first.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter Bar ─────────────────────────────────────────────────────────────

  Widget _buildFilterBar(ControllerHomeBranch controller, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, code, city, email, phone, brand...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: controller.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: controller.searchController.clear,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Brand Filter
          Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.rxBrandFilter.value,
                    isDense: true,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                    items: controller.brandFilterItems,
                    onChanged: controller.onBrandFilterChanged,
                  ),
                ),
              )),
          const SizedBox(width: 12),
          // Status Filter
          Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.rxStatusFilter.value,
                    isDense: true,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                    items: ControllerHomeBranch.statusFilterOptions.map((s) {
                      return DropdownMenuItem(value: s, child: Text('Status: $s'));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) controller.rxStatusFilter.value = v;
                    },
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ── Grid View ─────────────────────────────────────────────────────────────

  Widget _buildGridView(ControllerHomeBranch controller, ColorScheme colorScheme) {
    final branches = controller.filteredBranches;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 270,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: branches.length,
      itemBuilder: (context, index) => _buildBranchCard(context, branches[index], controller, colorScheme),
    );
  }

  Widget _buildBranchCard(BuildContext context, ModelBranch branch, ControllerHomeBranch controller, ColorScheme colorScheme) {
    final isActive = branch.isActive;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () => controller.openDetailsDialog(branch),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Icon(Icons.add_business_rounded, color: Colors.white, size: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(branch.name.en,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(branch.branchCode,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepPurple.shade700)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(branch.status,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? Colors.green.shade700 : Colors.red.shade700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    splashRadius: 18,
                    onSelected: (action) {
                      if (action == 'view') controller.openDetailsDialog(branch);
                      if (action == 'edit') controller.openEditDialog(branch);
                      if (action == 'select') controller.selectAsActive(branch);
                      if (action == 'plan') DialogPlanExpiry.show(context, branch: branch);
                      if (action == 'history') DialogPlanExpiry.showHistory(context, branch: branch);
                      if (action == 'toggle') controller.toggleStatus(branch);
                      if (action == 'copy') {
                        Clipboard.setData(ClipboardData(text: branch.toJsonString(pretty: true)));
                        SnackbarUtil.showSuccess('JSON copied');
                      }
                      if (action == 'delete') controller.deleteBranch(branch);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility_outlined, size: 16), SizedBox(width: 8), Text('View Details')])),
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit Branch')])),
                      const PopupMenuItem(
                        value: 'select',
                        child: Row(children: [
                          Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.deepPurple),
                          SizedBox(width: 8),
                          Text('Set as Active Branch', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'plan',
                        child: Row(children: [
                          Icon(Icons.credit_card_rounded, size: 16, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text('Plan Details'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'history',
                        child: Row(children: [
                          Icon(Icons.history_edu_rounded, size: 16, color: Colors.teal),
                          SizedBox(width: 8),
                          Text('Plan History'),
                        ]),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy_rounded, size: 16), SizedBox(width: 8), Text('Copy JSON')])),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),

              const Divider(height: 16),

              // Brand
              _infoPill(Icons.branding_watermark_rounded, 'Brand: ${branch.displayBrandName}', Colors.indigo.shade600),
              const SizedBox(height: 5),

              // Location
              if (branch.address.displaySummary.isNotEmpty)
                _infoPill(Icons.location_on_rounded, branch.address.displaySummary, Colors.blue.shade600),
              const SizedBox(height: 5),

              // Phone
              _infoPill(
                Icons.phone_rounded,
                branch.contact.phones.primary.isNotEmpty ? branch.contact.phones.primary : 'No phone',
                Colors.teal.shade600,
              ),

              // Plan & Subscription
              if (branch.planDetails != null) ...[
                const SizedBox(height: 5),
                InkWell(
                  onTap: () => DialogPlanExpiry.show(context, branch: branch),
                  borderRadius: BorderRadius.circular(20),
                  child: _infoPill(
                    Icons.card_membership_rounded,
                    'Plan: ${branch.planDetails!.note.isNotEmpty ? branch.planDetails!.note : "Active"} (${branch.planDetails!.expiryStatusText})',
                    branch.planDetails!.isExpired
                        ? Colors.red.shade700
                        : branch.planDetails!.isExpiringSoon
                            ? Colors.amber.shade800
                            : Colors.teal.shade700,
                  ),
                ),
              ],

              const Spacer(),

              // Service Type Chips
              if (branch.serviceTypes.isNotEmpty)
                SizedBox(
                  height: 26,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: branch.serviceTypes.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 4),
                    itemBuilder: (_, i) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.deepPurple.shade200),
                      ),
                      child: Text(
                        branch.serviceTypes[i].replaceAll('_', ' '),
                        style: TextStyle(fontSize: 9, color: Colors.deepPurple.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => controller.selectAsActive(branch),
                    icon: Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.deepPurple.shade600),
                    label: Text('Select', style: TextStyle(fontSize: 11, color: Colors.deepPurple.shade600)),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.tonalIcon(
                    onPressed: () => controller.openEditDialog(branch),
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    label: const Text('Edit', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // ── Table View ────────────────────────────────────────────────────────────

  Widget _buildTableView(ControllerHomeBranch controller, ColorScheme colorScheme) {
    final branches = controller.filteredBranches;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
          columns: const [
            DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Branch Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Brand', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('City', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Primary Phone', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: branches.map((b) {
            final isActive = b.isActive;
            return DataRow(
              cells: [
                DataCell(Text(b.branchCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataCell(
                  Row(children: [
                    const Icon(Icons.add_business_rounded, size: 16, color: Colors.deepPurple),
                    const SizedBox(width: 6),
                    Text(b.name.en, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  onTap: () => controller.openDetailsDialog(b),
                ),
                DataCell(Text(b.displayBrandName, style: TextStyle(color: Colors.indigo.shade600, fontSize: 12))),
                DataCell(Text(b.address.city.isNotEmpty ? b.address.city : '-')),
                DataCell(Text(b.contact.phones.primary.isNotEmpty ? b.contact.phones.primary : '-')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      b.status,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? Colors.green.shade800 : Colors.red.shade800),
                    ),
                  ),
                ),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.deepPurple),
                      tooltip: 'Set as Active Branch',
                      onPressed: () => controller.selectAsActive(b),
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: 'View Details',
                      onPressed: () => controller.openDetailsDialog(b),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit',
                      onPressed: () => controller.openEditDialog(b),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () => controller.deleteBranch(b),
                    ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Empty & Error States ──────────────────────────────────────────────────

  Widget _buildEmptyState(ControllerHomeBranch controller, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.deepPurple.shade50, shape: BoxShape.circle),
            child: Icon(Icons.add_business_rounded, size: 56, color: Colors.deepPurple.shade400),
          ),
          const SizedBox(height: 16),
          const Text('No Branches Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Create a branch linked to a Brand, or sync with the backend.',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: controller.openCreateDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create First Branch'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ControllerHomeBranch controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to Load Branches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Obx(() => Text(
                controller.rxErrorMessage.value,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                textAlign: TextAlign.center,
              )),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => controller.loadBranches(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  Widget _metricTileActiveContext(ControllerHomeBranch controller, ColorScheme colorScheme) {
    final ctx = Get.find<ServiceBrandContext>();
    return Obx(() {
      final branchName = ctx.rxSelectedBranch.value?.name.en ?? '—';
      final brandName = ctx.rxSelectedBrand.value?.name.en ?? 'None selected';
      return _metricTile(
        title: 'Active Branch',
        value: branchName,
        icon: Icons.location_on_rounded,
        gradient: [Colors.orange.shade600, Colors.deepOrange.shade800],
        subtitle: brandName,
      );
    });
  }
}
