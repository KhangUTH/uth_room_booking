import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/app_colors.dart';

class BookingUsageNotice extends StatelessWidget {
  const BookingUsageNotice({super.key});

  static Future<void> showOnce(
    BuildContext context, {
    required String role,
    required String account,
    required bool Function() isActive,
  }) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final key = 'booking_usage_notice_v1.$role.$account';
      if (!context.mounted ||
          !isActive() ||
          preferences.getBool(key) == true ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      final acknowledged = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const BookingUsageNotice(),
      );
      if (acknowledged == true) await preferences.setBool(key, true);
    } on MissingPluginException {
      // Local storage is unavailable on this platform.
    } on PlatformException {
      // Keep scheduling available if preference storage fails.
    }
  }

  static const _rules = [
    'Trước khi rời phòng, tắt quạt, đèn và nguồn điện của các thiết bị đã sử dụng.',
    'Sử dụng đúng phòng, thiết bị và khung giờ đã đăng ký.',
    'Giữ vệ sinh và sắp xếp lại thiết bị sau khi sử dụng.',
    'Nếu phát hiện hư hỏng, gửi báo cáo sự cố trong app để kỹ thuật viên hỗ trợ.',
  ];

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    scrollable: true,
    title: Column(
      children: [
        Image.asset('assets/images/logo/logo.jpg', height: 36),
        const SizedBox(height: 14),
        Text(
          'Lưu ý khi sử dụng phòng và thiết bị',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final rule in _rules)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(rule)),
              ],
            ),
          ),
      ],
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Đã hiểu'),
      ),
    ],
  );
}

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
