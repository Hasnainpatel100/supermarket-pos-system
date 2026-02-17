import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/screens/home/fragment/users/controller_home_users.dart';
import 'package:super_market/widget/my_card.dart';
import 'package:super_market/widget/my_card_with_header.dart';

import '../../../../enums/enum_permission.dart';
import '../../../../enums/enum_user_action.dart';
import '../../../../model/entity_user.dart';
import '../../../../util/app_route.dart';
import '../../../../widget/button_permission.dart';
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

    final canUpdate = controllerHome.can(EnumPermission.userUpdate);
    final canDisable = controllerHome.can(EnumPermission.userDisable);
    final canAssign = controllerHome.can(EnumPermission.roleAssign);

    return Scaffold(
      appBar: AppBar(
        title: Text('users'.tr),
        actions: [
          ButtonPermission(
            permission: EnumPermission.userCreate.name,
            permissions: entityUser!.permissions ?? [],
            icon: Icons.person_add,
            label: 'Create User',
            onPressed: () async {
              await Get.to(AppRoute.user);
              controller.loadUsers();
            },
          ),
        ],
      ),
      body: Obx(
        () => MyCard(
          margin: const EdgeInsets.all(16),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Username')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Last Login')),
              DataColumn(label: Text('Action')),
            ],
            rows: controller.rxListUser.map((u) {
              return DataRow(
                cells: [
                  DataCell(Text(u.username ?? '-')),
                  DataCell(Text("${u.first ?? ''} ${u.last ?? ''}".trim())),
                  DataCell(Text(u.role ?? '-')),
                  DataCell(
                    Text(
                      (u.isActive ?? true) ? "Active" : "Disabled",
                      style: TextStyle(
                        color: (u.isActive ?? true) ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  DataCell(Text(u.lastLoginAt ?? "-")),
                  DataCell(
                    PopupMenuButton<EnumUserAction>(
                      onSelected: (action) =>
                          _handleUserAction(action, u, controller),
                      itemBuilder: (_) => [
                        if (canUpdate)
                          const PopupMenuItem(
                            value: EnumUserAction.edit,
                            child: Text("Edit"),
                          ),
                        if (canAssign)
                          const PopupMenuItem(
                            value: EnumUserAction.assignRole,
                            child: Text("Assign Role"),
                          ),
                        const PopupMenuItem(
                          value: EnumUserAction.details,
                          child: Text("User Details"),
                        ),
                        if (canDisable)
                          PopupMenuItem(
                            value: EnumUserAction.toggle,
                            child: Text(
                              (u.isActive ?? true) ? "Disable" : "Enable",
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

  void _handleUserAction(
    EnumUserAction action,
    EntityUser user,
    ControllerHomeUsers controller,
  ) {
    switch (action) {
      case EnumUserAction.edit:
        Get.toNamed(AppRoute.user, arguments: user);
        controller.loadUsers();
        break;

      case EnumUserAction.assignRole:
        _showRoleAssignDialog(user);
        break;

      case EnumUserAction.details:
        _showUserDetails(user);
        break;

      case EnumUserAction.toggle:
        Get.defaultDialog(
          title: "Confirm",
          middleText:
              "Are you sure you want to ${(user.isActive ?? true) ? "disable" : "enable"} this user?",
          onConfirm: () {
            controller.toggleActive(user);
            Get.back();
          },
          textConfirm: "Yes",
          textCancel: "Cancel",
        );
        break;
    }
  }
}

// ==================== PERMISSION ASSIGN =====================

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
    child: MyCardWithHeader(
      title: title,
      child: Obx(
        () => ListView.separated(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final item = list[i];
            final isSelected = selected.value == item;

            return Container(
              color: isSelected ? Colors.blue.withValues(alpha: 0.25) : null,
              child: ListTile(
                title: Text(item),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () => selected.value = item,
                onLongPress: () {
                  list.remove(item);
                  other.add(item);
                  list.value = _sortPermissions(list);
                  other.value = _sortPermissions(other);
                },
              ),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
        ),
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
        icon: const Icon(Icons.arrow_forward),
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
        icon: const Icon(Icons.arrow_back),
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
      child: Container(
        width: 800,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Assign Permissions to ${user.username}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  _permissionList("Available", available, assigned, selA),
                  _buttons(available, assigned, selA, selB),
                  _permissionList("Assigned", assigned, available, selB),
                ],
              ),
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: const Text("cancel"),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      user.permissions = assigned.toList();
                      Get.find<ControllerHomeUsers>().saveUser(user);
                      Get.back();
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ================= USER DETAILS =================

Widget _info(String l, String? v) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    children: [
      SizedBox(
        width: 120,
        child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      Expanded(child: Text(v ?? "-")),
    ],
  ),
);

void _showUserDetails(EntityUser u) {
  Get.dialog(
    Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "User Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _info("Username", u.username),
            _info("Name", "${u.first} ${u.last}"),
            _info("Role", u.role),
            _info("Status", (u.isActive ?? true) ? "Active" : "Disabled"),
            _info("Mobile", u.mobileNumber),
            _info("Alt Mobile", u.alternateMobile),
            _info("ID Proof", "${u.idProofType} : ${u.idProofNumber}"),
            _info("Address", u.address),
            _info("Last Login", u.lastLoginAt),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    ),
  );
}
