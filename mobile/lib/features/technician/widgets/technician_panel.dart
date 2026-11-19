import 'package:flutter/material.dart';
import 'package:uth_room_booking/theme/app_colors.dart';

const _line = Color(0xFFDCE8E9);

class TechnicianPanel extends StatelessWidget {
  const TechnicianPanel({
    super.key,
    required this.child,
    this.featured = false,
  });

  final Widget child;
  final bool featured;

  @override
  Widget build(BuildContext context) => Material(
    color: featured ? AppColors.primary : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: featured ? AppColors.primary : _line),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}
