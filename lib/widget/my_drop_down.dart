import 'package:flutter/material.dart';

class MyDropDown<T> extends StatelessWidget {
  final String label;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final IconData? prefixIcon;
  final bool required;
  final String? hint;

  const MyDropDown({
    super.key,
    required this.label,
    required this.items,
    this.value,
    required this.onChanged,
    this.prefixIcon,
    this.required = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      validator: (val) {
        if (required && val == null) {
          return '${label} is required';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: cs.onSurfaceVariant) : null,
        label: RichText(
          text: TextSpan(
            text: label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
            children: required
                ? [
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ]
                : [],
          ),
        ),
      ),
    );
  }
}
