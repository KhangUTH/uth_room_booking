import 'package:flutter/material.dart';

const _line = Color(0xFFD6E6E7);

class BookingPanel extends StatelessWidget {
  const BookingPanel({super.key, required this.child, required this.padding});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _line),
    ),
    child: child,
  );
}
