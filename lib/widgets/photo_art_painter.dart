import 'dart:math';

import 'package:flutter/material.dart';

import '../models/photo.dart';

/// Paints deterministic, photo-like placeholder scenes for mock data.
///
/// Mock-only: once real photos are wired up, `PhotoView` renders
/// `Photo.image` instead.
class PhotoArtPainter extends CustomPainter {
  const PhotoArtPainter(this.art);

  final PhotoArt art;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final r = Random(art.seed);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    switch (art.scene) {
      case ArtScene.sunset:
        _sunset(canvas, size, r);
      case ArtScene.mountains:
        _mountains(canvas, size, r);
      case ArtScene.ocean:
        _ocean(canvas, size, r);
      case ArtScene.city:
        _city(canvas, size, r);
      case ArtScene.forest:
        _forest(canvas, size, r);
      case ArtScene.desert:
        _desert(canvas, size, r);
      case ArtScene.aurora:
        _aurora(canvas, size, r);
      case ArtScene.food:
        _food(canvas, size, r);
      case ArtScene.screenshot:
        _screenshot(canvas, size, r);
      case ArtScene.document:
        _document(canvas, size, r);
    }
    if (art.scene != ArtScene.screenshot && art.scene != ArtScene.document) {
      _vignette(canvas, size);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PhotoArtPainter old) =>
      old.art.seed != art.seed || old.art.scene != art.scene || old.art.variant != art.variant;

  // ---------------------------------------------------------------- helpers

  double get _v => art.variant;

