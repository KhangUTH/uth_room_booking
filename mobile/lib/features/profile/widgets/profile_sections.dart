import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

const _pale = Color(0xFFDCEFEF);
const _line = Color(0xFFD6E6E7);
const profileMutedColor = Color(0xFF526E74);

class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
      side: const BorderSide(color: _line),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0) const Divider(height: 1, thickness: 1, color: _line),
          rows[index],
        ],
      ],
    ),
  );
}

class ProfileRow extends StatelessWidget {
  const ProfileRow({
    super.key,
    required this.icon,
    required this.title,
    this.caption,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? caption;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _pale,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (caption case final label?)
                    Text(
                      label,
                      style: const TextStyle(
                        color: profileMutedColor,
                        fontSize: 11,
                      ),
                    ),
                  Text(title, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            if (trailing case final widget?) ...[
              const SizedBox(width: 8),
              widget,
            ],
          ],
        ),
      ),
    ),
  );
}
