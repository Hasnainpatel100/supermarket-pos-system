import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final bool required;
  final bool obscure;
  final bool isNumber;
  final IconData? prefixIcon;
  final int maxLines;
  final String? hint;
  final Widget? suffixIcon;

  const MyTextField({
    super.key,
    required this.controller,
    required this.label,
    this.required = false,
    this.obscure = false,
    this.isNumber = false,
    this.prefixIcon,
    this.maxLines = 1,
    this.hint,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNumber
          ? <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '${label ?? "Field"} is required';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: cs.onSurfaceVariant) : null,
        suffixIcon: suffixIcon,
        label: RichText(
          text: TextSpan(
            text: label ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
            children: required
                ? [
                    TextSpan(
                      text: ' *',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ]
                : [],
          ),
        ),
      ),
    );
  }
}