  void _fillGradient(Canvas c, Rect rect, List<Color> colors, {List<double>? stops}) {
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ).createShader(rect),
    );
  }

  void _glow(Canvas c, Offset center, double radius, Color color) {
    c.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  /// A ridge line from left to right, closed to the bottom of the canvas.
  Path _ridge(Size s, Random r, double baseY, double amp, int points, {bool smooth = true}) {
    final pts = <Offset>[];
    for (var i = 0; i <= points; i++) {
      final x = s.width * i / points;
      final y = baseY - r.nextDouble() * amp + amp * 0.3;
      pts.add(Offset(x, y));
    }
    final path = Path()
      ..moveTo(0, s.height)
      ..lineTo(pts.first.dx, pts.first.dy);
    if (smooth) {
      for (var i = 0; i < pts.length - 1; i++) {
        final mid = Offset((pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
        path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
      }
      path.lineTo(pts.last.dx, pts.last.dy);
    } else {
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
    }
    path
      ..lineTo(s.width, s.height)
      ..close();
    return path;
  }

  void _stars(Canvas c, Size s, Random r, int count, double maxY) {
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      paint.color = Colors.white.withValues(alpha: 0.3 + r.nextDouble() * 0.6);
      c.drawCircle(
        Offset(r.nextDouble() * s.width, r.nextDouble() * s.height * maxY),
        0.4 + r.nextDouble() * 1.2,
        paint,
      );
    }
  }

  void _vignette(Canvas c, Size s) {
    final rect = Offset.zero & s;
    c.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.28)],
          stops: const [0.55, 1],
        ).createShader(rect),
    );
  }

  T _pick<T>(Random r, List<T> list) => list[r.nextInt(list.length)];

  // ----------------------------------------------------------------- scenes

  void _sunset(Canvas c, Size s, Random r) {
    final p = _pick(r, const [
      [Color(0xFF2B1B4A), Color(0xFF8E3B6E), Color(0xFFF0765A), Color(0xFFFFC98B)],
      [Color(0xFF1D2B53), Color(0xFF7E2553), Color(0xFFFF6B4A), Color(0xFFFFD39A)],
      [Color(0xFF3A1C5C), Color(0xFFC04A7A), Color(0xFFFF9A5C), Color(0xFFFFE0A8)],
    ]);
    _fillGradient(c, Offset.zero & s, p, stops: const [0, 0.45, 0.72, 1]);
    final sun = Offset(s.width * (0.35 + r.nextDouble() * 0.3 + _v * 0.12), s.height * (0.6 - _v * 0.04));
    _glow(c, sun, s.width * 0.55, p[3].withValues(alpha: 0.65));
    c.drawCircle(sun, s.width * 0.085, Paint()..color = const Color(0xFFFFF1D6));
    final layers = [
      (0.64, 0.10, Color.lerp(p[1], p[0], 0.35)!.withValues(alpha: 0.85)),
      (0.73, 0.08, Color.lerp(p[0], Colors.black, 0.15)!),
      (0.84, 0.06, Color.lerp(p[0], Colors.black, 0.45)!),
    ];
    for (final (base, amp, color) in layers) {
      c.drawPath(_ridge(s, r, s.height * base, s.height * amp, 7), Paint()..color = color);
    }
  }

  void _mountains(Canvas c, Size s, Random r) {
    final sky = _pick(r, const [
      [Color(0xFF5B8FD1), Color(0xFFA9CBEA), Color(0xFFE7F0F7)],
      [Color(0xFF7FA6C9), Color(0xFFC6D8E6), Color(0xFFF1EEE8)],
    ]);
    _fillGradient(c, Offset.zero & s, sky, stops: const [0, 0.5, 0.8]);
    _glow(c, Offset(s.width * (0.8 - _v * 0.2), s.height * 0.12), s.width * 0.4, Colors.white.withValues(alpha: 0.5));

    final peak = _ridge(s, r, s.height * 0.42, s.height * 0.22, 5, smooth: false);
    final rect = Offset.zero & s;
    c.drawPath(
      peak,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6E7F99), Color(0xFF3E4A5E)],
        ).createShader(rect),
    );
    // Snow caps.
    c.save();
    c.clipPath(peak);
    c.drawRect(
      Rect.fromLTWH(0, 0, s.width, s.height * 0.44),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white.withValues(alpha: 0)],
          stops: const [0.55, 1],
        ).createShader(Rect.fromLTWH(0, 0, s.width, s.height * 0.44)),
    );
    c.restore();

    c.drawPath(_ridge(s, r, s.height * 0.62, s.height * 0.08, 6), Paint()..color = const Color(0xFF2F4A3F));
    c.drawPath(_ridge(s, r, s.height * 0.7, s.height * 0.05, 8), Paint()..color = const Color(0xFF1E332B));

    final lake = Rect.fromLTWH(0, s.height * 0.74, s.width, s.height * 0.26);
    _fillGradient(c, lake, const [Color(0xFF3F8C9A), Color(0xFF1F4F5E)]);
    final line = Paint()..color = Colors.white.withValues(alpha: 0.25);
    for (var i = 0; i < 9; i++) {
      final y = lake.top + 8 + r.nextDouble() * (lake.height - 16);
      final x = r.nextDouble() * s.width;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, s.width * (0.08 + r.nextDouble() * 0.2), 1.6),
          const Radius.circular(1),
        ),
        line,
      );
    }
  }

  void _ocean(Canvas c, Size s, Random r) {
    _fillGradient(c, Offset.zero & s, const [Color(0xFF79B8E8), Color(0xFFC9E6F7)], stops: const [0, 0.5]);
    final sun = Offset(s.width * (0.72 - _v * 0.1), s.height * 0.16);
    _glow(c, sun, s.width * 0.35, Colors.white.withValues(alpha: 0.9));
    final horizon = s.height * (0.5 + r.nextDouble() * 0.06);
    _fillGradient(c, Rect.fromLTWH(0, horizon, s.width, s.height - horizon), const [
      Color(0xFF1B6F8F),
      Color(0xFF2BB3B8),
      Color(0xFF7EDFD4),
    ]);
    final foam = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (var i = 0; i < 14; i++) {
      final y = horizon + 6 + r.nextDouble() * (s.height * 0.26);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(r.nextDouble() * s.width, y, s.width * (0.05 + r.nextDouble() * 0.18), 2),
          const Radius.circular(1),
        ),
        foam,
      );
    }
    final shore = Path()
      ..moveTo(0, s.height * 0.8)
      ..quadraticBezierTo(s.width * 0.45, s.height * (0.74 + r.nextDouble() * 0.04), s.width, s.height * 0.84)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(shore.shift(const Offset(0, -6)), Paint()..color = Colors.white.withValues(alpha: 0.6));
    c.drawPath(
      shore,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF2DDB6), Color(0xFFE2C091)],
        ).createShader(Offset.zero & s),
    );
  }

  void _city(Canvas c, Size s, Random r) {
    _fillGradient(c, Offset.zero & s, const [Color(0xFF0B1026), Color(0xFF1B2A5A), Color(0xFF4B3F7A)]);
    _stars(c, s, r, 50, 0.5);
    final moon = Offset(s.width * (0.2 + r.nextDouble() * 0.2 + _v * 0.1), s.height * 0.16);
    _glow(c, moon, s.width * 0.22, const Color(0x55C9D6FF));
    c.drawCircle(moon, s.width * 0.05, Paint()..color = const Color(0xFFF1F3FF));

    final window = Paint();
    final building = Paint();
    for (final layer in [0, 1]) {
      var x = -s.width * 0.02;
      while (x < s.width) {
        final w = s.width * (0.08 + r.nextDouble() * 0.1);
        final h = s.height * (layer == 0 ? 0.35 + r.nextDouble() * 0.3 : 0.2 + r.nextDouble() * 0.28);
        final top = s.height * 0.92 - h;
        building.color = layer == 0 ? const Color(0xFF1A2146) : const Color(0xFF0E1330);
        c.drawRect(Rect.fromLTWH(x, top, w, h), building);
        final cols = max(2, (w / 9).floor());
        final colW = w / cols;
        for (var wy = top + 8; wy < s.height * 0.9; wy += 11) {
          for (var i = 0; i < cols; i++) {
            if (r.nextDouble() < (layer == 0 ? 0.35 : 0.45)) {
              window.color = Color.lerp(
                const Color(0xFFFFD27A),
                const Color(0xFFFFF3C4),
                r.nextDouble(),
              )!.withValues(alpha: 0.55 + r.nextDouble() * 0.4);
              c.drawRect(Rect.fromLTWH(x + i * colW + colW * 0.25, wy, colW * 0.5, 5), window);
            }
          }
        }
        x += w + (layer == 0 ? s.width * 0.02 : 0);
      }
    }
    _fillGradient(c, Rect.fromLTWH(0, s.height * 0.92, s.width, s.height * 0.08), const [
      Color(0xFF0A0D20),
      Color(0xFF05060F),
    ]);
  }

  void _forest(Canvas c, Size s, Random r) {
    _fillGradient(c, Offset.zero & s, const [Color(0xFFAFC4B4), Color(0xFFE6EEE4)], stops: const [0, 0.6]);
    const colors = [Color(0xFF8DA897), Color(0xFF5E7F6B), Color(0xFF365645), Color(0xFF1C3328)];
    for (var layer = 0; layer < 4; layer++) {
      final base = s.height * (0.5 + layer * 0.14);
      final paint = Paint()..color = colors[layer];
      var x = -10.0 + _v * 10;
      while (x < s.width + 10) {
        final w = s.width * (0.07 + r.nextDouble() * 0.05) * (1 + layer * 0.25);
        final h = w * (2.2 + r.nextDouble());
        c.drawPath(
          Path()
            ..moveTo(x, base)
            ..lineTo(x + w / 2, base - h)
            ..lineTo(x + w, base)
            ..close(),
          paint,
        );
        x += w * 0.6;
      }
      c.drawRect(Rect.fromLTWH(0, base, s.width, s.height - base), paint);
      _fillGradient(c, Rect.fromLTWH(0, base - s.height * 0.1, s.width, s.height * 0.12), [
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0.28),
      ]);
    }
  }

  void _desert(Canvas c, Size s, Random r) {
    _fillGradient(c, Offset.zero & s, const [Color(0xFFF7C99B), Color(0xFFFBE3C2)], stops: const [0, 0.55]);
    final sun = Offset(s.width * (0.3 + r.nextDouble() * 0.4 + _v * 0.1), s.height * 0.3);
    _glow(c, sun, s.width * 0.4, const Color(0x99FFF4DE));
    c.drawCircle(sun, s.width * 0.1, Paint()..color = const Color(0xFFFFF6E6));
    const dunes = [Color(0xFFE3A56C), Color(0xFFD08548), Color(0xFFB0602D)];
    for (var i = 0; i < 3; i++) {
      c.drawPath(_ridge(s, r, s.height * (0.58 + i * 0.13), s.height * 0.12, 3), Paint()..color = dunes[i]);
    }
  }

  void _aurora(Canvas c, Size s, Random r) {
    _fillGradient(c, Offset.zero & s, const [Color(0xFF040915), Color(0xFF0A1B33), Color(0xFF12305A)]);
    _stars(c, s, r, 70, 0.7);
    const bands = [Color(0xFF3CF0A8), Color(0xFF2BD4C8), Color(0xFF9B7CFF)];
    for (var i = 0; i < 3; i++) {
      final y = s.height * (0.22 + i * 0.1 + r.nextDouble() * 0.05);
      final path = Path()..moveTo(-20, y);
      for (var k = 1; k <= 4; k++) {
        path.quadraticBezierTo(
          s.width * (k - 0.5) / 4,
          y + (r.nextDouble() - 0.5) * s.height * 0.22 + _v * 20,
          s.width * k / 4 + (k == 4 ? 20 : 0),
          y + (r.nextDouble() - 0.5) * s.height * 0.08,
        );
      }
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * (0.1 - i * 0.02)
          ..color = bands[i].withValues(alpha: 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.width * 0.06),
      );
    }
    c.drawPath(_ridge(s, r, s.height * 0.8, s.height * 0.08, 6), Paint()..color = const Color(0xFF050A14));
  }

  void _food(Canvas c, Size s, Random r) {
    final table = _pick(r, const [
      [Color(0xFFE9DCCB), Color(0xFFD9C6AE)],
      [Color(0xFF9C6B4A), Color(0xFF7A5037)],
      [Color(0xFFDCE3E6), Color(0xFFC3CDD2)],
    ]);
    _fillGradient(c, Offset.zero & s, table);
    final center = Offset(s.width * (0.48 + _v * 0.05), s.height * 0.5);
    final plate = s.width * 0.36;
    c.drawCircle(
      center.translate(0, 10),
      plate,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    c.drawCircle(center, plate, Paint()..color = const Color(0xFFFBFAF7));
    c.drawCircle(center, plate * 0.78, Paint()..color = const Color(0xFFF1EEE8));
    const foods = [
      Color(0xFFE85D4A),
      Color(0xFF8BC34A),
      Color(0xFFF6B93B),
      Color(0xFF6D3F2A),
      Color(0xFFB83B5E),
      Color(0xFFFFE08A),
    ];
    for (var i = 0; i < 14; i++) {
      final a = r.nextDouble() * pi * 2;
      final d = r.nextDouble() * plate * 0.55;
      final o = center + Offset(cos(a) * d, sin(a) * d);
      final rad = plate * (0.1 + r.nextDouble() * 0.1);
      final col = foods[r.nextInt(foods.length)];
      c.drawCircle(
        o,
        rad,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [Color.lerp(col, Colors.white, 0.3)!, col],
          ).createShader(Rect.fromCircle(center: o, radius: rad)),
      );
    }
    // Coffee cup.
    final cup = Offset(s.width * 0.85, s.height * 0.14);
    c.drawCircle(cup, s.width * 0.14, Paint()..color = const Color(0xFFFBFAF7));
    c.drawCircle(cup, s.width * 0.11, Paint()..color = const Color(0xFF5A3A26));
    c.drawCircle(cup, s.width * 0.06, Paint()..color = const Color(0xFFC89B6D).withValues(alpha: 0.8));
    // Cutlery.
    final metal = Paint()..color = const Color(0xFFCBCED3);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.06, s.height * 0.3, s.width * 0.03, s.height * 0.42),
        const Radius.circular(8),
      ),
      metal,
    );
  }

  void _screenshot(Canvas c, Size s, Random r) {
    final dark = r.nextBool();
    final bg = dark ? const Color(0xFF121318) : const Color(0xFFF7F7FA);
    final fg = dark ? const Color(0xFF2A2C35) : const Color(0xFFE3E4EA);
    final ink = dark ? const Color(0xFF8A8D99) : const Color(0xFFB7BAC4);
    final accent = _pick(r, const [
      Color(0xFF4F46E5),
      Color(0xFF0EA5E9),
      Color(0xFFF43F5E),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
    ]);
    c.drawRect(Offset.zero & s, Paint()..color = bg);

    final u = s.width / 20; // grid unit
    RRect rr(double x, double y, double w, double h, [double rad = 6]) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(rad));

    // Status bar + title.
    c.drawRRect(rr(u, u * 0.8, u * 2.5, u * 0.5, 3), Paint()..color = ink);
    c.drawRRect(rr(s.width - u * 4, u * 0.8, u * 3, u * 0.5, 3), Paint()..color = ink);
    c.drawRRect(rr(u, u * 2.4, u * 9, u * 1.2, 5), Paint()..color = dark ? Colors.white : const Color(0xFF15161B));

    // Banner card.
    final banner = rr(u, u * 4.4, s.width - u * 2, u * 7, u);
    c.drawRRect(banner, Paint()..color = accent);
    c.drawRRect(rr(u * 2.2, u * 5.8, u * 8, u * 0.9, 4), Paint()..color = Colors.white.withValues(alpha: 0.9));
    c.drawRRect(rr(u * 2.2, u * 7.3, u * 11, u * 0.6, 3), Paint()..color = Colors.white.withValues(alpha: 0.55));
    c.drawRRect(rr(u * 2.2, u * 9, u * 5, u * 1.3, u * 0.65), Paint()..color = Colors.white);

    // List rows.
    var y = u * 13;
    while (y < s.height - u * 5) {
      c.drawCircle(
        Offset(u * 2.2, y + u * 1.1),
        u * 1.1,
        Paint()..color = accent.withValues(alpha: 0.25 + r.nextDouble() * 0.5),
      );
      c.drawRRect(
        rr(u * 4.2, y + u * 0.3, u * (6 + r.nextDouble() * 7), u * 0.7, 3),
        Paint()..color = dark ? const Color(0xFF6B6E7A) : const Color(0xFF3B3D45),
      );
      c.drawRRect(rr(u * 4.2, y + u * 1.4, u * (4 + r.nextDouble() * 9), u * 0.55, 3), Paint()..color = fg);
      y += u * 3.2;
    }

    // Bottom nav.
    c.drawRect(
      Rect.fromLTWH(0, s.height - u * 3.6, s.width, u * 3.6),
      Paint()..color = dark ? const Color(0xFF1A1B21) : Colors.white,
    );
    for (var i = 0; i < 4; i++) {
      c.drawCircle(
        Offset(s.width * (i + 0.5) / 4, s.height - u * 1.8),
        u * 0.55,
        Paint()..color = i == 0 ? accent : ink,
      );
    }
  }

  void _document(Canvas c, Size s, Random r) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFD9D5CE));
    final paper = Rect.fromLTWH(s.width * 0.12, s.height * 0.08, s.width * 0.76, s.height * 0.84);
    c.drawRect(
      paper.shift(const Offset(0, 6)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    c.drawRect(paper, Paint()..color = const Color(0xFFFFFEFA));
    final ink = Paint()..color = const Color(0xFF3B3D45);
    final light = Paint()..color = const Color(0xFFC9CBD1);
    final pad = paper.width * 0.1;
    c.drawRect(Rect.fromLTWH(paper.left + pad, paper.top + pad, paper.width * 0.45, 9), ink);
    var y = paper.top + pad + 28;
    while (y < paper.bottom - pad - 30) {
      final w = (paper.width - pad * 2) * (0.5 + r.nextDouble() * 0.5);
      c.drawRect(Rect.fromLTWH(paper.left + pad, y, w, 4), light);
      c.drawRect(Rect.fromLTWH(paper.right - pad - 26, y, 26, 4), light);
      y += 14;
    }
    c.drawRect(Rect.fromLTWH(paper.left + pad, paper.bottom - pad - 10, paper.width * 0.3, 8), ink);
    c.drawRect(Rect.fromLTWH(paper.right - pad - 40, paper.bottom - pad - 10, 40, 8), ink);
  }
}
