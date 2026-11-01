import 'package:flutter/material.dart';

import 'my_card.dart';

class MyCardWithHeader extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? leadingIcon;
  final Color? leadingColor;
  final List<Widget>? actions;

  const MyCardWithHeader({
    super.key,
    required this.title,
    required this.child,
    this.leadingIcon,
    this.leadingColor,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MyCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (leadingIcon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (leadingColor ?? cs.secondary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(leadingIcon, color: leadingColor ?? cs.secondary, size: 20),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: child),
        ],
      ),
    );
  }
}

