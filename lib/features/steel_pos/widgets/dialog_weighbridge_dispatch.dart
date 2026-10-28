import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../util/snackbar_util.dart';
import '../../../screens/home/fragment/pos/controller_home_pos.dart';
import '../controllers/controller_steel_pos.dart';
import '../utils/steel_weight_calculator.dart';

class DialogWeighbridgeDispatch extends StatefulWidget {
  const DialogWeighbridgeDispatch({super.key});

  static Future<void> show(BuildContext context) {
    return Get.dialog(
      const DialogWeighbridgeDispatch(),
      barrierDismissible: true,
    );
  }

  @override
  State<DialogWeighbridgeDispatch> createState() => _DialogWeighbridgeDispatchState();
}

class _DialogWeighbridgeDispatchState extends State<DialogWeighbridgeDispatch> {
  final ControllerSteelPos steelCtrl = Get.isRegistered<ControllerSteelPos>()
      ? Get.find<ControllerSteelPos>()
      : Get.put(ControllerSteelPos(), permanent: true);

  late final TextEditingController _vehicleController;
  late final TextEditingController _siteController;
  late final TextEditingController _driverPhoneController;
  late final TextEditingController _ewayController;

  late final TextEditingController _grossController;
  late final TextEditingController _tareController;
  late final TextEditingController _craneController;
  late final TextEditingController _freightController;

  @override
  void initState() {
    super.initState();
    _vehicleController = TextEditingController(text: steelCtrl.rxVehicleNo.value);
    _siteController = TextEditingController(text: steelCtrl.rxDeliverySite.value);
    _driverPhoneController = TextEditingController(text: steelCtrl.rxDriverPhone.value);
    _ewayController = TextEditingController(text: steelCtrl.rxEwayBillNo.value);

    _grossController = TextEditingController(
      text: steelCtrl.rxWeighbridgeGrossKg.value > 0 ? steelCtrl.rxWeighbridgeGrossKg.value.toStringAsFixed(0) : '',
    );
    _tareController = TextEditingController(
      text: steelCtrl.rxWeighbridgeTareKg.value > 0 ? steelCtrl.rxWeighbridgeTareKg.value.toStringAsFixed(0) : '',
    );
    _craneController = TextEditingController(
      text: steelCtrl.rxCraneCharges.value > 0 ? steelCtrl.rxCraneCharges.value.toStringAsFixed(0) : '',
    );
    _freightController = TextEditingController(
      text: steelCtrl.rxFreightCharges.value > 0 ? steelCtrl.rxFreightCharges.value.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _siteController.dispose();
    _driverPhoneController.dispose();
    _ewayController.dispose();
    _grossController.dispose();
    _tareController.dispose();
    _craneController.dispose();
    _freightController.dispose();
    super.dispose();
  }

  void _saveData() {
    steelCtrl.rxVehicleNo.value = _vehicleController.text.trim();
    steelCtrl.rxDeliverySite.value = _siteController.text.trim();
    steelCtrl.rxDriverPhone.value = _driverPhoneController.text.trim();
    steelCtrl.rxEwayBillNo.value = _ewayController.text.trim();

    steelCtrl.rxWeighbridgeGrossKg.value = double.tryParse(_grossController.text.trim()) ?? 0.0;
    steelCtrl.rxWeighbridgeTareKg.value = double.tryParse(_tareController.text.trim()) ?? 0.0;
    steelCtrl.rxCraneCharges.value = double.tryParse(_craneController.text.trim()) ?? 0.0;
    steelCtrl.rxFreightCharges.value = double.tryParse(_freightController.text.trim()) ?? 0.0;

    // Also update ControllerHomePos if freight is entered as additional charge
    if (Get.isRegistered<ControllerHomePos>()) {
      final pos = Get.find<ControllerHomePos>();
      pos.calculateTotals();
    }

    SnackbarUtil.showSuccess('Vehicle & Logistics slip saved for current order.');
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartKg = steelCtrl.getCartTotalWeightKg();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF78350F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                    ),
                    child: const Icon(Icons.local_shipping_rounded, color: Color(0xFFFBBF24), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Truck Dispatch & Weighbridge Slip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Vehicle logistics, bridge tare/gross weights, and freight charges',
                          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Vehicle & Transport
                    const Text('1. TRANSPORTATION & VEHICLE DETAILS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B), letterSpacing: 0.6)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildField(
                            label: 'Truck / Vehicle No.',
                            controller: _vehicleController,
                            hint: 'e.g. MH-12-AB-1234',
                            icon: Icons.directions_bus_filled_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: _buildField(
                            label: 'Driver Phone / Contact',
                            controller: _driverPhoneController,
                            hint: '10-digit mobile number',
                            icon: Icons.phone_android_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: _buildField(
                            label: 'Delivery Site / Project Destination',
                            controller: _siteController,
                            hint: 'e.g. Site 4, Metro Pillar 124, Kothrud',
                            icon: Icons.place_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: _buildField(
                            label: 'E-Way Bill Number',
                            controller: _ewayController,
                            hint: '12-digit E-way bill',
                            icon: Icons.receipt_long_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Section 2: Weighbridge Slip
                    const Text('2. WEIGHBRIDGE WEIGHT SLIP (KG)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B), letterSpacing: 0.6)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            label: 'Gross Weight (Loaded Truck)',
                            controller: _grossController,
                            hint: 'e.g. 24500 kg',
                            suffix: 'Kg',
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            label: 'Tare Weight (Empty Truck)',
                            controller: _tareController,
                            hint: 'e.g. 12050 kg',
                            suffix: 'Kg',
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Weighbridge vs Cart Weight Comparison Card
                    Builder(builder: (context) {
                      final gross = double.tryParse(_grossController.text.trim()) ?? 0.0;
                      final tare = double.tryParse(_tareController.text.trim()) ?? 0.0;
                      final net = gross > tare ? (gross - tare) : 0.0;
                      final diff = net > 0 ? (net - cartKg) : 0.0;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: net > 0 ? const Color(0xFFF59E0B).withValues(alpha: 0.4) : cs.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('WEIGHBRIDGE NET', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  net > 0 ? SteelWeightCalculator.formatWeight(net) : 'No Bridge Slip',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFF59E0B)),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 32, color: cs.outlineVariant.withValues(alpha: 0.5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('THEORETICAL CART WT', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  SteelWeightCalculator.formatWeight(cartKg),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF38BDF8)),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 32, color: cs.outlineVariant.withValues(alpha: 0.5)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('DISCREPANCY (TOLERANCE)', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  net > 0 ? '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} Kg' : '-',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: diff.abs() <= 50 ? const Color(0xFF4ADE80) : const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 18),

                    // Section 3: Crane & Freight Charges
                    const Text('3. EXTRA SURCHARGES & FREIGHT',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B), letterSpacing: 0.6)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            label: 'Crane / Loading Charges (₹)',
                            controller: _craneController,
                            hint: 'e.g. 500',
                            prefix: '₹',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            label: 'Freight / Transportation (₹)',
                            controller: _freightController,
                            hint: 'e.g. 2500',
                            prefix: '₹',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
                border: Border(
                  top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _saveData,
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Attach Slip to Order', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    IconData? icon,
    String? prefix,
    String? suffix,
    ValueChanged<String>? onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 18, color: cs.primary) : null,
            prefixText: prefix != null ? '$prefix ' : null,
            suffixText: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}
