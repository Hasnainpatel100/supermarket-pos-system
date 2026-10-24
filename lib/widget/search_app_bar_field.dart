import 'package:flutter/material.dart';

/// Standard search field used in appBar.bottom across list fragments.
///
/// Replaces the copy-pasted PreferredSize + Container + TextField pattern
/// found in customer, item, supplier, and purchase fragments.
///
/// Usage:
/// ```dart
/// appBar: AppBar(
///   bottom: PreferredSize(
///     preferredSize: const Size.fromHeight(60),
///     child: SearchAppBarField(
///       controller: controller.searchController,
///       hint: 'search_item'.tr,
///       onChanged: controller.updateSearch,
///       onClear: controller.clearSearch,
///       hasQuery: controller.searchQuery.isNotEmpty,
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
  final bool hasQuery;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? closeIconColor;

  const SearchAppBarField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.hasQuery = false,
    this.backgroundColor,
    this.iconColor,
    this.closeIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded,
              color: iconColor ?? Colors.blue.shade600, size: 22),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final show = hasQuery || value.text.isNotEmpty;
              return show
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: closeIconColor ?? Colors.red.shade400, size: 20),
                      onPressed: onClear,
                    )
                  : const SizedBox.shrink();
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          filled: true,
          fillColor: backgroundColor ?? Theme.of(context).cardColor,
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}
