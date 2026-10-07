import 'package:flutter/material.dart';

class MyRowExpandedTwo extends StatelessWidget {
  final Widget left;
  final Widget right;

  const MyRowExpandedTwo({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 20),
        Expanded(child: right),
      ],
    );
  }
}
