import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft mint auth background shared by splash + login.
class AuthBackground extends StatelessWidget {
  const AuthBackground({
    super.key,
    required this.child,
    this.showArch = false,
    this.showCornerPatterns = false,
    this.showMosqueScene = false,
    this.showBottomSkyline = false,
    this.showCenterGlow = false,
  });

  final Widget child;
  final bool showArch;
  final bool showCornerPatterns;
  final bool showMosqueScene;
  final bool showBottomSkyline;
  final bool showCenterGlow;

  static const mint = Color(0xFFF4F9F5);
  static const pattern = Color(0xFFB7D4C3);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: mint,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showCenterGlow)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.55),
                  radius: 0.85,
                  colors: [
                    Color(0x332A9B68),
                    Color(0x00F4F9F5),
                  ],
                ),
              ),
            ),
          if (showCornerPatterns) ...[
            Positioned(
              top: -20,
              left: -30,
              child: CustomPaint(
                size: const Size(180, 180),
                painter: IslamicStarPainter(color: pattern.withValues(alpha: 0.28)),
              ),
            ),
            Positioned(
              top: -20,
              right: -30,
              child: CustomPaint(
                size: const Size(180, 180),
                painter: IslamicStarPainter(color: pattern.withValues(alpha: 0.28)),
              ),
            ),
          ],
          if (showArch)
            Positioned.fill(
              child: CustomPaint(
                painter: ArchFramePainter(color: pattern.withValues(alpha: 0.35)),
              ),
            ),
          if (showMosqueScene)
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.sizeOf(context).height * 0.28,
              height: MediaQuery.sizeOf(context).height * 0.34,
              child: CustomPaint(
                painter: MosqueScenePainter(color: AppColors.primary.withValues(alpha: 0.12)),
              ),
            ),
          if (showBottomSkyline)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 140,
              child: CustomPaint(
                painter: MosqueSkylinePainter(color: pattern.withValues(alpha: 0.55)),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.height = 160, this.radius = 20});

  static const assetPath = 'assets/images/logo_iias.png';

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          assetPath,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class DomeLogoPainter extends CustomPainter {
  DomeLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Outer arch
    final arch = Path()
      ..moveTo(w * 0.18, h * 0.92)
      ..lineTo(w * 0.18, h * 0.48)
      ..quadraticBezierTo(w * 0.18, h * 0.12, w * 0.5, h * 0.12)
      ..quadraticBezierTo(w * 0.82, h * 0.12, w * 0.82, h * 0.48)
      ..lineTo(w * 0.82, h * 0.92);
    canvas.drawPath(arch, paint);

    // Inner crescent-ish arc
    final crescent = Path()
      ..moveTo(w * 0.38, h * 0.62)
      ..quadraticBezierTo(w * 0.5, h * 0.34, w * 0.62, h * 0.62);
    canvas.drawPath(crescent, paint);

    // Base line
    canvas.drawLine(
      Offset(w * 0.22, h * 0.92),
      Offset(w * 0.78, h * 0.92),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant DomeLogoPainter oldDelegate) => oldDelegate.color != color;
}

class IslamicStarPainter extends CustomPainter {
  IslamicStarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    for (var ring = 0; ring < 3; ring++) {
      final r = radius * (1 - ring * 0.22);
      final path = Path();
      for (var i = 0; i < 8; i++) {
        final angle = (i * math.pi / 4) - math.pi / 2;
        final outer = Offset(
          center.dx + math.cos(angle) * r,
          center.dy + math.sin(angle) * r,
        );
        final midAngle = angle + math.pi / 8;
        final inner = Offset(
          center.dx + math.cos(midAngle) * r * 0.55,
          center.dy + math.sin(midAngle) * r * 0.55,
        );
        if (i == 0) {
          path.moveTo(outer.dx, outer.dy);
        } else {
          path.lineTo(outer.dx, outer.dy);
        }
        path.lineTo(inner.dx, inner.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
      canvas.drawCircle(center, r * 0.28, paint);
    }
  }

  @override
  bool shouldRepaint(covariant IslamicStarPainter oldDelegate) => oldDelegate.color != color;
}

class ArchFramePainter extends CustomPainter {
  ArchFramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final inset = size.width * 0.06;
    final path = Path()
      ..moveTo(inset, size.height * 0.92)
      ..lineTo(inset, size.height * 0.28)
      ..quadraticBezierTo(inset, size.height * 0.06, size.width / 2, size.height * 0.06)
      ..quadraticBezierTo(size.width - inset, size.height * 0.06, size.width - inset, size.height * 0.28)
      ..lineTo(size.width - inset, size.height * 0.92);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ArchFramePainter oldDelegate) => oldDelegate.color != color;
}

