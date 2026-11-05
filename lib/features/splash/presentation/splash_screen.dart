import 'dart:async';
import 'dart:math' as math;

import 'package:uth_room_booking/features/auth/login_page.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Vòng tròn xoay liên tục, 1 vòng = 10 giây
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Sau 3 giây chuyển sang màn hình tiếp theo
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      // TODO: đổi sang route của bạn
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ringSize = size.width * 0.82;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Nền PNG
          const ColoredBox(color: Colors.white),
          Align(
            alignment: Alignment.topCenter,
            child: Image.asset(
              'assets/images/splash/splash_top.jpg',
              fit: BoxFit.fitWidth,
              width: size.width,
            ),
          ),

          // 2. Logo tròn + vòng xoay
          Positioned(
            top: size.height * 0.12,
            left: (size.width - ringSize) / 2,
            child: SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Vòng ngoài xoay thuận chiều kim đồng hồ
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, child) => Transform.rotate(
                      angle: _controller.value * 2 * math.pi,
                      child: child,
                    ),
                    child: CustomPaint(
                      size: Size(ringSize, ringSize),
                      painter: _OuterRingPainter(),
                    ),
                  ),

                  // Vòng trong xoay ngược chiều
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, child) => Transform.rotate(
                      angle: -_controller.value * 2 * math.pi,
                      child: child,
                    ),
                    child: CustomPaint(
                      size: Size(ringSize, ringSize),
                      painter: _InnerRingPainter(),
                    ),
                  ),

                  // Hình tròn nền mờ (đứng yên)
                  Container(
                    width: ringSize * 0.74,
                    height: ringSize * 0.74,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEEF5F4),
                    ),
                  ),

                  // Hình tròn chứa logo (đứng yên)
                  Container(
                    width: ringSize * 0.58,
                    height: ringSize * 0.58,
                    padding: EdgeInsets.all(ringSize * 0.04),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFD3E8E6),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/splash/logo.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: size.height * 0.06),
              child: Image.asset(
                'assets/images/splash/splash_school.jpg',
                height: size.height * 0.55,
                width: size.width * 0.9,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),

          // Hình trường học PNG ở dưới
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/images/splash/splash_bottom.jpg',
              width: size.width,
              fit: BoxFit.fitWidth,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vòng ngoài: nét đứt mảnh + cung đậm + các chấm tròn
class _OuterRingPainter extends CustomPainter {
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
class _InnerRingPainter extends CustomPainter {
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
