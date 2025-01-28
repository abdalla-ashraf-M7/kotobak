import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'dart:math' as math;

class BookProgressIndicator extends StatelessWidget {
  final double progress;
  final double size;
  final Color? color;
  final bool showText;

  const BookProgressIndicator({
    Key? key,
    required this.progress,
    this.size = 60.0,
    this.color,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircularProgressPainter(
          progress: progress,
          color: color ?? AppColors.primary,
          backgroundColor: AppColors.secondaryContainer,
        ),
        child: showText
            ? Center(
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: size * 0.25,
                    fontWeight: FontWeight.bold,
                    color: color ?? AppColors.primary,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2, // Start from top
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) => progress != oldDelegate.progress || color != oldDelegate.color || backgroundColor != oldDelegate.backgroundColor;
}
