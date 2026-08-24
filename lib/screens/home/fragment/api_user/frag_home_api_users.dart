import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../model/model_api_user.dart';
import '../../../../widget/my_card.dart';
import 'controller_home_api_users.dart';

class FragHomeApiUsers extends StatelessWidget {
  const FragHomeApiUsers({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ControllerHomeApiUsers());
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.cloud_sync_rounded, color: colorScheme.primary, size: 26),
            const SizedBox(width: 10),
            const Text('API Users', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // Config Server Button
          IconButton.filledTonal(
            onPressed: controller.openConfigDialog,
            icon: const Icon(Icons.settings_remote_rounded, size: 18),
            tooltip: 'Configure API Server',
          ),
          const SizedBox(width: 8),

          // Refresh Button
          IconButton.filledTonal(
            onPressed: () => controller.loadUsers(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            tooltip: 'Sync API Users',
          ),
          const SizedBox(width: 8),

          // Toggle View (Table vs Grid)
          Obx(
            () => IconButton.filledTonal(
              onPressed: () => controller.rxIsGridView.value = !controller.rxIsGridView.value,
              icon: Icon(
                controller.rxIsGridView.value ? Icons.table_chart_outlined : Icons.grid_view_rounded,
                size: 18,
              ),
              tooltip: controller.rxIsGridView.value ? 'Table View' : 'Grid View',
            ),
          ),
          const SizedBox(width: 12),

          // Create API User Button
          FilledButton.icon(
            onPressed: controller.openCreateDialog,
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Create API User'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // ── 1. Top Summary Metric Cards ──
          Obx(
            () => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  _metricCard(
                    context,
                    'Total API Users',
                    '${controller.totalUsersCount}',
                    Icons.people_alt_rounded,
                    colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  _metricCard(
                    context,
                    'Active Users',
                    '${controller.activeUsersCount}',
                    Icons.check_circle_outline_rounded,
                    Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _metricCard(
                    context,
                    'Platform Users',
                    '${controller.platformUsersCount}',
                    Icons.hub_outlined,
                    Colors.deepPurple,
                  ),
                  const SizedBox(width: 12),
                  _metricCard(
                    context,
                    'Support Team',
                    '${controller.supportTeamUsersCount}',
                    Icons.support_agent_rounded,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),

          // ── 2. Search & Filter Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Search TextField
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, username, email, phone, role...',
                      prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
                      suffixIcon: Obx(
                        () => controller.rxSearchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  controller.searchController.clear();
                                  controller.rxSearchQuery.value = '';
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      filled: true,
                      fillColor: colorScheme.surface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // UserType Dropdown Filter
                Obx(
                  () => SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      value: controller.rxUserTypeFilter.value,
                      decoration: InputDecoration(
                        labelText: 'User Type',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ControllerHomeApiUsers.userTypeFilterOptions
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) controller.rxUserTypeFilter.value = val;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Role Dropdown Filter
                Obx(
                  () => SizedBox(
                    width: 170,
                    child: DropdownButtonFormField<String>(
                      value: controller.rxRoleFilter.value,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ControllerHomeApiUsers.roleFilterOptions
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) controller.rxRoleFilter.value = val;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 3. Main Data View (Loading / Empty / Table / Grid) ──
          Expanded(
            child: Obx(() {
              if (controller.rxIsLoading.value) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Fetching API Users from server...'),
                    ],
                  ),
                );
              }

              final users = controller.filteredUsers;

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_search_rounded,
                          size: 56,
                          color: colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No API Users found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click "Create API User" to add a new user or adjust filters.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: controller.openCreateDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create API User'),
                      ),
                    ],
                  ),
                );
              }

              if (controller.rxIsGridView.value) {
                return _buildGridView(context, users, controller);
              }

              return _buildTableView(context, users, controller);
            }),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: MyCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableView(
    BuildContext context,
    List<ModelApiUser> users,
    ControllerHomeApiUsers controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return MyCard(
      margin: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 14,
            horizontalMargin: 16,
            headingRowColor: WidgetStateProperty.all(colorScheme.primary.withValues(alpha: 0.04)),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: colorScheme.onSurface,
            ),
            columns: const [
              DataColumn(label: Text('Username')),
              DataColumn(label: Text('Full Name')),
              DataColumn(label: Text('User Type')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Contact Details')),
              DataColumn(label: Text('Permissions')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: users.map((u) {
              return DataRow(
                cells: [
                  // Username
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                          child: Text(
                            u.username.isNotEmpty ? u.username[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          u.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Name
                  DataCell(Text(u.fullName)),

                  // User Type Badge
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: u.isPlatform
                            ? Colors.deepPurple.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        u.userType,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: u.isPlatform ? Colors.deepPurple : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ),

                  // Role Badge
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        u.role,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ),

                  // Contact
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.email, style: const TextStyle(fontSize: 12)),
                        Text(u.phoneNumber, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),

                  // Permissions Count Badge
                  DataCell(
                    Chip(
                      label: Text('${u.permissionsCount} Perms', style: const TextStyle(fontSize: 10)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                  // Status Badge
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: u.isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 3,
                            backgroundColor: u.isActive ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            u.isActive ? 'Active' : 'Disabled',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: u.isActive ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Actions Popup
                  DataCell(
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade600),
                      onSelected: (action) {
                        if (action == 'details') controller.showUserDetails(u);
                        if (action == 'edit') controller.openEditDialog(u);
                        if (action == 'toggle') controller.toggleActive(u);
                        if (action == 'delete') controller.deleteUser(u);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'details',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 18, color: Colors.purple),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Edit User'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                u.isActive ? Icons.block_outlined : Icons.check_circle_outline,
                                size: 18,
                                color: u.isActive ? Colors.amber.shade800 : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(u.isActive ? 'Disable User' : 'Enable User'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete User'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(
    BuildContext context,
    List<ModelApiUser> users,
    ControllerHomeApiUsers controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 360,
          mainAxisExtent: 220,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: users.length,
        itemBuilder: (context, i) {
          final u = users[i];
          final colorScheme = Theme.of(context).colorScheme;

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          u.username.isNotEmpty ? u.username[0].toUpperCase() : '?',
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '@${u.username}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        onPressed: () => controller.showUserDetails(u),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          u.userType,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          u.role,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('📧 ${u.email}', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                  Text('📞 ${u.phoneNumber}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${u.permissionsCount} permissions',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      OutlinedButton(
                        onPressed: () => controller.showUserDetails(u),
                        child: const Text('View Details', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
