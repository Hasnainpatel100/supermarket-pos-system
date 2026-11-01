import 'package:flutter/material.dart';

class MyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const MyCard({
    super.key,
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: margin,
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: cs.outline.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: padding == EdgeInsets.zero
          ? child
          : Padding(padding: padding!, child: child),
    );
  }
}
