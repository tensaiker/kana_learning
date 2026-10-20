import 'package:flutter/material.dart';
import 'dart:ui';
import '../data/kana_data.dart'; // Imports the normalized Kana data model

// --- COLOR PALETTE ---
class AppColors {
  static const Color cream = Color(0xFFFDF8F3);
  static const Color beige = Color(0xFFEADFD1);
  static const Color sand = Color(0xFFDCC6A8);
  static const Color taupe = Color(0xFFC6B8A5);
  static const Color textDark = Color(0xFF5D534A);
  static const Color textLight = Color(0xFF8B8076);
  static const Color sage = Color(0xFFB7C9B2);
}

// -----------------------------------------------------------------------------
// 1. DASHED GRID PAINTER
// -----------------------------------------------------------------------------
/// Draws traditional dashed crosshair guidelines in the center of the canvas.
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textLight.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const double dashWidth = 8;
    const double dashSpace = 8;

    // Horizontal center dashed line
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Vertical center dashed line
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// 2. AUTHENTIC FONT REVEAL PAINTER (STAGE 1 & STAGE 2)
// -----------------------------------------------------------------------------
/// Uses a high-quality text font for accurate calligraphy, but masks it
/// using the stroke coordinate data to simulate a perfect writing animation.
class AuthenticFontRevealPainter extends CustomPainter {
  final KanaCharacter character;
  final double progress; // 0.0 to 1.0 (scales across all strokes)
  final Color textColor;

  AuthenticFontRevealPainter({
    required this.character,
    required this.progress,
    this.textColor = AppColors.textDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Layout the perfect text font
    final textPainter = TextPainter(
      text: TextSpan(
        text: character.kana,
        style: TextStyle(
          fontSize: size.width * 0.8, // Scales font to 80% of canvas
          fontWeight: FontWeight.w400,
          color: textColor,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );

    // 2. Save layer for masking. Everything drawn after this will be masked together.
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 3. Draw the beautiful text font onto the saved layer
    textPainter.paint(canvas, textOffset);

    // 4. Prepare the thick masking brush
    final maskPaint = Paint()
      ..color = Colors
          .black // Color doesn't matter for dstIn, only alpha matters
      ..strokeWidth =
          size.width *
          0.20 // Thick enough to cover the font's natural calligraphy thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode
          .dstIn; // CRITICAL: This blends the mask, hiding text where the brush hasn't painted!

    // 5. Draw the invisible strokes up to the current progress to reveal the text
    int totalStrokes = character.strokes.length;
    if (totalStrokes == 0) {
      canvas.restore();
      return;
    }

    double progressPerStroke = 1.0 / totalStrokes;

    for (int i = 0; i < totalStrokes; i++) {
      double strokeStartProgress = i * progressPerStroke;

      if (progress > strokeStartProgress) {
        double currentStrokeProgress =
            ((progress - strokeStartProgress) / progressPerStroke).clamp(
              0.0,
              1.0,
            );
        _drawPartialStroke(
          canvas,
          size,
          character.strokes[i].points,
          currentStrokeProgress,
          maskPaint,
        );
      }
    }

    // 6. Restore the canvas to apply the mask
    canvas.restore();
  }

  void _drawPartialStroke(
    Canvas canvas,
    Size size,
    List<Offset> points,
    double strokeProgress,
    Paint paint,
  ) {
    if (points.isEmpty) return;

    // Draw a dot if it's a single point
    if (points.length == 1) {
      canvas.drawCircle(
        Offset(points[0].dx * size.width, points[0].dy * size.height),
        paint.strokeWidth / 2,
        paint,
      );
      return;
    }

    Path path = Path();
    path.moveTo(points[0].dx * size.width, points[0].dy * size.height);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx * size.width, points[i].dy * size.height);
    }

    // Direct render if stroke has finished
    if (strokeProgress >= 1.0) {
      canvas.drawPath(path, paint);
    } else {
      // Extract partial stroke path based on animation progress
      PathMetrics pathMetrics = path.computeMetrics();
      for (PathMetric pathMetric in pathMetrics) {
        canvas.drawPath(
          pathMetric.extractPath(0.0, pathMetric.length * strokeProgress),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant AuthenticFontRevealPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.character != character ||
        oldDelegate.textColor != textColor;
  }
}

// -----------------------------------------------------------------------------
// 3. STATIC FONT PAINTER (STAGE 3 & STAGE 4 BACKGROUND GUIDES)
// -----------------------------------------------------------------------------
/// Renders a static font without animation. Used for faint background tracing guides.
class StaticFontPainter extends CustomPainter {
  final KanaCharacter character;
  final Color textColor;

  StaticFontPainter({required this.character, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: character.kana,
        style: TextStyle(
          fontSize: size.width * 0.8,
          fontWeight: FontWeight.w400,
          color: textColor,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant StaticFontPainter oldDelegate) {
    return oldDelegate.character != character ||
        oldDelegate.textColor != textColor;
  }
}

// -----------------------------------------------------------------------------
// 4. DIRECTIONAL MARKER PAINTER (STAGE 2)
// -----------------------------------------------------------------------------
/// Renders numbered badges at the start of each stroke with subtle directional hints.
class DirectionMarkerPainter extends CustomPainter {
  final KanaCharacter character;

  DirectionMarkerPainter({required this.character});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final circleFillPaint = Paint()
      ..color = AppColors.sand
      ..style = PaintingStyle.fill;

    final circleBorderPaint = Paint()
      ..color = AppColors.textDark
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = AppColors.taupe
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < character.strokes.length; i++) {
      final points = character.strokes[i].points;
      if (points.isEmpty) continue;

      Offset startPoint = Offset(
        points[0].dx * size.width,
        points[0].dy * size.height,
      );

      // Draw subtle directional hint arrow along the first stroke vector if long enough
      if (points.length > 1) {
        Offset nextPoint = Offset(
          points[1].dx * size.width,
          points[1].dy * size.height,
        );
        Offset direction = (nextPoint - startPoint);
        if (direction.distance > 24) {
          Offset normalizedDir = direction / direction.distance;
          Offset arrowTip = startPoint + normalizedDir * 24;
          canvas.drawLine(
            startPoint + normalizedDir * 14,
            arrowTip,
            arrowPaint,
          );
        }
      }

      // Draw Numbered Badge Circle
      canvas.drawCircle(startPoint, 13, circleFillPaint);
      canvas.drawCircle(startPoint, 13, circleBorderPaint);

      // Draw Number Text
      textPainter.text = TextSpan(
        text: '${i + 1}',
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          startPoint.dx - textPainter.width / 2,
          startPoint.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// 5. USER FREEHAND TRACING PAINTER (STAGE 3 & STAGE 4)
// -----------------------------------------------------------------------------
/// Renders user touch/mouse inputs on the drawing canvas.
class UserStrokePainter extends CustomPainter {
  final List<Offset?> points;
  final Color strokeColor;
  final double strokeWidth;

  UserStrokePainter({
    required this.points,
    this.strokeColor = AppColors.sage,
    this.strokeWidth = 18.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(PointMode.points, [points[i]!], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant UserStrokePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.strokeColor != strokeColor;
}
