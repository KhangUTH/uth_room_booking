import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class UthAiAvatar extends StatelessWidget {
  const UthAiAvatar({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: Image.asset(
      'assets/images/ai_chat/uth_ai_avatar.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
    ),
  );
}

class ChatLauncher extends StatelessWidget {
  const ChatLauncher({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? .7 : 1, end: 1),
      duration: animate ? const Duration(milliseconds: 650) : Duration.zero,
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: FloatingActionButton(
        tooltip: 'Mở UTH AI',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: const CircleBorder(),
        onPressed: onPressed,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: animate
              ? const Duration(milliseconds: 1800)
              : Duration.zero,
          builder: (context, phase, child) => CustomPaint(
            foregroundPainter: _ChatBlinkPainter(
              AlwaysStoppedAnimation(phase),
              launcher: true,
            ),
            child: child,
          ),
          child: const UthAiAvatar(size: 56),
        ),
      ),
    );
  }
}

class ChatHero extends StatefulWidget {
  const ChatHero({super.key});

  @override
  State<ChatHero> createState() => _ChatHeroState();
}

class _ChatHeroState extends State<ChatHero>
    with SingleTickerProviderStateMixin {
  late final _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ripple.reset();
    } else if (!_ripple.isAnimating) {
      _ripple.repeat();
    }
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 136,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _ChatRipplePainter(_ripple)),
          ),
        ),
        Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(13),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.feedbackBackground,
          ),
          child: RepaintBoundary(
            child: CustomPaint(
              foregroundPainter: _ChatBlinkPainter(_ripple),
              child: Image.asset(
                'assets/images/ai_chat/uth_ai_glyph.png',
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ChatRipplePainter extends CustomPainter {
  _ChatRipplePainter(this.phase) : super(repaint: phase);

  final Animation<double> phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var ring = 0; ring < 3; ring++) {
      final progress = (phase.value + (ring + .5) / 3) % 1;
      final radius = 40 + (size.shortestSide / 2 - 40) * progress;
      paint.color = AppColors.chatPrimary.withValues(
        alpha: .48 * (1 - progress),
      );
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ChatRipplePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _ChatBlinkPainter extends CustomPainter {
  _ChatBlinkPainter(this.phase, {this.launcher = false})
    : super(repaint: phase);

  final Animation<double> phase;
  final bool launcher;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = (phase.value - .83) / .085;
    if (progress <= 0 || progress >= 1) return;
    final blink = Curves.easeInOut.transform(1 - (2 * progress - 1).abs());
    final face = Paint()..color = const Color(0xFF04504F);
    final eye = Paint()..color = const Color(0xFF7FE8D2);

    // Align with the eye bounds in the original launcher and hero assets.
    final assetSize = launcher ? 192 : 512;
    final eyeBounds = launcher
        ? const [Rect.fromLTWH(68, 93, 16, 25), Rect.fromLTWH(108, 93, 16, 25)]
        : const [
            Rect.fromLTWH(165.5, 253, 48, 80),
            Rect.fromLTWH(298, 253, 48, 80),
          ];
    canvas.save();
    canvas.scale(size.width / assetSize, size.height / assetSize);
    for (final bounds in eyeBounds) {
      canvas.drawRect(bounds, face);
      final width = bounds.width * .92;
      final height = bounds.height * (.95 - .85 * blink);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: bounds.center, width: width, height: height),
          Radius.circular(height < width ? height / 2 : width / 2),
        ),
        eye,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChatBlinkPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.launcher != launcher;
}
