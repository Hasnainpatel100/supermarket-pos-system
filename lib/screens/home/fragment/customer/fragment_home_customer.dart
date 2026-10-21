import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_market/widget/gradient_action_button.dart';
import 'package:super_market/widget/gradient_app_bar_title.dart';
import 'package:super_market/widget/generic_empty_state.dart';
import 'package:super_market/widget/my_card.dart';
import 'package:super_market/widget/search_app_bar_field.dart';
import '../../../../model/entity_customer.dart';
import '../../../../util/snackbar_util.dart';
import '../../../../core/auth/app_permissions.dart';
import '../../controller_home.dart';
import '../../../customer/activity_customer_form.dart';
import 'controller_home_customer.dart';

class FragmentHomeCustomer extends StatelessWidget {
  const FragmentHomeCustomer({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerHomeCustomer controller =
    Get.isRegistered<ControllerHomeCustomer>()
        ? Get.find<ControllerHomeCustomer>()
        : Get.put(ControllerHomeCustomer());
    final ControllerHome? homeCtrl = Get.isRegistered<ControllerHome>() ? Get.find<ControllerHome>() : null;
    final canCreate = homeCtrl?.hasPermission(AppPermissions.customerCreate) ?? true;
    final canUpdate = homeCtrl?.hasPermission(AppPermissions.customerUpdate) ?? true;
    final canDelete = homeCtrl?.hasPermission(AppPermissions.customerDelete) ?? true;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: GradientAppBarTitle(
          icon: Icons.people_alt_rounded,
          title: 'customers'.tr,
          subtitle: 'manage_customer_base'.tr,
          gradientColors: [Colors.blue.shade400, Colors.blue.shade700],
        ),
        actions: [
          if (canCreate)
            GradientActionButton(
              icon: Icons.person_add_rounded,
              label: 'new_customer'.tr,
              gradientColors: [Colors.teal.shade400, Colors.teal.shade700],
              onTap: () async {
                await Get.dialog(
                  const ActivityCustomerForm(),
                  barrierDismissible: false,
                );
                controller.loadCustomers();
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SearchAppBarField(
            controller: controller.searchController,
            hint: 'search_customer_hint'.tr,
            onChanged: controller.updateSearch,
            onClear: controller.clearSearch,
            hasQuery: controller.searchQuery.isNotEmpty,
          ),
        ),
      ),

      body: Obx(
            () => controller.rxListCustomer.isEmpty
            ? const GenericEmptyState(
                icon: Icons.person_off_rounded,
                title: 'no_customers_found',
                subtitle: 'add_new_customer_to_get_started',
                gradientColors: [Color(0xFFBFDBFE), Color(0xFFDDD6FE)],
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
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  size: 16,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'name'.tr,
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
                                  Icons.phone_rounded,
                                  size: 16,
                                  color: Colors.green.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'phone'.tr,
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
                                  Icons.location_city_rounded,
                                  size: 16,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'city'.tr,
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
                                'status'.tr,
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
                                'actions'.tr,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      rows: controller.rxListCustomer.map((
                          EntityCustomer customer,
                          ) {
                        final isActive = customer.isActive ?? true;

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
                            /// Name — show ★ prefix for VIP customers
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (customer.isVip == true) ...[
                                    Text(
                                      '★ ',
                                      style: TextStyle(
                                        color: Colors.amber.shade600,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                  Text(
                                    customer.name ?? '-',
                                    style: TextStyle(
                                      fontWeight: isActive
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isActive ? null : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// Phone
                            DataCell(
                              Text(
                                customer.phone ?? '-',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isActive ? colorScheme.onSurface : Colors.grey,
                                ),
                              ),
                            ),

                            /// City
                            DataCell(
                              Text(
                                customer.city ?? '-',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isActive ? colorScheme.onSurfaceVariant : Colors.grey,
                                ),
                              ),
                            ),

                            /// Status badge
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
                                    const SizedBox(width: 5),
                                    Text(
                                      isActive ? 'active'.tr : 'inactive'.tr,
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

                            /// ── Action Column ──
                            DataCell(
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                tooltip: 'actions'.tr,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      _showCustomerDetails(context, customer);
                                      break;
                                    case 'edit':
                                      _onEdit(customer, controller);
                                      break;
                                    case 'toggle':
                                      _confirmToggleActive(
                                        context,
                                        customer,
                                        controller,
                                      );
                                      break;
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.visibility_outlined,
                                          size: 20,
                                          color: Colors.blue.shade600,
                                        ),
                                        const SizedBox(width: 12),
                                        Text('view_details'.tr),
                                      ],
                                    ),
                                  ),
                                  if (canUpdate)
                                    PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Text('edit'.tr),
                                      ],
                                    ),
                                  ),
                                  if (canDelete)
                                    PopupMenuItem(
                                    value: 'toggle',
                                    child: Row(
                                      children: [
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
                                          isActive ? 'deactivate'.tr : 'activate'.tr,
                                          style: TextStyle(
                                            color: isActive
                                                ? Colors.orange.shade500
                                                : Colors.green.shade600,
                                          ),
                                        ),
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
            // ── Pagination Footer ──
            Obx(() => _buildPagination(context, controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(BuildContext context, ControllerHomeCustomer controller) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'total_customers_count'.trParams({'count': '${controller.totalCount.value}'}),
            style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: controller.hasPrev ? controller.prevPage : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                label: Text('prev'.tr),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha:0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('page_number'.trParams({'number': '${controller.currentPage.value + 1}'}),
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: controller.hasNext ? controller.nextPage : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: Text('next'.tr),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onEdit(
      EntityCustomer customer,
      ControllerHomeCustomer controller,
      ) async {
    await Get.dialog(
      const ActivityCustomerForm(),
      arguments: customer,
      barrierDismissible: false,
    );
    controller.loadCustomers();
  }

  void _confirmToggleActive(
      BuildContext context,
      EntityCustomer customer,
      ControllerHomeCustomer controller,
      ) {
    final isCurrentlyActive = customer.isActive ?? true;

    Get.defaultDialog(
      title: isCurrentlyActive ? 'deactivate_customer'.tr : 'activate_customer'.tr,
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      middleText: (isCurrentlyActive ? 'deactivate_customer_confirm' : 'activate_customer_confirm')
          .trParams({'item': customer.name ?? ''}),
      confirm: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentlyActive
              ? Colors.orange.shade400
              : Colors.green.shade500,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        icon: Icon(
          isCurrentlyActive
              ? Icons.toggle_off_rounded
              : Icons.toggle_on_rounded,
          size: 20,
        ),
        onPressed: () {
          controller.toggleActive(customer);
          Get.back();
          SnackbarUtil.showSuccess(
            (!(isCurrentlyActive) ? 'customer_activated' : 'customer_deactivated').trParams({'item': customer.name ?? ''}),
          );
        },
        label: Text(isCurrentlyActive ? 'deactivate'.tr : 'activate'.tr),
      ),
      cancel: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () => Get.back(),
        child: Text('cancel'.tr),
      ),
    );
  }

  void _showCustomerDetails(BuildContext context, EntityCustomer customer) {
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
                  Icon(Icons.person, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 10),
                  Text(
                    'customer_details'.tr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow(context, 'name'.tr, customer.name),
              _buildDetailRow(context, 'phone'.tr, customer.phone),
              _buildDetailRow(context, 'email'.tr, customer.email),
              const SizedBox(height: 16),
              Text(
                "address".tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${customer.address ?? ''}\n${customer.city ?? ''} ${customer.state ?? ''} ${customer.zipCode ?? ''}",
                style: const TextStyle(fontSize: 15),
              ),
              if (customer.notes != null && customer.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  "notes".tr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.notes!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Get.back(),
                  child: Text("close".tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
