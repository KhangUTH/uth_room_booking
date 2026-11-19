import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class BookingFeedback extends StatelessWidget {
  const BookingFeedback({
    super.key,
    required this.message,
    required this.failed,
  });

  final String message;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = failed ? colors.onErrorContainer : AppColors.primary;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: failed ? colors.errorContainer : AppColors.feedbackBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              failed ? Icons.info_outline : Icons.check_circle_outline,
              size: 19,
              color: foreground,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingHint extends StatelessWidget {
  const BookingHint({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _BookingHintBorder(),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 5,
        runSpacing: 4,
        children: [
          const Icon(
            Icons.touch_app_outlined,
            size: 15,
            color: AppColors.primary,
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.primary, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _BookingHintBorder extends CustomPainter {
  const _BookingHintBorder();

  @override
  void paint(Canvas canvas, Size size) {
    final border = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          const Radius.circular(14),
        ),
      );
    final stroke = Paint()
      ..color = const Color(0xFFACD6D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final edge in border.computeMetrics()) {
      for (var start = 0.0; start < edge.length; start += 6) {
        final end = (start + 3).clamp(0.0, edge.length).toDouble();
        canvas.drawPath(edge.extractPath(start, end), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BookingHintBorder oldDelegate) => false;
}
