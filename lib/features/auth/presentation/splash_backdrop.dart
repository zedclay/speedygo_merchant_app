import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';

/// Subtle decorative curves for the Merchant branded splash (static paint only).
class MerchantSplashBackdropPainter extends CustomPainter {
  const MerchantSplashBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final topGlow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.85, h * 0.08),
        w * 0.75,
        [
          AppColors.primaryContainer.withValues(alpha: 0.45),
          AppColors.primary.withValues(alpha: 0.0),
        ],
        const [0.0, 1.0],
      );
    canvas.drawCircle(Offset(w * 0.92, -h * 0.02), w * 0.65, topGlow);

    final bottomGlow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.1, h * 0.95),
        w * 0.8,
        [
          const Color(0xFFBBD562).withValues(alpha: 0.12),
          AppColors.primary.withValues(alpha: 0.0),
        ],
        const [0.0, 1.0],
      );
    canvas.drawCircle(Offset(w * 0.05, h * 1.02), w * 0.7, bottomGlow);

    final curvePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.14);

    final softPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..color = Colors.white.withValues(alpha: 0.08);

    final upper = Path()
      ..moveTo(-w * 0.1, h * 0.22)
      ..cubicTo(w * 0.2, h * 0.05, w * 0.55, h * 0.28, w * 1.05, h * 0.12);
    canvas.drawPath(upper, softPaint);
    canvas.drawPath(upper, curvePaint);

    final lower = Path()
      ..moveTo(-w * 0.05, h * 0.82)
      ..cubicTo(w * 0.3, h * 0.68, w * 0.7, h * 0.92, w * 1.1, h * 0.74);
    canvas.drawPath(lower, softPaint);
    canvas.drawPath(lower, curvePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
