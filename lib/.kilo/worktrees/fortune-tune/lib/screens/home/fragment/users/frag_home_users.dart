import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/screens/home/fragment/users/controller_home_users.dart';
import 'package:super_market/widget/my_card.dart';

import '../../../../enums/enum_permission.dart';
import '../../../../enums/enum_user_action.dart';
import '../../../../model/entity_user.dart';
import '../../../../util/app_route.dart';
import '../../../../util/snackbar_util.dart';
import '../../controller_home.dart';

class FragHomeUsers extends StatelessWidget {
  final EntityUser? entityUser;

  const FragHomeUsers({super.key, this.entityUser});

  @override
  Widget build(BuildContext context) {
    ControllerHomeUsers controller = Get.put(
      ControllerHomeUsers(entityUser: entityUser),
    );
    ControllerHome controllerHome = Get.find();
    final colorScheme = Theme.of(context).colorScheme;

    final canUpdate = controllerHome.can(EnumPermission.userUpdate);
    final canDisable = controllerHome.can(EnumPermission.userDisable);
    final canAssign = controllerHome.can(EnumPermission.roleAssign);
    final canCreate = controllerHome.can(EnumPermission.userCreate);

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
                Icons.group_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'users'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Manage system users',
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
          /// ── Create User Button ──
          if (canCreate)
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
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await Get.toNamed(AppRoute.user);
                    controller.loadUsers();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_add_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Create User',
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  hintText: 'Search by name or username...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.indigo.shade600,
                    size: 22,
                  ),
                  suffixIcon: Obx(
                    () => controller.rxSearchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: Colors.red.shade400,
                              size: 20,
                            ),
                            onPressed: controller.clearSearch,
                          )
                        : const SizedBox.shrink(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                onChanged: (val) => controller.rxSearchQuery.value = val,
              ),
            ),
          ),
        ),
      ),
      body: Obx(
        () => controller.rxListUser.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade100,
                            Colors.purple.shade100,
                          ],
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
                      child: Icon(
                        Icons.person_search_rounded,
                        size: 64,
                        color: Colors.indigo.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No users found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add a new user to get started',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: MyCard(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                            columns: [
                              DataColumn(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.person_outline_rounded,
                                        size: 16,
                                        color: Colors.indigo.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Username',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataColumn(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.badge_outlined,
                                        size: 16,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Name',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataColumn(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.admin_panel_settings_outlined,
                                        size: 16,
                                        color: Colors.orange.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Role',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataColumn(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.toggle_on_rounded,
                                        size: 16,
                                        color: Colors.purple.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Status',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataColumn(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.access_time_rounded,
                                        size: 16,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Last Login',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataColumn(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.settings_rounded,
                                        size: 16,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Actions',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            rows: controller.rxListUser.map((u) {
                              final isActive = u.isActive ?? true;

                              return DataRow(
                                color: WidgetStateProperty.resolveWith<Color?>((
                                  states,
                                ) {
                                  if (!isActive) {
                                    return Colors.grey.withValues(alpha: 0.05);
                                  }
                                  return null;
                                }),
                                cells: [
                                  /// Username
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.indigo.shade300,
                                                Colors.indigo.shade500,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.indigo
                                                    .withOpacity(0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            (u.username != null &&
                                                    u.username!.isNotEmpty)
                                                ? u.username![0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          u.username ?? '-',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isActive
                                                ? null
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// Name
                                  DataCell(
                                    Text(
                                      "${u.first ?? ''} ${u.last ?? ''}".trim(),
                                      style: TextStyle(
                                        fontWeight: isActive
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                        color: isActive
                                            ? Colors.grey.shade800
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),

                                  /// Role
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.orange.shade100,
                                            Colors.amber.shade100,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.orange.shade200,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        u.role ?? '-',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                  ),

                                  /// Status Badge
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
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
                                              color: isActive
                                                  ? Colors.green.shade600
                                                  : Colors.red.shade500,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isActive ? 'Active' : 'Disabled',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isActive
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  /// Last Login
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 14,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          u.lastLoginAt != null
                                              ? u.lastLoginAt
                                                  .toString()
                                                  .split(' ')
                                                  .first
                                              : "-",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// Actions
                                  DataCell(
                                    PopupMenuButton<EnumUserAction>(
                                      icon: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.more_horiz_rounded,
                                          color: Colors.grey.shade600,
                                          size: 18,
                                        ),
                                      ),
                                      tooltip: 'Actions',
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      onSelected: (action) =>
                                          _handleUserAction(action, u, controller),
                                      itemBuilder: (_) => [
                                        if (canUpdate)
                                          PopupMenuItem(
                                            value: EnumUserAction.edit,
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Icon(
                                                    Icons.edit_outlined,
                                                    size: 16,
                                                    color: Colors.blue.shade600,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Text("Edit"),
                                              ],
                                            ),
                                          ),
                                        if (canAssign)
                                          PopupMenuItem(
                                            value: EnumUserAction.assignRole,
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.orange.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Icon(
                                                    Icons
                                                        .admin_panel_settings_outlined,
                                                    size: 16,
                                                    color:
                                                        Colors.orange.shade600,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Text("Assign Role"),
                                              ],
                                            ),
                                          ),
                                        PopupMenuItem(
                                          value: EnumUserAction.details,
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Icon(
                                                  Icons.visibility_outlined,
                                                  size: 16,
                                                  color: Colors.purple.shade600,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Text("Details"),
                                            ],
                                          ),
                                        ),
                                        if (canDisable)
                                          PopupMenuItem(
                                            value: EnumUserAction.toggle,
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: isActive
                                                        ? Colors.red.shade50
                                                        : Colors.green.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Icon(
                                                    isActive
                                                        ? Icons.block_outlined
                                                        : Icons
                                                            .check_circle_outline,
                                                    size: 16,
                                                    color: isActive
                                                        ? Colors.red.shade600
                                                        : Colors.green.shade600,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(isActive
                                                    ? "Disable"
                                                    : "Enable"),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                            dataRowMaxHeight: 56,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ── Pagination Footer ──
                  Obx(() => _buildPagination(controller)),
                ],
              ),
      ),
    );
  }

  Widget _buildPagination(ControllerHomeUsers controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 16,
                  color: Colors.indigo.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  'Total: ${controller.totalCount.value} users',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: controller.hasPrev ? controller.prevPage : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                label: const Text('Prev'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Page ${controller.currentPage.value + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: controller.hasNext ? controller.nextPage : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: const Text('Next'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleUserAction(
    EnumUserAction action,
    EntityUser user,
    ControllerHomeUsers controller,
  ) {
    switch (action) {
      case EnumUserAction.edit:
        Get.toNamed(
          AppRoute.user,
          arguments: user,
        )?.then((_) => controller.loadUsers());
        break;

      case EnumUserAction.assignRole:
        _showRoleAssignDialog(user);
        break;

      case EnumUserAction.details:
        _showUserDetails(user);
        break;

      case EnumUserAction.toggle:
        Get.defaultDialog(
          title: (user.isActive ?? true) ? "Disable User?" : "Enable User?",
          titleStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          middleText:
              "Are you sure you want to ${(user.isActive ?? true) ? "disable" : "enable"} ${user.username}?",
          confirm: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  (user.isActive ?? true) ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: Icon(
              (user.isActive ?? true)
                  ? Icons.block_outlined
                  : Icons.check_circle_outline,
              size: 18,
            ),
            onPressed: () {
              controller.toggleActive(user);
              Get.back();
              SnackbarUtil.showSuccess("User updated successfully");
            },
            label: Text((user.isActive ?? true) ? "Disable" : "Enable"),
          ),
          cancel: OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
        );
        break;
    }
  }
}

// ==================== PERMISSION ASSIGN & DETAILS =====================

List<String> _sortPermissions(Iterable<String> list) {
  final l = list.toList();
  l.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return l;
}

Widget _permissionList(
  String title,
  RxList<String> list,
  RxList<String> other,
  RxString selected,
) {
  return Expanded(
    child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade100, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Obx(
              () => ListView.separated(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final item = list[i];
                  final isSelected = selected.value == item;

                  return InkWell(
                    onTap: () => selected.value = item,
                    onLongPress: () {
                      list.remove(item);
                      other.add(item);
                      list.value = _sortPermissions(list);
                      other.value = _sortPermissions(other);
                    },
                    child: Container(
                      color:
                          isSelected ? Colors.indigo.withValues(alpha: 0.1) : null,
                      child: ListTile(
                        title: Text(item, style: const TextStyle(fontSize: 13)),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        trailing: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.indigo,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buttons(
  RxList<String> available,
  RxList<String> assigned,
  RxString selA,
  RxString selB,
) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          color: Colors.indigo,
          onPressed: () {
            if (selA.value.isNotEmpty) {
              available.remove(selA.value);
              assigned.add(selA.value);
              available.value = _sortPermissions(available);
              assigned.value = _sortPermissions(assigned);
              selA.value = "";
            }
          },
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.indigo,
          onPressed: () {
            if (selB.value.isNotEmpty) {
              assigned.remove(selB.value);
              available.add(selB.value);
              available.value = _sortPermissions(available);
              assigned.value = _sortPermissions(assigned);
              selB.value = "";
            }
          },
        ),
      ),
    ],
  );
}

void _showRoleAssignDialog(EntityUser user) {
  final all = EnumPermission.values.map((e) => e.name).toList();
  final RxList<String> assigned = RxList.from(
    _sortPermissions(user.permissions ?? []),
  );
  final RxList<String> available = RxList.from(
    _sortPermissions(all.where((p) => !assigned.contains(p))),
  );

  final RxString selA = "".obs;
  final RxString selB = "".obs;

  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Assign Permissions",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "User: ${user.username} (${user.role})",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                children: [
                  _permissionList(
                    "Available Permissions",
                    available,
                    assigned,
                    selA,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buttons(available, assigned, selA, selB),
                  ),
                  _permissionList(
                    "Assigned Permissions",
                    assigned,
                    available,
                    selB,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        user.permissions = assigned.toList();
                        Get.find<ControllerHomeUsers>().saveUser(user);
                        Get.back();
                        SnackbarUtil.showSuccess("Permissions updated");
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.save_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Save Changes",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    ),
  );
}

void _showUserDetails(EntityUser u) {
  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    u.username?[0].toUpperCase() ?? "?",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.username ?? "-",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        u.role ?? "-",
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (u.isActive ?? true)
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: (u.isActive ?? true)
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (u.isActive ?? true) ? "Active" : "Disabled",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (u.isActive ?? true)
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _info("Name", "${u.first ?? ''} ${u.last ?? ''}".trim()),
            _info("Mobile", u.mobileNumber),
            _info("Alt Mobile", u.alternateMobile),
            _info("ID Proof", "${u.idProofType ?? '-'} : ${u.idProofNumber ?? '-'}"),
            _info("Address", u.address),
            _info("Last Login", u.lastLoginAt?.toString()),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Get.back(),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _info(String l, String? v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              l,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              (v != null && v.isNotEmpty) ? v : "-",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
