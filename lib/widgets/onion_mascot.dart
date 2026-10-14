import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Maskot bawang yang tumbuh mengikuti streak:
/// 0 = biji, 1-6 = tunas, 7-29 = bawang muda, 30+ = bawang besar.
class OnionMascot extends StatelessWidget {
  const OnionMascot({super.key, required this.streak, this.size = 120});

  final int streak;
  final double size;

  static int tahap(int s) => s <= 0 ? 0 : (s < 7 ? 1 : (s < 30 ? 2 : 3));

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _OnionPainter(tahap(streak))),
      );
}

class _OnionPainter extends CustomPainter {
  _OnionPainter(this.tahap);
  final int tahap;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final tanah = Paint()..color = const Color(0xFF8D6E63);
    final daun = Paint()..color = const Color(0xFF4CAF50);
    final daunGelap = Paint()..color = const Color(0xFF388E3C);
    final ungu = Paint()..color = const Color(0xFF9C5BB0);
    final garis = Paint()
      ..color = const Color(0xFF5E2B6E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round;

    void helai(Offset dasar, double panjang, double sudut, Paint p) {
      canvas.save();
      canvas.translate(dasar.dx, dasar.dy);
      canvas.rotate(sudut);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(panjang * 0.35, -panjang * 0.5, 0, -panjang)
        ..quadraticBezierTo(-panjang * 0.35, -panjang * 0.5, 0, 0)
        ..close();
      canvas.drawPath(path, p);
      canvas.restore();
    }

    // Gundukan tanah
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w / 2, h * 0.84), width: w * 0.7, height: h * 0.14),
        tanah);

    if (tahap == 0) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(w / 2, h * 0.74), width: w * 0.22, height: h * 0.15),
          Paint()..color = const Color(0xFFE0B97A));
      return;
    }

    if (tahap == 1) {
      canvas.drawLine(
          Offset(w / 2, h * 0.82),
          Offset(w / 2, h * 0.5),
          Paint()
            ..color = const Color(0xFF4CAF50)
            ..strokeWidth = w * 0.04
            ..strokeCap = StrokeCap.round);
      helai(Offset(w / 2, h * 0.56), h * 0.26, -0.9, daun);
      helai(Offset(w / 2, h * 0.5), h * 0.26, 0.9, daunGelap);
      return;
    }

    final besar = tahap == 3;
    final cx = w / 2;
    final cy = h * (besar ? 0.58 : 0.64);
    final rx = w * (besar ? 0.3 : 0.22);
    final ry = rx * 0.95;

    // Daun
    final sudut = besar
        ? [-0.9, -0.45, 0.0, 0.45, 0.9]
        : [-0.5, 0.0, 0.5];
    final panjang = ry * (besar ? 1.3 : 1.0);
    for (var i = 0; i < sudut.length; i++) {
      helai(Offset(cx, cy - ry * 1.4), panjang, sudut[i], i.isEven ? daun : daunGelap);
    }

    // Akar
    for (final dx in [-0.3, 0.0, 0.3]) {
      canvas.drawLine(Offset(cx + rx * dx, cy + ry * 0.98),
          Offset(cx + rx * dx * 1.6, cy + ry * 1.2), garis);
    }

    // Badan
    final badan = Path()
      ..moveTo(cx, cy - ry * 1.5)
      ..cubicTo(cx + rx * 0.35, cy - ry * 0.9, cx + rx, cy - ry * 0.7, cx + rx, cy)
      ..cubicTo(cx + rx, cy + ry * 0.8, cx + rx * 0.5, cy + ry, cx, cy + ry)
      ..cubicTo(cx - rx * 0.5, cy + ry, cx - rx, cy + ry * 0.8, cx - rx, cy)
      ..cubicTo(cx - rx, cy - ry * 0.7, cx - rx * 0.35, cy - ry * 0.9, cx, cy - ry * 1.5)
      ..close();
    canvas.drawPath(badan, ungu);

    if (besar) {
      for (final s in [-1.0, 1.0]) {
        final l = Path()
          ..moveTo(cx, cy - ry * 1.4)
          ..quadraticBezierTo(cx + s * rx * 0.85, cy, cx + s * rx * 0.3, cy + ry * 0.95);
        canvas.drawPath(l, garis);
      }
      canvas.drawLine(Offset(cx, cy - ry * 1.4), Offset(cx, cy + ry * 0.98), garis);
    }

    // Wajah
    final mata = Paint()..color = const Color(0xFF2C1A33);
    final pipi = Paint()..color = const Color(0x55FF8FB1);
    final r = rx * 0.1;
    final yMata = cy + ry * 0.08;
    for (final s in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(cx + s * rx * 0.38, yMata), r, mata);
      canvas.drawCircle(Offset(cx + s * rx * 0.34, yMata - r * 0.3), r * 0.35,
          Paint()..color = Colors.white);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + s * rx * 0.62, yMata + r * 2.2),
              width: r * 2.4,
              height: r * 1.4),
          pipi);
    }
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx, cy + ry * 0.32), width: rx * 0.5, height: rx * 0.36),
        0.2,
        math.pi - 0.4,
        false,
        garis);
  }

  @override
  bool shouldRepaint(covariant _OnionPainter old) => old.tahap != tahap;
}
