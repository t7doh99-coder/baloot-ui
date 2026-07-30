import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimatedFlameIcon extends StatefulWidget {
  final double size;

  const AnimatedFlameIcon({super.key, this.size = 200});

  @override
  State<AnimatedFlameIcon> createState() => _AnimatedFlameIconState();
}

class _AnimatedFlameIconState extends State<AnimatedFlameIcon>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMicroseconds / 1000000.0;
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double _kf(double p, List<double> stops, List<double> values) {
    for (int i = 0; i < stops.length - 1; i++) {
      if (p >= stops[i] && p <= stops[i + 1]) {
        double t = (p - stops[i]) / (stops[i + 1] - stops[i]);
        return values[i] + (values[i + 1] - values[i]) * t;
      }
    }
    return values.last;
  }

  Widget _buildSvgLayer(String content) {
    const String defs = '''
  <defs>
    <radialGradient id="baseGlow" cx="50%" cy="30%" r="50%">
      <stop offset="0%" stop-color="#fcd34d" stop-opacity="0.9" />
      <stop offset="55%" stop-color="#f97316" stop-opacity="0.45" />
      <stop offset="100%" stop-color="#7f1d1d" stop-opacity="0" />
    </radialGradient>
    <radialGradient id="flameOuter" cx="50%" cy="80%" r="65%">
      <stop offset="0%" stop-color="#f97316" />
      <stop offset="55%" stop-color="#dc2626" />
      <stop offset="100%" stop-color="#7f1d1d" />
    </radialGradient>
    <radialGradient id="flameMid" cx="50%" cy="75%" r="60%">
      <stop offset="0%" stop-color="#fde68a" />
      <stop offset="45%" stop-color="#f97316" />
      <stop offset="100%" stop-color="#c2410c" />
    </radialGradient>
    <radialGradient id="flameInner" cx="50%" cy="70%" r="55%">
      <stop offset="0%" stop-color="#fffbeb" />
      <stop offset="40%" stop-color="#fde68a" />
      <stop offset="100%" stop-color="#f59e0b" />
    </radialGradient>
    <radialGradient id="flameCore" cx="50%" cy="60%" r="50%">
      <stop offset="0%" stop-color="#ffffff" />
      <stop offset="100%" stop-color="#fef3c7" />
    </radialGradient>
  </defs>
''';
    // Removed the flameShadow filter because flutter_svg standard might not support feGaussianBlur,
    // which can cause the SVG rendering to break completely. We will add a shadow via Flutter if needed, 
    // but the core gradients will render perfectly.

    final svgString = '''
<svg viewBox="0 0 160 200" width="160" height="200" xmlns="http://www.w3.org/2000/svg">
$defs
$content
</svg>
''';
    return SvgPicture.string(
      svgString,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Base glow pool ───────────────────────────
    double pGlow = (_time % 1.1) / 1.1;
    double glowOp = _kf(pGlow, const [0, 0.5, 1.0], const [0.65, 0.9, 0.65]);
    double glowSx = _kf(pGlow, const [0, 0.5, 1.0], const [1.0, 1.1, 1.0]);
    double glowSy = _kf(pGlow, const [0, 0.5, 1.0], const [1.0, 1.15, 1.0]);

    // ── Outer flame (flicker) ──────────────────────
    double p1 = (_time % 0.9) / 0.9;
    double sx1 = _kf(p1, const [0, 0.25, 0.5, 0.75, 1.0], const [1.0, 0.93, 1.05, 0.96, 1.0]);
    double sy1 = _kf(p1, const [0, 0.25, 0.5, 0.75, 1.0], const [1.0, 1.04, 0.97, 1.03, 1.0]);
    double ty1 = _kf(p1, const [0, 0.25, 0.5, 0.75, 1.0], const [0.0, -2.0, 1.0, -1.0, 0.0]);

    // ── Mid flame (flicker2) ───────────────────────
    double t2 = (_time - 0.15) % 0.75;
    if (t2 < 0) t2 += 0.75;
    double p2 = t2 / 0.75;
    double sx2 = _kf(p2, const [0, 0.3, 0.6, 1.0], const [1.0, 1.06, 0.94, 1.0]);
    double sy2 = _kf(p2, const [0, 0.3, 0.6, 1.0], const [1.0, 0.95, 1.06, 1.0]);
    double ty2 = _kf(p2, const [0, 0.3, 0.6, 1.0], const [0.0, 2.0, -3.0, 0.0]);

    // ── Inner flame (flicker3) ─────────────────────
    double t3 = (_time - 0.3) % 0.6;
    if (t3 < 0) t3 += 0.6;
    double p3 = t3 / 0.6;
    double sx3 = _kf(p3, const [0, 0.4, 0.7, 1.0], const [1.0, 0.9, 1.08, 1.0]);
    double sy3 = _kf(p3, const [0, 0.4, 0.7, 1.0], const [1.0, 1.08, 0.94, 1.0]);
    double ty3 = _kf(p3, const [0, 0.4, 0.7, 1.0], const [0.0, -4.0, 2.0, 0.0]);

    // ── Core tip (flicker4) ────────────────────────
    double t4 = (_time - 0.1) % 0.5;
    if (t4 < 0) t4 += 0.5;
    double p4 = t4 / 0.5;
    double sy4 = _kf(p4, const [0, 0.5, 1.0], const [1.0, 1.1, 1.0]);
    double ty4 = _kf(p4, const [0, 0.5, 1.0], const [0.0, -5.0, 0.0]);
    double op4 = _kf(p4, const [0, 0.5, 1.0], const [1.0, 0.85, 1.0]);

    // ── Ember particles ────────────────────────────
    double eTime(double delay) {
      double t = (_time - delay) % 1.6;
      if (t < 0) t += 1.6;
      return t / 1.6;
    }

    // Exact original CSS values for embers
    double pe1 = eTime(0.0);
    double e1Tx = _kf(pe1, const [0, 0.6, 1.0], const [0, -8, -12]);
    double e1Ty = _kf(pe1, const [0, 0.6, 1.0], const [0, -55, -90]);
    double e1S = _kf(pe1, const [0, 0.6, 1.0], const [1.0, 0.7, 0.3]);
    double e1Op = _kf(pe1, const [0, 0.6, 1.0], const [0.9, 0.6, 0.0]);

    double pe2 = eTime(0.4);
    double e2Tx = _kf(pe2, const [0, 0.6, 1.0], const [0, 10, 14]);
    double e2Ty = _kf(pe2, const [0, 0.6, 1.0], const [0, -50, -85]);
    double e2S = _kf(pe2, const [0, 0.6, 1.0], const [1.0, 0.6, 0.2]);
    double e2Op = _kf(pe2, const [0, 0.6, 1.0], const [0.8, 0.5, 0.0]);

    double pe3 = eTime(0.8);
    double e3Tx = _kf(pe3, const [0, 0.6, 1.0], const [0, -5, -8]);
    double e3Ty = _kf(pe3, const [0, 0.6, 1.0], const [0, -60, -95]);
    double e3S = _kf(pe3, const [0, 0.6, 1.0], const [0.8, 0.5, 0.2]);
    double e3Op = _kf(pe3, const [0, 0.6, 1.0], const [0.7, 0.4, 0.0]);

    double pe4 = eTime(1.1);
    double e4Tx = _kf(pe4, const [0, 0.6, 1.0], const [0, 7, 10]);
    double e4Ty = _kf(pe4, const [0, 0.6, 1.0], const [0, -48, -82]);
    double e4S = _kf(pe4, const [0, 0.6, 1.0], const [0.9, 0.5, 0.2]);
    double e4Op = _kf(pe4, const [0, 0.6, 1.0], const [0.85, 0.4, 0.0]);

    double pe5 = eTime(1.4);
    double e5Tx = _kf(pe5, const [0, 0.6, 1.0], const [0, -3, -6]);
    double e5Ty = _kf(pe5, const [0, 0.6, 1.0], const [0, -52, -88]);
    double e5S = _kf(pe5, const [0, 0.6, 1.0], const [0.7, 0.4, 0.15]);
    double e5Op = _kf(pe5, const [0, 0.6, 1.0], const [0.75, 0.35, 0.0]);

    // Construct the layers using Transform correctly scaled relative to 160x200 viewBox
    // The width/height ratios give us exact translation mapping.
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Base Glow
          Opacity(
            opacity: glowOp,
            child: Transform(
              alignment: const FractionalOffset(80 / 160, 175 / 200), // origin: 80 175
              transform: Matrix4.identity()..scale(glowSx, glowSy),
              child: _buildSvgLayer('<ellipse cx="80" cy="175" rx="52" ry="18" fill="url(#baseGlow)" />'),
            ),
          ),
          // Outer Flame
          Transform(
            alignment: const FractionalOffset(80 / 160, 170 / 200), // origin: 80 170
            transform: Matrix4.identity()..translate(0.0, ty1)..scale(sx1, sy1),
            child: _buildSvgLayer('<path d="M80 22 C 80 22 112 55 118 88 C 124 118 116 140 108 155 C 100 168 88 174 80 174 C 72 174 60 168 52 155 C 44 140 36 118 42 88 C 48 55 80 22 80 22 Z" fill="url(#flameOuter)" />'),
          ),
          // Mid Flame
          Transform(
            alignment: const FractionalOffset(80 / 160, 165 / 200), // origin: 80 165
            transform: Matrix4.identity()..translate(0.0, ty2)..scale(sx2, sy2),
            child: _buildSvgLayer('<path d="M80 42 C 80 42 104 70 109 97 C 114 122 108 142 101 154 C 95 164 87 169 80 169 C 73 169 65 164 59 154 C 52 142 46 122 51 97 C 56 70 80 42 80 42 Z" fill="url(#flameMid)" />'),
          ),
          // Inner Flame
          Transform(
            alignment: const FractionalOffset(80 / 160, 160 / 200), // origin: 80 160
            transform: Matrix4.identity()..translate(0.0, ty3)..scale(sx3, sy3),
            child: _buildSvgLayer('<path d="M80 62 C 80 62 97 83 101 105 C 105 125 101 143 96 153 C 91 162 85 166 80 166 C 75 166 69 162 64 153 C 59 143 55 125 59 105 C 63 83 80 62 80 62 Z" fill="url(#flameInner)" />'),
          ),
          // Core Flame
          Opacity(
            opacity: op4,
            child: Transform(
              alignment: const FractionalOffset(80 / 160, 155 / 200), // origin: 80 155
              transform: Matrix4.identity()..translate(0.0, ty4)..scale(1.0, sy4),
              child: _buildSvgLayer('<path d="M80 78 C 80 78 90 95 92 112 C 94 128 90 144 85 153 C 83 158 81 161 80 162 C 79 161 77 158 75 153 C 70 144 66 128 68 112 C 70 95 80 78 80 78 Z" fill="url(#flameCore)" />'),
            ),
          ),
          // Embers
          Opacity(
            opacity: e1Op,
            child: Transform(
              alignment: const FractionalOffset(72 / 160, 155 / 200),
              transform: Matrix4.identity()..translate(e1Tx, e1Ty)..scale(e1S, e1S),
              child: _buildSvgLayer('<circle cx="72" cy="155" r="3.5" fill="#FCD34D" />'),
            ),
          ),
          Opacity(
            opacity: e2Op,
            child: Transform(
              alignment: const FractionalOffset(88 / 160, 148 / 200),
              transform: Matrix4.identity()..translate(e2Tx, e2Ty)..scale(e2S, e2S),
              child: _buildSvgLayer('<circle cx="88" cy="148" r="3" fill="#FCA5A5" />'),
            ),
          ),
          Opacity(
            opacity: e3Op,
            child: Transform(
              alignment: const FractionalOffset(76 / 160, 152 / 200),
              transform: Matrix4.identity()..translate(e3Tx, e3Ty)..scale(e3S, e3S),
              child: _buildSvgLayer('<circle cx="76" cy="152" r="2.5" fill="#FDE68A" />'),
            ),
          ),
          Opacity(
            opacity: e4Op,
            child: Transform(
              alignment: const FractionalOffset(85 / 160, 158 / 200),
              transform: Matrix4.identity()..translate(e4Tx, e4Ty)..scale(e4S, e4S),
              child: _buildSvgLayer('<circle cx="85" cy="158" r="2" fill="#FCD34D" />'),
            ),
          ),
          Opacity(
            opacity: e5Op,
            child: Transform(
              alignment: const FractionalOffset(80 / 160, 145 / 200),
              transform: Matrix4.identity()..translate(e5Tx, e5Ty)..scale(e5S, e5S),
              child: _buildSvgLayer('<circle cx="80" cy="145" r="2" fill="#FB923C" />'),
            ),
          ),
        ],
      ),
    );
  }
}
