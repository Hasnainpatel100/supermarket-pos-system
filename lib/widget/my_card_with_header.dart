import 'package:flutter/material.dart';

import 'my_card.dart';
class MyCardWithHeader extends StatelessWidget {
  final String title;
  final Widget child;

  const MyCardWithHeader({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return MyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

