import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Standard search field used in appBar.bottom across list fragments.
/// Clean, theme-aware design with subtle border and focus state.
///
/// Usage:
/// ```dart
/// appBar: AppBar(
///   bottom: PreferredSize(
///     preferredSize: const Size.fromHeight(64),
///     child: SearchAppBarField(
///       controller: controller.searchController,
///       hint: 'search_item'.tr,
///       onChanged: controller.updateSearch,
///       onClear: controller.clearSearch,
///     ),
///   ),
/// )
/// ```
class SearchAppBarField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final List<TextInputFormatter>? inputFormatters;
  final bool hasQuery;
  final Color? iconColor;

  const SearchAppBarField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.inputFormatters,
    this.hasQuery = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        inputFormatters: inputFormatters,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant, size: 22),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final show = value.text.isNotEmpty;
              return show
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant, size: 20),
                      onPressed: onClear,
                    )
                  : const SizedBox.shrink();
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.secondary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          filled: true,
          fillColor: cs.surfaceContainerLowest,
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}
