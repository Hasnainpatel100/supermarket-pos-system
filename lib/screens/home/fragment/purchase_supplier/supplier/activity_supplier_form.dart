import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../model/entity_supplier.dart';
import '../../../../../util/snackbar_util.dart';
import '../../../../../widget/app_dialog_components.dart';
import 'controller_home_supplier.dart';

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
        _isEdit ? 'Supplier updated!' : 'Supplier created!');
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      maxWidth: 750,
      maxHeight: 680,
      header: DialogHeader(
        title: _isEdit ? 'Edit Supplier' : 'New Supplier',
        icon: _isEdit ? Icons.edit_rounded : Icons.add_business_rounded,
        iconColor: Colors.indigo.shade700,
      ),
      body: DialogBody(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 550;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FormSection(
                    icon: Icons.local_shipping_rounded,
                    color: Colors.indigo,
                    title: 'Supplier Information',
                  ),
                  const SizedBox(height: 16),

                  if (isWide) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _nameCtrl,
                            label: 'Supplier Name *',
                            hint: 'e.g. Fresh Farms Pvt Ltd',
                            prefixIcon: Icons.business_rounded,
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: _contactCtrl,
                            label: 'Contact Person',
                            hint: 'e.g. Ramesh Kumar',
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppNumberField(
                            controller: _phoneCtrl,
                            label: 'Phone',
                            hint: 'e.g. 9876543210',
                            prefixIcon: Icons.phone_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: _emailCtrl,
                            label: 'Email',
                            hint: 'e.g. supplier@example.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    AppTextField(
                      controller: _nameCtrl,
                      label: 'Supplier Name *',
                      hint: 'e.g. Fresh Farms Pvt Ltd',
                      prefixIcon: Icons.business_rounded,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _contactCtrl,
                      label: 'Contact Person',
                      hint: 'e.g. Ramesh Kumar',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    AppNumberField(
                      controller: _phoneCtrl,
                      label: 'Phone',
                      hint: 'e.g. 9876543210',
                      prefixIcon: Icons.phone_rounded,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      hint: 'e.g. supplier@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],

                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _gstCtrl,
                    label: 'GST Number',
                    hint: 'e.g. 27AAPFU0939F1ZV',
                    prefixIcon: Icons.receipt_long_rounded,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _addressCtrl,
                    label: 'Address',
                    hint: 'Street, City, State',
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 3,
                  ),
                ],
              );
            },
          ),
        ),
      ),
      footer: DialogFooter(
        onCancel: () => Get.back(),
        onSave: _save,
        saveLabel: _isEdit ? 'Update Supplier' : 'Save Supplier',
        saveButtonColor: Colors.indigo.shade700,
      ),
    );
  }
}
