import 'dart:async';
import 'dart:math' as math;

import 'package:uth_room_booking/core/router/app_route.dart';
import 'package:flutter/material.dart';

import '../widgets/splash_ring_painters.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.restoreSession});

  final Future<HomeRouteArgs?> Function()? restoreSession;

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
    final pendingProfile = widget.restoreSession?.call();
    _timer = Timer(const Duration(seconds: 3), () async {
      final profile = await pendingProfile;
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed<void, void>(
        profile == null ? AppRoute.login : AppRoute.home,
        arguments: profile,
      );
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
                      painter: SplashOuterRingPainter(),
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
                      painter: SplashInnerRingPainter(),
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
                        'assets/images/logo/logo.jpg',
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
