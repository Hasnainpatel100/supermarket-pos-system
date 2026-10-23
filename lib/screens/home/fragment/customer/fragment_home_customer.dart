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
    final canCreate = homeCtrl?.hasAnyPermission([
      'CREATE_CUSTOMER',
      'CUSTOMER_CREATE',
      'ADD_CUSTOMER',
      'CUSTOMER_ADD',
      AppPermissions.customerCreate,
    ]) ?? true;
    final canUpdate = homeCtrl?.hasAnyPermission([
      'UPDATE_CUSTOMER',
      'CUSTOMER_UPDATE',
      'EDIT_CUSTOMER',
      'CUSTOMER_EDIT',
      AppPermissions.customerUpdate,
    ]) ?? true;
    final canDelete = homeCtrl?.hasAnyPermission([
      'DELETE_CUSTOMER',
      'CUSTOMER_DELETE',
      AppPermissions.customerDelete,
    ]) ?? true;
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
            Obx(
              () => GradientActionButton(
                icon: controller.rxShowCreateForm.value
                    ? Icons.close_rounded
                    : Icons.person_add_rounded,
                label: controller.rxShowCreateForm.value
                    ? (controller.isEditing ? 'Cancel Edit' : 'Close Form')
                    : 'new_customer'.tr,
                gradientColors: controller.rxShowCreateForm.value
                    ? [Colors.grey.shade600, Colors.grey.shade800]
                    : [Colors.teal.shade400, Colors.teal.shade700],
                onTap: controller.toggleCreateForm,
              ),
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

      floatingActionButton: canCreate
          ? Obx(
              () => FloatingActionButton.extended(
                onPressed: controller.toggleCreateForm,
                icon: Icon(
                  controller.rxShowCreateForm.value
                      ? Icons.close_rounded
                      : Icons.person_add_rounded,
                ),
                label: Text(
                  controller.rxShowCreateForm.value
                      ? (controller.isEditing ? 'Cancel Edit' : 'Close Form')
                      : 'new_customer'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: controller.rxShowCreateForm.value
                    ? Colors.grey.shade700
                    : colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
            )
          : null,

      body: Obx(() {
        if (controller.rxListCustomer.isEmpty) {
          if (controller.rxShowCreateForm.value) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: _buildInlineCustomerFormCard(context, controller),
            );
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GenericEmptyState(
                  icon: Icons.person_off_rounded,
                  title: 'no_customers_found',
                  subtitle: 'add_new_customer_to_get_started',
                  gradientColors: [Color(0xFFBFDBFE), Color(0xFFDDD6FE)],
                ),
                if (canCreate) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => controller.openCreateForm(),
                    icon: const Icon(Icons.person_add_rounded, size: 20),
                    label: Text(
                      'new_customer'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          children: [
            if (controller.rxShowCreateForm.value)
              _buildInlineCustomerFormCard(context, controller),
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
            _buildPagination(context, controller),
          ],
        );
      }),
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
      ) {
    controller.openCreateForm(customer);
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

  Widget _buildInlineCustomerFormCard(
    BuildContext context,
    ControllerHomeCustomer controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = controller.isEditing;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      elevation: 6,
      shadowColor: colorScheme.primary.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Form(
        key: controller.createFormKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Row ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isEditing
                            ? [Colors.orange.shade500, Colors.deepOrange.shade700]
                            : [Colors.teal.shade500, Colors.teal.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.manage_accounts_rounded
                          : Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'edit_customer'.tr
                              : 'new_customer'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'Update existing customer details in your database'
                              : 'Fill in details below to register customer into RH POS',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'close'.tr,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: controller.closeCreateForm,
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.15)),
              const SizedBox(height: 16),

              // ── Responsive Form Content ──
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 750;
                  if (isCompact) {
                    return Column(
                      children: [
                        _buildNameField(controller, isDark, colorScheme),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildPhoneField(controller, isDark, colorScheme)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildEmailField(controller, isDark, colorScheme)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildAddressField(controller, isDark, colorScheme),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(flex: 2, child: _buildCityField(controller, isDark, colorScheme)),
                            const SizedBox(width: 10),
                            Expanded(flex: 2, child: _buildStateField(controller, isDark, colorScheme)),
                            const SizedBox(width: 10),
                            Expanded(flex: 1, child: _buildZipField(controller, isDark, colorScheme)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildNotesField(controller, isDark, colorScheme)),
                            const SizedBox(width: 10),
                            _buildVipSwitch(controller, isDark, colorScheme),
                          ],
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildNameField(controller, isDark, colorScheme)),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: _buildPhoneField(controller, isDark, colorScheme)),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: _buildEmailField(controller, isDark, colorScheme)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildAddressField(controller, isDark, colorScheme)),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: _buildCityField(controller, isDark, colorScheme)),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: _buildStateField(controller, isDark, colorScheme)),
                          const SizedBox(width: 12),
                          Expanded(flex: 1, child: _buildZipField(controller, isDark, colorScheme)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildNotesField(controller, isDark, colorScheme)),
                          const SizedBox(width: 12),
                          _buildVipSwitch(controller, isDark, colorScheme),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // ── Action Buttons ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: controller.clearCreateForm,
                    icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: controller.closeCreateForm,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('cancel'.tr),
                  ),
                  const SizedBox(width: 10),
                  Obx(
                    () => ElevatedButton.icon(
                      onPressed: controller.rxIsSaving.value ? null : controller.saveCustomerFromForm,
                      icon: controller.rxIsSaving.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        isEditing ? 'update_customer'.tr : 'save_customer'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEditing ? Colors.deepOrange.shade600 : colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
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

  Widget _buildNameField(ControllerHomeCustomer controller, bool isDark, ColorScheme colorScheme) {
    return TextFormField(
      controller: controller.nameController,
      decoration: InputDecoration(
        labelText: '${'customer_name'.tr} *',
        hintText: 'e.g. John Doe',
        prefixIcon: const Icon(Icons.person_rounded, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey.shade50,
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Customer name is required';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField(ControllerHomeCustomer controller, bool isDark, ColorScheme colorScheme) {
    return TextFormField(
      controller: controller.phoneController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'phone_number'.tr,
        hintText: '10 digit number',
        prefixIcon: const Icon(Icons.phone_rounded, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey.shade50,
      ),
    );
  }

  Widget _buildEmailField(ControllerHomeCustomer controller, bool isDark, ColorScheme colorScheme) {
    return TextFormField(
      controller: controller.emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'email_address'.tr,
        hintText: 'user@gmail.com',
        prefixIcon: const Icon(Icons.email_rounded, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey.shade50,
      ),
    );
  }

  Widget _buildAddressField(ControllerHomeCustomer controller, bool isDark, ColorScheme colorScheme) {
    return TextFormField(
      controller: controller.addressController,
      decoration: InputDecoration(
        labelText: 'street_address'.tr,
        hintText: 'Street / Area / Building',
        prefixIcon: const Icon(Icons.home_rounded, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey.shade50,
      ),
    );
  }

  Widget _buildCityField(ControllerHomeCustomer controller, bool isDark, ColorScheme colorScheme) {
    return TextFormField(
      controller: controller.cityController,
      decoration: InputDecoration(
        labelText: 'city'.tr,
        prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey.shade50,
      ),
    );
  }

  Widget _buildStateField(ControllerHomeCustomer controller, bool isDark, ColorScheme colorScheme) {
    return TextFormField(
      controller: controller.stateController,
      decoration: InputDecoration(
        labelText: 'state'.tr,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey.shade50,
      ),
    );
  }

  Widget _buildZipField(ControllerHomeCustomer controller, bool isDark, ColorScheme colorScheme) {
    return TextFormField(
      controller: controller.zipController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'zip_code'.tr,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey.shade50,
      ),
    );
  }

  Widget _buildNotesField(ControllerHomeCustomer controller, bool isDark, ColorScheme colorScheme) {
    return TextFormField(
      controller: controller.notesController,
      maxLines: 1,
      decoration: InputDecoration(
        labelText: 'notes'.tr,
        hintText: 'Special preferences, discount terms, or notes',
        prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey.shade50,
      ),
    );
  }

  Widget _buildVipSwitch(ControllerHomeCustomer controller, bool isDark, ColorScheme colorScheme) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: controller.rxIsVip.value
              ? Colors.amber.withValues(alpha: 0.1)
              : (isDark ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: controller.rxIsVip.value ? Colors.amber.shade400 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              color: controller.rxIsVip.value ? Colors.amber.shade700 : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'vip_customer'.tr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: controller.rxIsVip.value ? Colors.amber.shade800 : colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: controller.rxIsVip.value,
              onChanged: (val) => controller.rxIsVip.value = val,
              activeTrackColor: Colors.amber.shade600,
            ),
          ],
        ),
      ),
    );
  }
}
