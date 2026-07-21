import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/screens/home/fragment/users/controller_home_users.dart';
import 'package:super_market/screens/user/activity_user.dart';
import 'package:super_market/widget/my_card.dart';

import '../../../../enums/enum_permission.dart';
import '../../../../enums/enum_user_action.dart';
import '../../../../model/entity_user.dart';
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
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.group_outlined, color: colorScheme.primary, size: 24),
            const SizedBox(width: 10),
            Text('users'.tr, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          /// ── Create User Button ──
          if (canCreate)
            FilledButton.icon(
              onPressed: () async {
                await Get.dialog(
                  const ActivityUser(),
                  barrierDismissible: false,
                );
                controller.loadUsers();
              },
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: Text('create_user'.tr),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'search_users_hint'.tr,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                ),
                suffixIcon: Obx(
                  () => controller.rxSearchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.grey.shade500,
                          ),
                          onPressed: () {
                            controller.searchController.clear();
                            controller.rxSearchQuery.value = '';
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: (val) => controller.rxSearchQuery.value = val,
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
                      'no_users_found'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : MyCard(
                margin: const EdgeInsets.all(16),
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
                        DataColumn(label: Text('username'.tr)),
                        DataColumn(label: Text('name'.tr)),
                        DataColumn(label: Text('role'.tr)),
                        DataColumn(label: Text('status'.tr)),
                        DataColumn(label: Text('last_login'.tr)),
                        DataColumn(label: Text('actions'.tr)),
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
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      (u.username != null &&
                                              u.username!.isNotEmpty)
                                          ? u.username![0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    u.username ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// Name
                            DataCell(
                              Text("${u.first ?? ''} ${u.last ?? ''}".trim()),
                            ),

                            /// Role
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  u.role ?? '-',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue.shade700,
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
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green.shade600
                                            : Colors.red.shade500,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isActive ? 'active'.tr : 'disabled'.tr,
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
                              Text(
                                u.lastLoginAt != null
                                    ? u.lastLoginAt.toString().split(' ').first
                                    : "-",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                            /// Actions
                            DataCell(
                              PopupMenuButton<EnumUserAction>(
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  color: Colors.grey.shade500,
                                ),
                                tooltip: 'actions'.tr,
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
                                          const Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 12),
                                          Text('edit'.tr),
                                        ],
                                      ),
                                    ),
                                  if (canAssign)
                                    PopupMenuItem(
                                      value: EnumUserAction.assignRole,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.admin_panel_settings_outlined,
                                            size: 20,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 12),
                                          Text('assign_role'.tr),
                                        ],
                                      ),
                                    ),
                                  PopupMenuItem(
                                    value: EnumUserAction.details,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.visibility_outlined,
                                          size: 20,
                                          color: Colors.deepPurple,
                                        ),
                                        const SizedBox(width: 12),
                                        Text('details'.tr),
                                      ],
                                    ),
                                  ),
                                  if (canDisable)
                                    PopupMenuItem(
                                      value: EnumUserAction.toggle,
                                      child: Row(
                                        children: [
                                          Icon(
                                            isActive
                                                ? Icons.block_outlined
                                                : Icons.check_circle_outline,
                                            size: 20,
                                            color: isActive
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(isActive ? 'disable'.tr : 'enable'.tr),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      dataRowMaxHeight: 52,
                    ),
                  ),
                ),
              ),
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
        Get.dialog(
          const ActivityUser(),
          arguments: user,
          barrierDismissible: false,
        ).then((_) => controller.loadUsers());
        break;

      case EnumUserAction.assignRole:
        _showRoleAssignDialog(user);
        break;

      case EnumUserAction.details:
        _showUserDetails(user);
        break;

      case EnumUserAction.toggle:
        Get.defaultDialog(
          title: (user.isActive ?? true) ? 'disable_user_title'.tr : 'enable_user_title'.tr,
          titleStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          middleText:
              'toggle_user_confirm'.tr.replaceFirst('%s', (user.isActive ?? true) ? 'disable'.tr : 'enable'.tr).replaceFirst('%u', user.username ?? ''),
          confirm: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: (user.isActive ?? true)
                  ? Colors.red
                  : Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              controller.toggleActive(user);
              Get.back();
              SnackbarUtil.showSuccess('user_updated_success'.tr);
            },
            child: Text((user.isActive ?? true) ? 'disable'.tr : 'enable'.tr),
          ),
          cancel: OutlinedButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
        );
        break;
    }
  }
}

// ==================== PERMISSION ASSIGN & DETAILS (Kept Same) =====================

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
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
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
                      color: isSelected
                          ? Colors.blue.withValues(alpha: 0.1)
                          : null,
                      child: ListTile(
                        title: Text(item, style: const TextStyle(fontSize: 13)),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        trailing: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.blue,
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
      IconButton(
        icon: const Icon(Icons.arrow_forward_rounded),
        color: Colors.blue,
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
      IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        color: Colors.blue,
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
                const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 28,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  'assign_permissions'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${'user'.tr}: ${user.username} (${user.role})',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                children: [
                  _permissionList(
                    'available_permissions'.tr,
                    available,
                    assigned,
                    selA,
                  ),
                  _buttons(available, assigned, selA, selB),
                  _permissionList(
                    'assigned_permissions'.tr,
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
                  onPressed: () => Get.back(),
                  child: Text('cancel'.tr),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () {
                    user.permissions = assigned.toList();
                    Get.find<ControllerHomeUsers>().saveUser(user);
                    Get.back();
                    SnackbarUtil.showSuccess('permissions_updated'.tr);
                  },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text('save_changes'.tr),
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
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    u.username?[0].toUpperCase() ?? "?",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                    Text(
                      u.role ?? "-",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (u.isActive ?? true)
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (u.isActive ?? true) ? 'active'.tr : 'disabled'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (u.isActive ?? true) ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _info('name'.tr, '${u.first} ${u.last}'),
            _info('mobile'.tr, u.mobileNumber),
            _info('alt_mobile'.tr, u.alternateMobile),
            _info('id_proof'.tr, '${u.idProofType} : ${u.idProofNumber}'),
            _info('address'.tr, u.address),
            _info('last_login'.tr, u.lastLoginAt?.toString()),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Get.back(),
                child: Text('close'.tr),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _info(String l, String? v) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
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
          v ?? "-",
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    ],
  ),
);
