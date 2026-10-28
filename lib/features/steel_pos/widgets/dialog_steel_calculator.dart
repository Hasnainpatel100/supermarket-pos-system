import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/controller_steel_pos.dart';
import '../models/steel_spec.dart';
import '../utils/steel_weight_calculator.dart';

class DialogSteelCalculator extends StatefulWidget {
  const DialogSteelCalculator({super.key});

  static Future<void> show(BuildContext context) {
    return Get.dialog(
      const DialogSteelCalculator(),
      barrierDismissible: true,
    );
  }

  @override
  State<DialogSteelCalculator> createState() => _DialogSteelCalculatorState();
}

class _DialogSteelCalculatorState extends State<DialogSteelCalculator> {
  final ControllerSteelPos steelCtrl = Get.isRegistered<ControllerSteelPos>()
      ? Get.find<ControllerSteelPos>()
      : Get.put(ControllerSteelPos(), permanent: true);

  late SteelSectionSpec _selectedSpec;
  String _selectedBrand = 'Tata Tiscon';

  final TextEditingController _pcsController = TextEditingController(text: '10');
  final TextEditingController _lengthController = TextEditingController(text: '12.0');
  final TextEditingController _rateMtController = TextEditingController(text: '56000');
  final TextEditingController _rateKgController = TextEditingController(text: '56.00');

  double _totalWeightKg = 0.0;
  double _totalAmount = 0.0;

  final List<String> _brands = [
    'Tata Tiscon',
    'JSW Neosteel',
    'SAIL',
    'Jindal Panther',
    'Kamdhenu',
    'Commercial Primary',
    'Secondary / Re-rolled',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSpec = SteelCatalogData.standardCatalog.first;
    _recalculate();
  }

  void _recalculate() {
    final pcs = int.tryParse(_pcsController.text.trim()) ?? 0;
    final length = double.tryParse(_lengthController.text.trim()) ?? _selectedSpec.standardLengthMtrs;
    final rateKg = double.tryParse(_rateKgController.text.trim()) ?? 0.0;

    setState(() {
      _totalWeightKg = _selectedSpec.calculateWeightKg(pieces: pcs, lengthMtrs: length);
      _totalAmount = _totalWeightKg * rateKg;
    });
  }

  void _onRateMtChanged(String val) {
    final rMt = double.tryParse(val) ?? 0.0;
    final rKg = SteelWeightCalculator.rateMtToRateKg(rMt);
    _rateKgController.text = rKg.toStringAsFixed(2);
    _recalculate();
  }

  void _onRateKgChanged(String val) {
    final rKg = double.tryParse(val) ?? 0.0;
    final rMt = SteelWeightCalculator.rateKgToRateMt(rKg);
    _rateMtController.text = rMt.toStringAsFixed(0);
    _recalculate();
  }

  @override
  void dispose() {
    _pcsController.dispose();
    _lengthController.dispose();
    _rateMtController.dispose();
    _rateKgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
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
            // ── Header Banner ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF3B82F6), width: 1.2),
                    ),
                    child: const Icon(Icons.architecture_rounded, color: Color(0xFF60A5FA), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Steel Sectional Weight & Price Calculator',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Indian Standard (IS 1786 / IS 2062) Structural Estimation',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
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

            // ── Form Body ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand & Section Selector
                    Row(
                      children: [
                        // Brand Dropdown
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Steel Mill / Brand',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onSurface)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedBrand,
                                    isExpanded: true,
                                    items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedBrand = v);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Section Spec Selector
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Standard Section & Size',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onSurface)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<SteelSectionSpec>(
                                    value: _selectedSpec,
                                    isExpanded: true,
                                    items: SteelCatalogData.standardCatalog.map((spec) {
                                      return DropdownMenuItem(
                                        value: spec,
                                        child: Text(
                                          '${spec.name} (${spec.unitWeightKgPerMtr} kg/m)',
                                          style: const TextStyle(fontSize: 12.5),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (spec) {
                                      if (spec != null) {
                                        setState(() {
                                          _selectedSpec = spec;
                                          _lengthController.text = spec.standardLengthMtrs.toStringAsFixed(1);
                                        });
                                        _recalculate();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Inputs: Pieces, Length, Rate MT, Rate KG
                    Row(
                      children: [
                        // Quantity in Pieces / Bars
                        Expanded(
                          child: _buildInput(
                            label: 'Quantity (Pieces / Bars)',
                            controller: _pcsController,
                            suffix: 'pcs',
                            onChanged: (_) => _recalculate(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Length in Meters
                        Expanded(
                          child: _buildInput(
                            label: 'Bar Length (Mtrs)',
                            controller: _lengthController,
                            suffix: 'm',
                            onChanged: (_) => _recalculate(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Rate per MT
                        Expanded(
                          child: _buildInput(
                            label: 'Rate / Metric Ton',
                            controller: _rateMtController,
                            prefix: '₹',
                            onChanged: _onRateMtChanged,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Rate per Kg
                        Expanded(
                          child: _buildInput(
                            label: 'Rate / Kg',
                            controller: _rateKgController,
                            prefix: '₹',
                            onChanged: _onRateKgChanged,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Live Calculation Card ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1E293B),
                            const Color(0xFF0F172A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ESTIMATED WEIGHT',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  SteelWeightCalculator.formatWeight(_totalWeightKg),
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Unit: ${_selectedSpec.unitWeightKgPerMtr} kg/m • Grade: ${_selectedSpec.grade}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 48,
                            width: 1,
                            color: Colors.white12,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'TOTAL ESTIMATED VALUE',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${_totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFF4ADE80),
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  '+ 18% GST Applicable',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer Action Bar ──
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
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      final pcs = int.tryParse(_pcsController.text.trim()) ?? 0;
                      final length = double.tryParse(_lengthController.text.trim()) ?? _selectedSpec.standardLengthMtrs;
                      final rateKg = double.tryParse(_rateKgController.text.trim()) ?? 0.0;

                      if (pcs <= 0 || _totalWeightKg <= 0) {
                        return;
                      }

                      steelCtrl.addCalculatedSteelToCart(
                        spec: _selectedSpec,
                        pieces: pcs,
                        lengthMtrs: length,
                        totalWeightKg: _totalWeightKg,
                        ratePerKg: rateKg,
                        brandName: _selectedBrand,
                      );
                      Get.back();
                    },
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: const Text('Add Steel to Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
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

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    String? prefix,
    String? suffix,
    required ValueChanged<String> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
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

