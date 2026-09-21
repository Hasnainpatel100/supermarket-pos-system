import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../model/model_brand.dart';
import '../../../../util/snackbar_util.dart';
import 'controller_home_brand.dart';

class FragmentHomeBrand extends StatelessWidget {
  const FragmentHomeBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerHomeBrand());
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
                    color: Colors.indigo.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.branding_watermark_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Brand Management',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Manage brands & REST API integrations',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // ─── API Config Button ───
          IconButton(
            tooltip: 'Brand API Server Settings',
            icon: const Icon(Icons.dns_outlined),
            onPressed: controller.openApiConfigDialog,
          ),

          // ─── Refresh / Sync Button ───
          IconButton(
            tooltip: 'Sync with API Server',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () => controller.loadBrands(forceRefresh: true),
          ),

          // ─── View Toggle Button (Grid vs Table) ───
          Obx(() => IconButton(
                tooltip: controller.rxIsGridView.value ? 'Switch to Table View' : 'Switch to Grid View',
                icon: Icon(
                  controller.rxIsGridView.value
                      ? Icons.table_rows_rounded
                      : Icons.grid_view_rounded,
                ),
                onPressed: () {
                  controller.rxIsGridView.value = !controller.rxIsGridView.value;
                },
              )),

          const SizedBox(width: 8),

          // ─── Button: Create New Brand ───
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                      Text(
                        'New Brand',
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
      ),
      body: Obx(() {
        if (controller.rxIsLoading.value && controller.rxBrandList.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Column(
          children: [
            // ─── 1. KPI Metric Summary Cards ───
            _buildMetricCards(controller, colorScheme),

            // ─── 2. Search & Filter Bar ───
            _buildFilterBar(controller, colorScheme),

            // ─── 3. Main Brand List (Grid or Table) ───
            Expanded(
              child: controller.filteredBrands.isEmpty
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

  // ─── Metric Cards ─────────────────────────────────────────────────────────

  Widget _buildMetricCards(ControllerHomeBrand controller, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _metricTile(
              title: 'Total Brands',
              count: controller.totalBrandsCount,
              icon: Icons.storefront_rounded,
              gradient: [Colors.indigo.shade600, Colors.indigo.shade800],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metricTile(
              title: 'Active Brands',
              count: controller.activeBrandsCount,
              icon: Icons.check_circle_rounded,
              gradient: [Colors.teal.shade600, Colors.teal.shade800],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metricTile(
              title: 'Supermarket Brands',
              count: controller.marketBrandsCount,
              icon: Icons.shopping_basket_rounded,
              gradient: [Colors.blue.shade600, Colors.blue.shade800],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metricTile(
              title: 'Restaurant Brands',
              count: controller.restaurantBrandsCount,
              icon: Icons.restaurant_rounded,
              gradient: [Colors.orange.shade700, Colors.deepOrange.shade800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String title,
    required int count,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter Bar ───────────────────────────────────────────────────────────

  Widget _buildFilterBar(ControllerHomeBrand controller, ColorScheme colorScheme) {
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
          // Search Input
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search by brand name, GST number, email, phone...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: controller.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          controller.searchController.clear();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // App Type Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Obx(() => DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.rxAppTypeFilter.value,
                    isDense: true,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    items: ControllerHomeBrand.appTypeFilterOptions.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text('Type: $type'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) controller.rxAppTypeFilter.value = val;
                    },
                  ),
                )),
          ),
          const SizedBox(width: 12),

          // Status Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Obx(() => DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.rxStatusFilter.value,
                    isDense: true,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    items: ControllerHomeBrand.statusFilterOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text('Status: $status'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) controller.rxStatusFilter.value = val;
                    },
                  ),
                )),
          ),
        ],
      ),
    );
  }

  // ─── Grid View ────────────────────────────────────────────────────────────

  Widget _buildGridView(ControllerHomeBrand controller, ColorScheme colorScheme) {
    final brands = controller.filteredBrands;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 250,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: brands.length,
      itemBuilder: (context, index) {
        final brand = brands[index];
        return _buildBrandCard(brand, controller, colorScheme);
      },
    );
  }

  Widget _buildBrandCard(
    ModelBrand brand,
    ControllerHomeBrand controller,
    ColorScheme colorScheme,
  ) {
    final isActive = brand.isActive;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () => controller.openDetailsDialog(brand),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Avatar, Name, Popup Menu
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: brand.isMarket
                            ? [Colors.teal.shade400, Colors.teal.shade700]
                            : [Colors.deepOrange.shade400, Colors.deepOrange.shade700],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        brand.isMarket
                            ? Icons.shopping_basket_rounded
                            : Icons.restaurant_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brand.name.en,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                brand.appType,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
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
                            Text(
                              brand.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    splashRadius: 18,
                    onSelected: (action) {
                      if (action == 'view') controller.openDetailsDialog(brand);
                      if (action == 'edit') controller.openEditDialog(brand);
                      if (action == 'toggle') controller.toggleStatus(brand);
                      if (action == 'copy') {
                        Clipboard.setData(ClipboardData(text: brand.toJsonString(pretty: true)));
                        SnackbarUtil.showSuccess('JSON copied');
                      }
                      if (action == 'delete') controller.deleteBrand(brand);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Edit Brand'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isActive ? Icons.cancel_outlined : Icons.check_circle_outline,
                              size: 16,
                              color: isActive ? Colors.orange : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(isActive ? 'Deactivate' : 'Activate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Copy JSON'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Divider(height: 20),

              // Details Body
              _infoPill(
                Icons.pin_rounded,
                'GST/VAT: ${brand.registration.gstNo.isNotEmpty ? brand.registration.gstNo : "N/A"} (${brand.registration.gstType})',
                Colors.teal.shade700,
              ),
              const SizedBox(height: 6),
              _infoPill(
                Icons.phone_rounded,
                brand.contact.phones.primary.isNotEmpty
                    ? brand.contact.phones.primary
                    : 'No phone',
                Colors.blue.shade700,
              ),
              const SizedBox(height: 6),
              _infoPill(
                Icons.email_outlined,
                brand.contact.email.isNotEmpty ? brand.contact.email : 'No email',
                Colors.purple.shade700,
              ),

              const Spacer(),

              // Card Bottom Bar: Quick Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => controller.openDetailsDialog(brand),
                    icon: const Icon(Icons.info_outline_rounded, size: 14),
                    label: const Text('Details', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => controller.openEditDialog(brand),
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
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
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Table View ───────────────────────────────────────────────────────────

  Widget _buildTableView(ControllerHomeBrand controller, ColorScheme colorScheme) {
    final brands = controller.filteredBrands;

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
          headingRowColor: WidgetStateProperty.all(
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          columns: const [
            DataColumn(label: Text('Brand Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('App Type', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('GST/VAT No', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Primary Phone', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: brands.map((b) {
            final isActive = b.isActive;
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      Icon(
                        b.isMarket ? Icons.shopping_basket_rounded : Icons.restaurant_rounded,
                        size: 18,
                        color: b.isMarket ? Colors.teal : Colors.deepOrange,
                      ),
                      const SizedBox(width: 8),
                      Text(b.name.en, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  onTap: () => controller.openDetailsDialog(b),
                ),
                DataCell(Text(b.appType)),
                DataCell(Text(b.registration.gstNo.isNotEmpty ? b.registration.gstNo : '-')),
                DataCell(Text(b.contact.phones.primary.isNotEmpty ? b.contact.phones.primary : '-')),
                DataCell(Text(b.contact.email.isNotEmpty ? b.contact.email : '-')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      b.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        tooltip: 'View Details',
                        onPressed: () => controller.openDetailsDialog(b),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Edit Brand',
                        onPressed: () => controller.openEditDialog(b),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        tooltip: 'Delete Brand',
                        onPressed: () => controller.deleteBrand(b),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(ControllerHomeBrand controller, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront_rounded,
              size: 56,
              color: Colors.indigo.shade400,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Brands Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a brand or sync with the REST API server to get started.',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: controller.openCreateDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create First Brand'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
