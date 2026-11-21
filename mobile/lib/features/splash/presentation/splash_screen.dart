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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Stack(
      fit: StackFit.expand,
      children: [
        const Align(
          alignment: Alignment.topCenter,
          child: Image(
            image: AssetImage('assets/images/splash/splash_top.jpg'),
            width: 720,
            fit: BoxFit.contain,
          ),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: Image(
            image: AssetImage('assets/images/splash/splash_bottom.jpg'),
            width: 720,
            fit: BoxFit.contain,
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (_, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              if (width >= 600 && width > height) {
                final ringSize = math.min(
                  340.0,
                  math.min(width * .38, height * .68),
                );
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _logoRings(ringSize),
                        SizedBox(width: math.min(width * .06, 48.0)),
                        Flexible(
                          child: Image.asset(
                            'assets/images/splash/splash_school.jpg',
                            width: 400,
                            height: height * .62,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final ringSize = math.min(
                360.0,
                math.min(width * .82, height * .46),
              );
              return Column(
                children: [
                  SizedBox(height: height * .10),
                  _logoRings(ringSize),
                  SizedBox(height: height * .03),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: height * .08),
                      child: Image.asset(
                        'assets/images/splash/splash_school.jpg',
                        width: math.min(460.0, width * .90),
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _logoRings(double ringSize) => SizedBox(
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
  );
}
