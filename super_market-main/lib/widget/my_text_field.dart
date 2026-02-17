import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final bool required;
  final bool obscure;
  final bool isNumber;

  const MyTextField({
    super.key,
    required this.controller,
    required this.label,
    this.required = false,
    this.obscure = false,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,

      keyboardType:
      isNumber ? TextInputType.number : TextInputType.text,

      inputFormatters: isNumber
          ? <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ]
          : null,

      // ✅ Validator without layout jump
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return ''; // <-- VERY IMPORTANT
        }
        return null;
      },

      decoration: InputDecoration(
        border: const OutlineInputBorder(),

        // ⭐ Label with required *
        label: RichText(
          text: TextSpan(
            text: label ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
            children: required
                ? [
              TextSpan(
                text: ' *',
                style: TextStyle(
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
          height: 0,     // no text height
          fontSize: 0,   // invisible
        ),
      ),
    );
  }
}