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

  const MyTextField({
    super.key,
    required this.controller,
    required this.label,
    this.required = false,
    this.obscure = false,
    this.isNumber = false,
    this.prefixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,

      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,

      inputFormatters: isNumber
          ? <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,

      // ✅ Validator without layout jump
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return ''; // <-- VERY IMPORTANT
        }
        return null;
      },

      decoration: InputDecoration(
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        
        // ⭐ Label with required *
        label: RichText(
          text: TextSpan(
            text: label ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
            children: required
                ? [
                    TextSpan(
                      text: ' *',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                : [],
          ),
        ),

        // 🔒 Reserve error space permanently
        errorStyle: const TextStyle(
          height: 0, // no text height
          fontSize: 0, // invisible
        ),
      ),
    );
  }
}
