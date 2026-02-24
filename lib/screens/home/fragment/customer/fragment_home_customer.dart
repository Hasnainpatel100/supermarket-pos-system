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
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.people_alt_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text(
              'Customers',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          /// ── Button: New Customer ──
          FilledButton.icon(
            onPressed: () async {
              await Get.to(() => const ActivityCustomerForm());
              controller.loadCustomers();
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Customer'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                hintText: 'Search by name or phone...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                ),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.grey.shade500,
                          ),
                          onPressed: controller.clearSearch,
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
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_off_rounded,
                        size: 56,
                        color: colorScheme.primary.withValues(alpha: 0.5),
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
                              Icon(
                                Icons.person_outline_rounded,
                                size: 15,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              const Text('Name'),
                            ],
                          ),
                        ),
                        DataColumn(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone_rounded,
                                size: 15,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 4),
                              const Text('Phone'),
                            ],
                          ),
                        ),
                        DataColumn(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_city_rounded,
                                size: 15,
                                color: Colors.orange.shade600,
                              ),
                              const SizedBox(width: 4),
                              const Text('City'),
                            ],
                          ),
                        ),
                        const DataColumn(label: Text('Status')),
                        const DataColumn(label: Text('')),
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
