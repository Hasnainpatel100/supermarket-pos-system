import 'package:flutter/material.dart';

class MyDatePicker extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const MyDatePicker({
    super.key,
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () => _selectDate(context),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _getInitialDate(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      // Safely update the text
      controller.text = picked.toIso8601String().split('T').first;
    }
  }

  DateTime _getInitialDate() {
    if (controller.text.isNotEmpty) {
      try {
        return DateTime.parse(controller.text);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