class MosqueScenePainter extends CustomPainter {
  MosqueScenePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final ground = h * 0.88;

    // Palm left
    _palm(canvas, Offset(w * 0.12, ground), h * 0.55, paint);
    // Palm right
    _palm(canvas, Offset(w * 0.88, ground), h * 0.55, paint);

    // Side domes
    _domeBuilding(canvas, Offset(w * 0.28, ground), w * 0.16, h * 0.28, paint);
    _domeBuilding(canvas, Offset(w * 0.72, ground), w * 0.16, h * 0.28, paint);

    // Main mosque
    _domeBuilding(canvas, Offset(w * 0.5, ground), w * 0.34, h * 0.42, paint, tall: true);

    // Minarets
    _minaret(canvas, Offset(w * 0.38, ground), h * 0.55, paint);
    _minaret(canvas, Offset(w * 0.62, ground), h * 0.55, paint);

    // Crescent
    final crescentPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.12), width: 28, height: 28),
      -0.4,
      math.pi * 1.4,
      false,
      crescentPaint,
    );
  }

  void _palm(Canvas canvas, Offset base, double height, Paint paint) {
    final trunk = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx + 6, base.dy - height * 0.5, base.dx, base.dy - height);
    canvas.drawPath(
      trunk,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < 5; i++) {
      final angle = -1.2 + i * 0.6;
      final tip = Offset(
        base.dx + math.cos(angle) * height * 0.28,
        base.dy - height + math.sin(angle) * height * 0.18,
      );
      canvas.drawLine(
        Offset(base.dx, base.dy - height),
        tip,
        Paint()
          ..color = paint.color
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _domeBuilding(
    Canvas canvas,
    Offset base,
    double width,
    double height,
    Paint paint, {
    bool tall = false,
  }) {
    final left = base.dx - width / 2;
    final top = base.dy - height;
    final bodyTop = top + height * 0.35;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left + width * 0.08, bodyTop, left + width * 0.92, base.dy),
        const Radius.circular(4),
      ),
      paint,
    );
    final dome = Path()
      ..moveTo(left + width * 0.12, bodyTop)
      ..quadraticBezierTo(base.dx, top - (tall ? 8 : 0), left + width * 0.88, bodyTop)
      ..close();
    canvas.drawPath(dome, paint);

    // Door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(base.dx, base.dy - height * 0.12),
          width: width * 0.18,
          height: height * 0.22,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = paint.color.withValues(alpha: 0.35),
    );
  }

  void _minaret(Canvas canvas, Offset base, double height, Paint paint) {
    final rect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - height / 2),
      width: 10,
      height: height,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
    canvas.drawCircle(Offset(base.dx, base.dy - height), 7, paint);
  }

  @override
  bool shouldRepaint(covariant MosqueScenePainter oldDelegate) => oldDelegate.color != color;
}

class MosqueSkylinePainter extends CustomPainter {
  MosqueSkylinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()..moveTo(0, size.height);

    void building(double x, double w, double h, {bool dome = false, bool minaret = false}) {
      final top = size.height - h;
      path.addRect(Rect.fromLTWH(x, top, w, h));
      if (dome) {
        path.addOval(Rect.fromCenter(center: Offset(x + w / 2, top), width: w * 0.9, height: w * 0.55));
      }
      if (minaret) {
        path.addRect(Rect.fromLTWH(x + w * 0.35, top - h * 0.55, w * 0.3, h * 0.55));
        path.addOval(Rect.fromCircle(center: Offset(x + w / 2, top - h * 0.55), radius: w * 0.22));
      }
    }

    building(0, 40, 36);
    building(36, 55, 58, dome: true);
    building(95, 28, 90, minaret: true);
    building(128, 70, 48, dome: true);
    building(200, 34, 100, minaret: true);
    building(240, 80, 55, dome: true);
    building(325, 30, 85, minaret: true);
    building(360, 60, 42, dome: true);
    building(420, 50, 70, dome: true);
    building(475, 28, 95, minaret: true);
    building(510, 70, 40);
    building(580, 50, 62, dome: true);
    building(640, 34, 88, minaret: true);
    building(680, 80, 45, dome: true);
    building(760, 40, 55);
    building(800, 60, 72, dome: true);

    // Stretch across width using transform if needed
    canvas.save();
    canvas.scale(size.width / 860, 1);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MosqueSkylinePainter oldDelegate) => oldDelegate.color != color;
}
