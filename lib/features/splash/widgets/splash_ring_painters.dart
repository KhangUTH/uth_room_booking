import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Vòng ngoài: nét đứt mảnh + cung đậm + các chấm tròn
class SplashOuterRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;

    // Vòng nét đứt
    final dashPaint = Paint()
      ..color = const Color(0xFFB7D8D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    _drawDashedCircle(
      canvas,
      center,
      r * 0.96,
      dashPaint,
      dashCount: 90,
      dashRatio: 0.55,
    );

    // Cung đậm
    final arcPaint = Paint()
      ..color = const Color(0xFFA9D0CB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.96),
      -math.pi * 0.15,
      math.pi * 0.55,
      false,
      arcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.96),
      math.pi * 0.85,
      math.pi * 0.45,
      false,
      arcPaint,
    );

    // Các chấm tròn trên vòng
    final dotPaint = Paint()..color = const Color(0xFF8EC3BC);
    _drawDot(canvas, center, r * 0.96, -math.pi * 0.15, 5, dotPaint);
    _drawDot(canvas, center, r * 0.96, math.pi * 0.4, 4, dotPaint);
    _drawDot(canvas, center, r * 0.96, math.pi * 1.3, 4.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Vòng trong: nhỏ hơn, xoay ngược chiều
class SplashInnerRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;

    final dashPaint = Paint()
      ..color = const Color(0xFFC8E0DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    _drawDashedCircle(
      canvas,
      center,
      r * 0.80,
      dashPaint,
      dashCount: 70,
      dashRatio: 0.5,
    );

    final arcPaint = Paint()
      ..color = const Color(0xFFB4D6D1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.80),
      math.pi * 1.1,
      math.pi * 0.5,
      false,
      arcPaint,
    );

    final dotPaint = Paint()..color = const Color(0xFF9CCBC5);
    _drawDot(canvas, center, r * 0.80, math.pi * 1.1, 3.5, dotPaint);
    _drawDot(canvas, center, r * 0.80, math.pi * 0.25, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _drawDashedCircle(
  Canvas canvas,
  Offset center,
  double radius,
  Paint paint, {
  required int dashCount,
  required double dashRatio,
}) {
  final step = 2 * math.pi / dashCount;
  final sweep = step * dashRatio;
  final rect = Rect.fromCircle(center: center, radius: radius);
  for (int i = 0; i < dashCount; i++) {
    canvas.drawArc(rect, i * step, sweep, false, paint);
  }
}

void _drawDot(
  Canvas canvas,
  Offset center,
  double radius,
  double angle,
  double dotRadius,
  Paint paint,
) {
  final pos = Offset(
    center.dx + radius * math.cos(angle),
    center.dy + radius * math.sin(angle),
  );
  canvas.drawCircle(pos, dotRadius, paint);
}
