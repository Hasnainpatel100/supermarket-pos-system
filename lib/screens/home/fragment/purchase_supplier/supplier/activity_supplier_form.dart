import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../model/entity_supplier.dart';
import '../../../../../util/snackbar_util.dart';
import '../../../../../widget/my_card.dart';
import 'controller_home_supplier.dart';

/// Used for both CREATE and EDIT.
/// Pass EntitySupplier as Get.arguments for edit mode.
class ActivitySupplierForm extends StatefulWidget {
  const ActivitySupplierForm({super.key});

  @override
  State<ActivitySupplierForm> createState() => _ActivitySupplierFormState();
}

class _ActivitySupplierFormState extends State<ActivitySupplierForm> {
  late final ControllerHomeSupplier _controller;
  late final EntitySupplier _supplier;
  late final bool _isEdit;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ControllerHomeSupplier>()
        ? Get.find<ControllerHomeSupplier>()
        : Get.put(ControllerHomeSupplier());

    final arg = Get.arguments;
    if (arg is EntitySupplier) {
      _isEdit = true;
      _supplier = arg;
    } else {
      _isEdit = false;
      _supplier = EntitySupplier();
    }

    _nameCtrl.text = _supplier.name ?? '';
    _contactCtrl.text = _supplier.contactPerson ?? '';
    _phoneCtrl.text = _supplier.phone ?? '';
    _emailCtrl.text = _supplier.email ?? '';
    _addressCtrl.text = _supplier.address ?? '';
    _gstCtrl.text = _supplier.gstNumber ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    _supplier
      ..name = _nameCtrl.text.trim()
      ..contactPerson = _contactCtrl.text.trim()
      ..phone = _phoneCtrl.text.trim()
      ..email = _emailCtrl.text.trim()
      ..address = _addressCtrl.text.trim()
      ..gstNumber = _gstCtrl.text.trim();

    final error = _controller.saveSupplier(_supplier);
    if (error != null) {
      SnackbarUtil.showError(error);
      return;
    }

    SnackbarUtil.showSuccess(
        _isEdit ? 'Supplier updated!'.tr : 'Supplier created!'.tr);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
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
                    color: Colors.indigo.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isEdit
                    ? Icons.edit_rounded
                    : Icons.add_business_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _isEdit ? 'Edit Supplier'.tr : 'New Supplier'.tr,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: MyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Row(
                      children: [
                        Icon(Icons.local_shipping_rounded,
                            color: Colors.indigo.shade500),
                        const SizedBox(width: 8),
                        Text(
                          'Supplier Information'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEdit
                          ? 'Update supplier details below'.tr
                          : 'Fill in supplier details below'.tr,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const Divider(height: 28),

                    // ── Name (required) ──
                    _buildField(
                      controller: _nameCtrl,
                      label: 'Supplier Name *'.tr,
                      hint: 'e.g. Fresh Farms Pvt Ltd'.tr,
                      icon: Icons.business_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'.tr
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Contact Person ──
                    _buildField(
                      controller: _contactCtrl,
                      label: 'Contact Person'.tr,
                      hint: 'e.g. Ramesh Kumar'.tr,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),

                    // ── Phone ──
                    _buildField(
                      controller: _phoneCtrl,
                      label: 'Phone'.tr,
                      hint: 'e.g. 9876543210'.tr,
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // ── Email ──
                    _buildField(
                      controller: _emailCtrl,
                      label: 'Email'.tr,
                      hint: 'e.g. supplier@example.com'.tr,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // ── GST ──
                    _buildField(
                      controller: _gstCtrl,
                      label: 'GST Number'.tr,
                      hint: 'e.g. 27AAPFU0939F1ZV'.tr,
                      icon: Icons.receipt_long_rounded,
                    ),
                    const SizedBox(height: 16),

                    // ── Address ──
                    _buildField(
                      controller: _addressCtrl,
                      label: 'Address'.tr,
                      hint: 'Street, City, State'.tr,
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 28),

                    // ── Action Buttons ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                          ),
                          onPressed: () => Get.back(),
                          child: Text('Cancel'.tr),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo.shade400,
                                Colors.indigo.shade700
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _save,
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                child: Row(
                                  children: [
                                    const Icon(Icons.save_rounded,
                                        color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isEdit
                                          ? 'Update Supplier'.tr
                                          : 'Save Supplier'.tr,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
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
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
