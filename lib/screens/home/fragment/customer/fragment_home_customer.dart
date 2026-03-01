import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../model/entity_customer.dart';
import '../../../../util/snackbar_util.dart';
import '../../../customer/activity_customer_form.dart';
import '../../../../widget/my_card.dart';
import 'controller_home_customer.dart';

class FragmentHomeCustomer extends StatelessWidget {
  const FragmentHomeCustomer({super.key});

  @override
  Widget build(BuildContext context) {
    final ControllerHomeCustomer controller =
        Get.isRegistered<ControllerHomeCustomer>()
        ? Get.find<ControllerHomeCustomer>()
        : Get.put(ControllerHomeCustomer());
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
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customers',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Manage your client base',
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
          /// ── Button: New Customer ──
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
                  await Get.to(() => const ActivityCustomerForm());
                  controller.loadCustomers();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.person_add_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'New Customer',
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
                hintText: 'Search by name or phone...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.blue.shade600,
                  size: 22,
                ),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
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
              onChanged: controller.updateSearch,
            ),
          ),
        ),
      ),

      body: Obx(
        () => controller.rxListCustomer.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade100,
                            Colors.purple.shade100,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_off_rounded,
                        size: 64,
                        color: Colors.blue.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No customers found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add a new customer to get started',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
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
                                'Phone',
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
                                'City',
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
                                  color: isActive
                                      ? Colors.grey.shade800
                                      : Colors.grey,
                                ),
                              ),
                            ),

                            /// City
                            DataCell(
                              Text(
                                customer.city ?? '-',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isActive
                                      ? Colors.grey.shade700
                                      : Colors.grey,
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
                                      isActive ? 'Active' : 'Inactive',
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
                                  color: Colors.grey.shade500,
                                ),
                                tooltip: 'Actions',
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
                                        const Text('View Details'),
                                      ],
                                    ),
                                  ),
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
                                        const Text('Edit'),
                                      ],
                                    ),
                                  ),
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
                                          isActive ? 'Deactivate' : 'Activate',
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
    );
  }

  void _onEdit(
    EntityCustomer customer,
    ControllerHomeCustomer controller,
  ) async {
    await Get.to(() => const ActivityCustomerForm(), arguments: customer);
    controller.loadCustomers();
  }

  void _confirmToggleActive(
    BuildContext context,
    EntityCustomer customer,
    ControllerHomeCustomer controller,
  ) {
    final isCurrentlyActive = customer.isActive ?? true;

    Get.defaultDialog(
      title: isCurrentlyActive ? 'Deactivate Customer?' : 'Activate Customer?',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      middleText:
          'Are you sure you want to ${isCurrentlyActive ? "deactivate" : "activate"} "${customer.name}"?',
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
            '${customer.name} ${!(isCurrentlyActive) ? "activated" : "deactivated"}',
          );
        },
        label: Text(isCurrentlyActive ? 'Deactivate' : 'Activate'),
      ),
      cancel: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
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
                    'Customer Details',
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
              _buildDetailRow(context, "Name", customer.name),
              _buildDetailRow(context, "Phone", customer.phone),
              _buildDetailRow(context, "Email", customer.email),
              const SizedBox(height: 16),
              const Text(
                "Address",
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
                const Text(
                  "Notes",
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
                  child: const Text("Close"),
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
