import 'package:flutter/material.dart';

import '../../../theme/app_text_sizes.dart';

class TechnicianPageTitle extends StatelessWidget {
  const TechnicianPageTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 48),
    alignment: AlignmentDirectional.centerStart,
    child: Text(
      title,
      style: const TextStyle(
        fontSize: AppTextSizes.section,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
