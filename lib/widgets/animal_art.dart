import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';

class AnimalArt extends StatelessWidget {
  const AnimalArt({
    super.key,
    required this.species,
    this.size = 44,
    this.color,
  });

  final PetSpecies species;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _AnimalPainter(species: species, color: color ?? species.ink),
    );
  }
}

class _AnimalPainter extends CustomPainter {
  _AnimalPainter({required this.species, required this.color});

  final PetSpecies species;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 64;
    canvas.save();
    canvas.scale(scale);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final eye = Paint()..color = Colors.white.withValues(alpha: 0.86);

    switch (species.artStyle) {
      case 'gecko':
        _gecko(canvas, paint, eye);
      case 'beardedDragon':
        _beardedDragon(canvas, paint, eye);
      case 'cockatiel':
        _cockatiel(canvas, paint, eye);
      case 'betta':
        _betta(canvas, paint, eye);
      case 'rabbit':
        _rabbit(canvas, paint, eye);
      case 'tarantula':
        _tarantula(canvas, paint, eye);
      case 'cat':
        _cat(canvas, paint, eye);
      case 'dog':
        _dog(canvas, paint, eye);
      case 'rodent':
        _rodent(canvas, paint, eye);
      case 'mustelid':
        _mustelid(canvas, paint, eye);
      case 'hedgehog':
        _hedgehog(canvas, paint, eye);
      case 'glider':
        _glider(canvas, paint, eye);
      case 'marsupial':
        _marsupial(canvas, paint, eye);
      case 'snake':
        _snake(canvas, paint, eye);
      case 'reptile':
        _reptile(canvas, paint, eye);
      case 'tortoise':
        _tortoise(canvas, paint, eye);
      case 'bird':
        _bird(canvas, paint, eye);
      case 'waterfowl':
        _waterfowl(canvas, paint, eye);
      case 'fish':
        _fish(canvas, paint, eye);
      case 'amphibian':
        _amphibian(canvas, paint, eye);
      case 'crustacean':
        _crustacean(canvas, paint, eye);
      case 'snail':
        _snail(canvas, paint, eye);
      case 'insect':
        _insect(canvas, paint, eye);
      default:
        _paw(canvas, paint);
    }
    canvas.restore();
  }

  void _gecko(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(22.5, 21.5, 19, 29), paint);
    canvas.drawCircle(const Offset(32, 19), 7.6, paint);
    _ovalAt(canvas, paint, const Offset(17.5, 28), 6.2, 2.3, -0.56);
    _ovalAt(canvas, paint, const Offset(46.5, 28), 6.2, 2.3, 0.56);
    _ovalAt(canvas, paint, const Offset(18, 42), 6.2, 2.3, 0.49);
    _ovalAt(canvas, paint, const Offset(46, 42), 6.2, 2.3, -0.49);
    final tail = Path()
      ..moveTo(32, 49)
      ..cubicTo(35, 55, 30, 59, 22, 60)
      ..cubicTo(19, 61, 18.5, 57, 23, 55)
      ..cubicTo(28, 53, 30, 51.5, 32, 49)
      ..close();
    canvas.drawPath(tail, paint);
    canvas.drawCircle(const Offset(29.2, 17.6), 1.4, eye);
    canvas.drawCircle(const Offset(34.8, 17.6), 1.4, eye);
  }

  void _beardedDragon(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(20, 26, 24, 27), paint);
    final head = Path()
      ..moveTo(32, 11)
      ..lineTo(34.5, 15.3)
      ..lineTo(39.5, 12.7)
      ..lineTo(38.4, 18)
      ..lineTo(43.4, 17.4)
      ..lineTo(40.5, 21.7)
      ..lineTo(45, 24)
      ..lineTo(40.1, 26.2)
      ..lineTo(43.5, 30.1)
      ..lineTo(38.3, 29.8)
      ..lineTo(38.8, 35)
      ..lineTo(34.4, 32)
      ..lineTo(32, 36.5)
      ..lineTo(30.6, 31.5)
      ..lineTo(25.7, 33)
      ..lineTo(27.1, 28)
      ..lineTo(22.5, 25.6)
      ..lineTo(27.1, 23.4)
      ..lineTo(24.1, 18.8)
      ..lineTo(29.3, 19.4)
      ..close();
    canvas.drawPath(head, paint);
    final tail = Path()
      ..moveTo(32, 50)
      ..cubicTo(33, 57, 29, 60, 20, 61)
      ..cubicTo(17, 61.5, 16, 57.5, 21, 56)
      ..cubicTo(27, 54, 30, 52, 32, 50)
      ..close();
    canvas.drawPath(tail, paint);
    _ovalAt(canvas, paint, const Offset(15.5, 32), 5.6, 3, -0.46);
    _ovalAt(canvas, paint, const Offset(48.5, 32), 5.6, 3, 0.46);
    canvas.drawCircle(const Offset(28.6, 20), 1.45, eye);
    canvas.drawCircle(const Offset(35.4, 20), 1.45, eye);
  }

  void _cockatiel(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(17.5, 26, 25, 29), paint);
    canvas.drawCircle(const Offset(31, 22), 9, paint);
    _ovalAt(canvas, paint, const Offset(28.5, 9), 2.7, 5.2, -0.24);
    _ovalAt(canvas, paint, const Offset(33.5, 9.5), 2.6, 4.8, 0.04);
    _ovalAt(canvas, paint, const Offset(37.8, 11), 2.4, 4.2, 0.35);
    final beak = Path()
      ..moveTo(39.7, 21)
      ..cubicTo(45.2, 21.5, 47, 24.5, 45.8, 26)
      ..cubicTo(43.7, 28, 40.5, 25.8, 37.8, 24.2)
      ..close();
    canvas.drawPath(beak, paint);
    final tail = Path()
      ..moveTo(22, 46)
      ..cubicTo(19.8, 54, 15, 59, 8, 61)
      ..cubicTo(16.5, 55.6, 19.5, 49, 19.8, 42)
      ..close();
    canvas.drawPath(tail, paint);
    canvas.drawCircle(const Offset(34, 20), 1.45, eye);
  }

  void _betta(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(23.5, 24, 23, 16), paint);
    final tail = Path()
      ..moveTo(24, 31.5)
      ..cubicTo(16, 24, 8.5, 22, 2.6, 26)
      ..cubicTo(6.2, 29.3, 10.2, 31.4, 14, 33.2)
      ..cubicTo(9.7, 35.4, 6.9, 38.2, 5.6, 41.5)
      ..cubicTo(12.4, 42.1, 19.4, 38, 24.8, 32.7)
      ..close();
    canvas.drawPath(tail, paint);
    final topFin = Path()
      ..moveTo(31, 24)
      ..cubicTo(34, 17.8, 39.2, 14.5, 45.6, 14.6)
      ..cubicTo(43.6, 18.5, 41, 21.1, 38, 22.9)
      ..cubicTo(41.8, 23.2, 44.7, 24.2, 46.6, 26)
      ..cubicTo(40.3, 29, 34.2, 26.5, 31, 24)
      ..close();
    canvas.drawPath(topFin, paint);
    final bottomFin = Path()
      ..moveTo(33, 40)
      ..cubicTo(36.6, 45.4, 41.6, 47.6, 47, 46.6)
      ..cubicTo(44, 43.4, 42, 41, 40.2, 38)
      ..close();
    canvas.drawPath(bottomFin, paint);
    canvas.drawCircle(const Offset(41.5, 30), 1.4, eye);
  }

  void _rabbit(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(19, 31, 26, 24), paint);
    canvas.drawCircle(const Offset(32, 25), 9, paint);
    _ovalAt(canvas, paint, const Offset(26.8, 11.5), 3.5, 9.4, -0.18);
    _ovalAt(canvas, paint, const Offset(37.2, 11.5), 3.5, 9.4, 0.18);
    canvas.drawCircle(const Offset(45, 48), 4.6, paint);
    canvas.drawCircle(const Offset(28.6, 24), 1.45, eye);
    canvas.drawCircle(const Offset(35.4, 24), 1.45, eye);
    final nose = Paint()..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawCircle(const Offset(32, 27.5), 1.5, nose);
  }

  void _tarantula(Canvas canvas, Paint paint, Paint eye) {
    final legs = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final paths = <Path>[
      Path()
        ..moveTo(25, 33)
        ..lineTo(12, 25),
      Path()
        ..moveTo(24, 37)
        ..lineTo(10, 37),
      Path()
        ..moveTo(25, 41)
        ..lineTo(13, 50),
      Path()
        ..moveTo(40, 32)
        ..lineTo(53, 24),
      Path()
        ..moveTo(41, 36)
        ..lineTo(55, 36),
      Path()
        ..moveTo(40, 40)
        ..lineTo(52, 49),
    ];
    for (final path in paths) {
      canvas.drawPath(path, legs);
    }
    canvas.drawCircle(const Offset(26, 36), 7.6, paint);
    canvas.drawCircle(const Offset(41, 41), 10.6, paint);
    canvas.drawCircle(
      const Offset(23, 34),
      1.35,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  void _cat(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(19, 30, 28, 25), paint);
    final head = Path()
      ..moveTo(21, 25)
      ..lineTo(22, 12)
      ..lineTo(29, 19)
      ..cubicTo(31, 18, 34, 18, 36, 19)
      ..lineTo(43, 12)
      ..lineTo(44, 25)
      ..cubicTo(44, 31, 39, 35, 32.5, 35)
      ..cubicTo(26, 35, 21, 31, 21, 25)
      ..close();
    canvas.drawPath(head, paint);
    final tail = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final tailPath = Path()
      ..moveTo(45, 48)
      ..cubicTo(55, 47, 57, 37, 52, 32);
    canvas.drawPath(tailPath, tail);
    canvas.drawCircle(const Offset(28, 25), 1.25, eye);
    canvas.drawCircle(const Offset(37, 25), 1.25, eye);
  }

  void _dog(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(19, 29, 29, 27), paint);
    canvas.drawCircle(const Offset(32, 24), 10, paint);
    _ovalAt(canvas, paint, const Offset(21, 24), 4, 9, -0.45);
    _ovalAt(canvas, paint, const Offset(43, 24), 4, 9, 0.45);
    canvas.drawOval(const Rect.fromLTWH(28, 27, 8, 5), eye);
    canvas.drawCircle(const Offset(28, 22), 1.3, eye);
    canvas.drawCircle(const Offset(36, 22), 1.3, eye);
    final tail = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(45, 44), const Offset(54, 37), tail);
  }

  void _rodent(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(19, 31, 26, 23), paint);
    canvas.drawCircle(const Offset(34, 29), 10, paint);
    canvas.drawCircle(const Offset(27, 20), 3.7, paint);
    canvas.drawCircle(const Offset(40, 20), 3.7, paint);
    canvas.drawCircle(const Offset(30.5, 28), 1.25, eye);
    canvas.drawCircle(const Offset(37, 28), 1.25, eye);
    canvas.drawCircle(
      const Offset(33.5, 33),
      1.5,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  void _mustelid(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(13, 31, 39, 15), paint);
    canvas.drawCircle(const Offset(46, 26), 9, paint);
    _ovalAt(canvas, paint, const Offset(18, 40), 9, 2.5, 0.2);
    canvas.drawCircle(const Offset(49, 24), 1.2, eye);
  }

  void _hedgehog(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(17, 31, 28, 20), paint);
    final spikes = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 9; index++) {
      final x = 20.0 + index * 3.1;
      canvas.drawLine(Offset(x, 33), Offset(x - 2, 27 - (index % 3)), spikes);
    }
    canvas.drawCircle(const Offset(44, 36), 7.5, paint);
    canvas.drawCircle(const Offset(47, 34), 1.1, eye);
  }

  void _glider(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawCircle(const Offset(32, 28), 9.5, paint);
    final body = Path()
      ..moveTo(25, 33)
      ..lineTo(12, 47)
      ..lineTo(25, 50)
      ..lineTo(32, 43)
      ..lineTo(39, 50)
      ..lineTo(52, 47)
      ..lineTo(39, 33)
      ..close();
    canvas.drawPath(body, paint);
    canvas.drawCircle(const Offset(28, 15), 5.2, paint);
    canvas.drawCircle(const Offset(36, 15), 5.2, paint);
    canvas.drawCircle(const Offset(29, 27), 1.3, eye);
    canvas.drawCircle(const Offset(35, 27), 1.3, eye);
  }

  void _marsupial(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(24, 28, 18, 26), paint);
    canvas.drawCircle(const Offset(36, 20), 7, paint);
    _ovalAt(canvas, paint, const Offset(31, 11), 2.8, 6.3, -0.3);
    _ovalAt(canvas, paint, const Offset(41, 11), 2.8, 6.3, 0.28);
    final tail = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(27, 50)
      ..cubicTo(14, 58, 10, 46, 18, 43);
    canvas.drawPath(path, tail);
    _ovalAt(canvas, paint, const Offset(22, 52), 8, 3.2, 0.25);
    _ovalAt(canvas, paint, const Offset(31, 52), 8, 3.2, -0.15);
    canvas.drawCircle(const Offset(39, 19), 1.2, eye);
  }

  void _snake(Canvas canvas, Paint paint, Paint eye) {
    final snake = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(14, 52)
      ..cubicTo(2, 43, 35, 38, 25, 27)
      ..cubicTo(18, 19, 49, 17, 47, 9);
    canvas.drawPath(path, snake);
    canvas.drawCircle(const Offset(47, 9), 5, paint);
    canvas.drawCircle(const Offset(48.5, 8), 1.1, eye);
  }

  void _reptile(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(23, 23, 18, 26), paint);
    canvas.drawCircle(const Offset(38, 20), 7, paint);
    _ovalAt(canvas, paint, const Offset(21, 31), 6, 2.2, -0.4);
    _ovalAt(canvas, paint, const Offset(19, 42), 6, 2.2, 0.35);
    _ovalAt(canvas, paint, const Offset(43, 35), 5.5, 2.2, 0.5);
    final tail = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(29, 48), const Offset(18, 58), tail);
    canvas.drawCircle(const Offset(40, 19), 1.1, eye);
  }

  void _tortoise(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(15, 27, 36, 27), paint);
    canvas.drawCircle(const Offset(49, 31), 6.5, paint);
    _ovalAt(canvas, paint, const Offset(19, 46), 5, 2.2, 0.3);
    _ovalAt(canvas, paint, const Offset(45, 48), 5, 2.2, -0.2);
    canvas.drawCircle(const Offset(50, 29), 1.1, eye);
    canvas.drawArc(
      const Rect.fromLTWH(21, 32, 22, 16),
      -1.2,
      2.4,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _bird(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(20, 27, 24, 25), paint);
    canvas.drawCircle(const Offset(36, 22), 8, paint);
    _ovalAt(canvas, paint, const Offset(36, 31), 6, 2.6, 0.15);
    final beak = Path()
      ..moveTo(43, 20)
      ..lineTo(51, 24)
      ..lineTo(43, 26)
      ..close();
    canvas.drawPath(beak, paint);
    canvas.drawCircle(const Offset(39, 20), 1.2, eye);
  }

  void _waterfowl(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(17, 30, 29, 20), paint);
    canvas.drawCircle(const Offset(43, 27), 8, paint);
    final beak = Path()
      ..moveTo(49, 25)
      ..cubicTo(56, 25, 58, 27, 57, 30)
      ..cubicTo(53, 31, 50, 29, 48, 28)
      ..close();
    canvas.drawPath(beak, paint);
    canvas.drawCircle(const Offset(45, 25), 1.2, eye);
  }

  void _fish(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(20, 25, 28, 17), paint);
    final tail = Path()
      ..moveTo(22, 32)
      ..lineTo(8, 24)
      ..lineTo(10, 35)
      ..lineTo(8, 44)
      ..close();
    canvas.drawPath(tail, paint);
    canvas.drawCircle(const Offset(41, 30), 1.3, eye);
  }

  void _amphibian(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(17, 29, 30, 20), paint);
    canvas.drawCircle(const Offset(30, 25), 9, paint);
    canvas.drawCircle(const Offset(26, 23), 3.2, paint);
    canvas.drawCircle(const Offset(37, 23), 3.2, paint);
    _ovalAt(canvas, paint, const Offset(18, 48), 8, 2.3, 0.14);
    _ovalAt(canvas, paint, const Offset(46, 48), 8, 2.3, -0.14);
    canvas.drawCircle(const Offset(26, 22), 1.2, eye);
    canvas.drawCircle(const Offset(37, 22), 1.2, eye);
  }

  void _crustacean(Canvas canvas, Paint paint, Paint eye) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 3; index++) {
      canvas.drawLine(
        Offset(22, 34 + index * 6),
        Offset(8, 27 + index * 9),
        stroke,
      );
      canvas.drawLine(
        Offset(42, 34 + index * 6),
        Offset(56, 27 + index * 9),
        stroke,
      );
    }
    canvas.drawCircle(const Offset(32, 35), 13, paint);
    canvas.drawCircle(const Offset(25, 40), 1.2, eye);
    canvas.drawCircle(const Offset(36, 40), 1.2, eye);
  }

  void _snail(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawCircle(const Offset(33, 35), 15, paint);
    final spiral = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(33, 35), radius: 9),
      -1.2,
      4.8,
      false,
      spiral,
    );
    _ovalAt(canvas, paint, const Offset(42, 47), 13, 3.2, 0.04);
    canvas.drawLine(
      const Offset(43, 43),
      const Offset(49, 36),
      Paint()
        ..color = color
        ..strokeWidth = 2.2,
    );
    canvas.drawCircle(const Offset(49, 36), 1.1, eye);
  }

  void _insect(Canvas canvas, Paint paint, Paint eye) {
    canvas.drawOval(const Rect.fromLTWH(29, 20, 7, 30), paint);
    canvas.drawCircle(const Offset(32.5, 18), 5.5, paint);
    final legs = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 3; index++) {
      canvas.drawLine(
        Offset(30, 29 + index * 7),
        Offset(19, 24 + index * 10),
        legs,
      );
      canvas.drawLine(
        Offset(35, 29 + index * 7),
        Offset(46, 24 + index * 10),
        legs,
      );
    }
    canvas.drawCircle(const Offset(30, 17), 1.1, eye);
    canvas.drawCircle(const Offset(35, 17), 1.1, eye);
  }

  void _paw(Canvas canvas, Paint paint) {
    canvas.drawOval(const Rect.fromLTWH(20, 32, 24, 18), paint);
    canvas.drawCircle(const Offset(17, 24), 4.6, paint);
    canvas.drawCircle(const Offset(27, 17), 4.2, paint);
    canvas.drawCircle(const Offset(37, 17), 4.2, paint);
    canvas.drawCircle(const Offset(47, 24), 4.6, paint);
  }

  void _ovalAt(
    Canvas canvas,
    Paint paint,
    Offset center,
    double radiusX,
    double radiusY,
    double rotation,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radiusX * 2,
        height: radiusY * 2,
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AnimalPainter oldDelegate) {
    return oldDelegate.species != species || oldDelegate.color != color;
  }
}

class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color, this.size = 7});

  final Color color;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = math.sin(_controller.value * math.pi * 2);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                  alpha: 0.15 + (phase + 1) * 0.08,
                ),
                blurRadius: 7 + phase * 2,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
