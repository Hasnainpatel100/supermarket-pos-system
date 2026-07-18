import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Unified wrapper for all desktop forms in dialog mode.
/// Standardizes dialog size, responsiveness, padding, and handles the ESC key.
class AppDialog extends StatelessWidget {
  final Widget header;
  final Widget body;
  final Widget? footer;
  final double maxWidth;
  final double maxHeight;
  final bool Function()? hasUnsavedChanges;

  const AppDialog({
    super.key,
    required this.header,
    required this.body,
    this.footer,
    this.maxWidth = 950,
    this.maxHeight = 720,
    this.hasUnsavedChanges,
  });

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: true,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            final hasChanges = hasUnsavedChanges?.call() ?? false;
            if (!hasChanges) {
              Get.back();
            }
          }
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: SizedBox(
              width: maxWidth,
              height: maxHeight,
              child: Card(
                elevation: 12,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    Expanded(
                      child: body,
                    ),
                    if (footer != null) footer!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Standardized fixed header for desktop dialogs.
class DialogHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onClose;
  final List<Widget>? actions;

  const DialogHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.onClose,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? colorScheme.primary).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor ?? colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            splashRadius: 20,
            onPressed: onClose ?? () => Get.back(),
          ),
        ],
      ),
    );
  }
}

/// Scrollable container for the form inputs.
class DialogBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DialogBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: child,
    );
  }
}

/// Fixed footer holding standard buttons that do not scroll.
class DialogFooter extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveLabel;
  final bool isSaving;
  final Widget? extraWidget;
  final Color? saveButtonColor;

  const DialogFooter({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.saveLabel = 'Save',
    this.isSaving = false,
    this.extraWidget,
    this.saveButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.12),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (extraWidget != null) ...[
            extraWidget!,
            const Spacer(),
          ],
          SecondaryButton(
            label: 'Cancel',
            onPressed: onCancel,
            icon: Icons.close_rounded,
          ),
          const SizedBox(width: 12),
          PrimaryButton(
            label: saveLabel,
            onPressed: onSave,
            isLoading: isSaving,
            icon: Icons.save_rounded,
            backgroundColor: saveButtonColor,
          ),
        ],
      ),
    );
  }
}

/// Visual Section Header with unified theme.
class FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;

  const FormSection({
    super.key,
    required this.title,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeColor = color ?? colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 18, color: themeColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: themeColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(height: 1, color: themeColor.withOpacity(0.15)),
        ),
      ],
    );
  }
}

/// Custom AppTextField with inline error styling to prevent layout shifts.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final bool obscure;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.obscure = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      onTap: onTap,
      validator: (value) {
        if (validator != null) {
          final customErr = validator!(value);
          if (customErr != null) return customErr;
        }

        final trimmed = value?.trim() ?? '';

        if (required && trimmed.isEmpty) {
          final cleanLabel = label.replaceAll(' *', '').trim();
          return "$cleanLabel is required";
        }

        if (trimmed.isNotEmpty) {
          final cleanLabel = label.toLowerCase();
          
          // 1. Phone number validation (exactly 10 digits)
          if (cleanLabel.contains('phone') || cleanLabel.contains('mobile')) {
            final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
            if (digitsOnly.length != 10 || trimmed.length != 10) {
              return "Phone number must be exactly 10 digits";
            }
            if (digitsOnly != trimmed) {
              return "Phone number must contain only digits";
            }
          }
          
          // 2. Email validation (valid email format, and gmail ends with @gmail.com)
          if (cleanLabel.contains('email') || cleanLabel.contains('mail')) {
            final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
            if (!emailRegex.hasMatch(trimmed)) {
              return "Please enter a valid email address";
            }
            if (trimmed.toLowerCase().contains('gmail') && !trimmed.toLowerCase().endsWith('@gmail.com')) {
              return "Gmail address must end with @gmail.com";
            }
          }

          // 3. Cost/Price/Amount validation (must not exceed 99,999,999 or 8 digits before decimal)
          final isNumeric = keyboardType == TextInputType.number || 
                            keyboardType.toString().contains('number') || 
                            inputFormatters?.isNotEmpty == true ||
                            cleanLabel.contains('cost') ||
                            cleanLabel.contains('price') ||
                            cleanLabel.contains('amount') ||
                            cleanLabel.contains('mrp') ||
                            cleanLabel.contains('rate') ||
                            cleanLabel.contains('tax') ||
                            cleanLabel.contains('discount');

          if (isNumeric) {
            final numVal = double.tryParse(trimmed);
            if (numVal != null) {
              if (numVal > 99999999.99) {
                return "Amount cannot exceed 99,999,999";
              }
              final parts = trimmed.split('.');
              if (parts[0].replaceAll(RegExp(r'\D'), '').length > 8) {
                return "Amount too large (max 8 digits)";
              }
            } else if (keyboardType.toString().contains('number')) {
              return "Please enter a valid number";
            }
          }
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

/// Input field specifically designed for numeric values.
class AppNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;

  const AppNumberField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hint: hint,
      required: required,
      prefixIcon: prefixIcon,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      validator: validator,
    );
  }
}

/// Standardized responsive Dropdown input.
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? prefixIcon;
  final bool required;

  const AppDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.prefixIcon,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: (val) {
        if (required && val == null) {
          return '';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorStyle: const TextStyle(height: 0, fontSize: 0),
      ),
    );
  }
}

/// Standardized Responsive Date Picker input.
class AppDatePicker extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final VoidCallback onTap;

  const AppDatePicker({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      prefixIcon: prefixIcon ?? Icons.calendar_today_rounded,
      readOnly: true,
      onTap: onTap,
    );
  }
}

/// Professional Material 3 primary action button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        minimumSize: const Size(120, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

/// Professional Material 3 secondary action button.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(120, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.24),
        ),
      ),
    );
  }
}
