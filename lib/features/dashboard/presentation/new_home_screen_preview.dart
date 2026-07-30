import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/rank_calculator.dart';
import '../../../data/models/rank_tier.dart';
import '../../game/presentation/game_provider.dart';
import '../../game/presentation/game_table_screen.dart';

// ══════════════════════════════════════════════════════════════════
//  TEST 1 — Gold / Purple Baloot Home Screen
//  Fully translated from BalootHome.tsx (test 1 Figma)
// ══════════════════════════════════════════════════════════════════

// ── Design tokens ────────────────────────────────────────────────
const _kG   = Color(0xFFFFD700);
const _kGL  = Color(0xFFFFE44D);
const _kGD  = Color(0xFFC9A84C);
const _kGX  = Color(0xFFB8860B);
const _kCYN = Color(0xFF00F5FF);
const _kRED = Color(0xFFFF2244);
const _kGRN = Color(0xFF00C853);
const _kBG  = Color(0xFF1A0A2E);

// ══════════════════════════════════════════════════════════════════
//  Particle model
// ══════════════════════════════════════════════════════════════════
class _Pt {
  double x, y, vx, vy, r, a, da;
  Color c;
  _Pt({required this.x, required this.y, required this.vx, required this.vy,
       required this.r, required this.a, required this.da, required this.c});
}

// ══════════════════════════════════════════════════════════════════
//  Ripple ring data
// ══════════════════════════════════════════════════════════════════
class _Ripple {
  final int id;
  final AnimationController ctrl;
  _Ripple({required this.id, required this.ctrl});
}

// ══════════════════════════════════════════════════════════════════
//  Main widget
// ══════════════════════════════════════════════════════════════════
class NewHomeScreenPreview extends StatefulWidget {
  final bool isArabic;
  const NewHomeScreenPreview({super.key, this.isArabic = false});

  @override
  State<NewHomeScreenPreview> createState() => _NewHomeScreenPreviewState();
}

class _NewHomeScreenPreviewState extends State<NewHomeScreenPreview>
    with TickerProviderStateMixin {

  // ── Animation controllers ──────────────────────────────────────
  late AnimationController _particlesCtrl;   // 60fps particle tick
  late AnimationController _avatarRingCtrl;  // 9s rotating conic ring
  late AnimationController _avatarFloatCtrl; // 3.2s float up/down
  late AnimationController _xpFillCtrl;      // 1.4s XP bar fill
  late AnimationController _xpStarCtrl;      // XP star spring pop
  late AnimationController _cardGlowCtrl;    // 3.2s card edge glow
  late AnimationController _vipPulseCtrl;    // 1.8s VIP badge pulse
  late AnimationController _onlineDotCtrl;   // 1.6s online dot pulse
  late AnimationController _streakCtrl;      // 4s streak flicker
  late AnimationController _coinFloatCtrl;   // 2.4s coin float
  late AnimationController _shimmerCtrl;     // 5.5s shimmer overlay
  late AnimationController _goldTextCtrl;    // 3s gold shimmer text
  late AnimationController _tournamentCtrl;  // 2.5s tournament glow
  late AnimationController _playOuterCtrl;   // 11s outer ring
  late AnimationController _playInnerCtrl;   // 18s inner ring counter-rotate
  late List<AnimationController> _fireCtrl;  // 5 fire flames
  late AnimationController _fireBurstCtrl;   // 500ms fire burst when tapped
  late AnimationController _searchDotsCtrl;  // 900ms search dots loop
  late AnimationController _playGlowCtrl;    // 2.2s play button glow pulse

  // ── Play button state ─────────────────────────────────────────
  bool _searching = false;
  bool _showFlash = false;
  bool _pressed = false;
  bool _fireBurst = false;
  final List<_Ripple> _ripples = [];
  int _rippleId = 0;

  // ── Nav ───────────────────────────────────────────────────────
  String _activeTab = 'home';

  // ── Particles ─────────────────────────────────────────────────
  final List<_Pt> _pts = [];
  final Random _rng = Random();
  bool _ptsReady = false;

  // ── XP star visible ───────────────────────────────────────────
  bool _starVisible = false;

  @override
  void initState() {
    super.initState();

    _particlesCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..repeat();

    _avatarRingCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat();

    _avatarFloatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);

    _xpFillCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _xpStarCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));

    _cardGlowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);

    _vipPulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _onlineDotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);

    _streakCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    _coinFloatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);

    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5500))
      ..repeat();

    _goldTextCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();

    _tournamentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat(reverse: true);

    _playOuterCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 11))
      ..repeat();

    _playInnerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 18))
      ..repeat();

    // 5 fire flame animations — staggered durations
    _fireCtrl = List.generate(5, (i) {
      final ms = (880 + i * 90);
      return AnimationController(vsync: this, duration: Duration(milliseconds: ms))
        ..repeat(reverse: true);
    });

    _fireBurstCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _searchDotsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();

    _playGlowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);

    // Delayed starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initParticles();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _xpFillCtrl.forward();
      });
      Future.delayed(const Duration(milliseconds: 1900), () {
        if (mounted) setState(() => _starVisible = true);
        if (mounted) _xpStarCtrl.forward();
      });
    });
  }

  void _initParticles() {
    final s = MediaQuery.of(context).size;
    const cols = [_kG, _kCYN, Color(0xFFF5C518), _kGD, Colors.white70, Color(0xFFBB66FF)];
    _pts.clear();
    for (int i = 0; i < 60; i++) {
      _pts.add(_Pt(
        x: _rng.nextDouble() * s.width,
        y: _rng.nextDouble() * s.height,
        vx: (_rng.nextDouble() - 0.5) * 0.28,
        vy: -(_rng.nextDouble() * 0.32 + 0.06),
        r: _rng.nextDouble() * 1.6 + 0.4,
        a: _rng.nextDouble(),
        da: (_rng.nextDouble() * 0.006 + 0.003) * (_rng.nextBool() ? 1 : -1),
        c: cols[_rng.nextInt(cols.length)],
      ));
    }
    setState(() => _ptsReady = true);
  }

  void _tickParticles(double w, double h) {
    for (final p in _pts) {
      p.x += p.vx; p.y += p.vy;
      p.a += p.da;
      if (p.a >= 1 || p.a <= 0) p.da = -p.da;
      if (p.y < -4) { p.y = h + 4; p.x = _rng.nextDouble() * w; }
      if (p.x < -4 || p.x > w + 4) p.vx = -p.vx;
    }
  }

  @override
  void dispose() {
    _particlesCtrl.dispose();
    _avatarRingCtrl.dispose();
    _avatarFloatCtrl.dispose();
    _xpFillCtrl.dispose();
    _xpStarCtrl.dispose();
    _cardGlowCtrl.dispose();
    _vipPulseCtrl.dispose();
    _onlineDotCtrl.dispose();
    _streakCtrl.dispose();
    _coinFloatCtrl.dispose();
    _shimmerCtrl.dispose();
    _goldTextCtrl.dispose();
    _tournamentCtrl.dispose();
    _playOuterCtrl.dispose();
    _playInnerCtrl.dispose();
    for (final c in _fireCtrl) { c.dispose(); }
    for (final r in _ripples) { r.ctrl.dispose(); }
    _fireBurstCtrl.dispose();
    _searchDotsCtrl.dispose();
    _playGlowCtrl.dispose();
    super.dispose();
  }

  // ── Play button logic ─────────────────────────────────────────
  void _handlePlay() {
    if (_searching) return;

    // Ripple
    final id = _rippleId++;
    final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 720));
    setState(() => _ripples.add(_Ripple(id: id, ctrl: ctrl)));
    ctrl.forward().then((_) {
      if (mounted) {
        setState(() => _ripples.removeWhere((r) => r.id == id));
        ctrl.dispose();
      }
    });

    // Flash
    setState(() => _showFlash = true);
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) setState(() => _showFlash = false);
    });

    // Fire Burst
    setState(() => _fireBurst = true);
    _fireBurstCtrl.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _fireBurst = false);
    });

    // Fast spin
    _playOuterCtrl.duration = const Duration(milliseconds: 1200);
    _playOuterCtrl.repeat();
    _playInnerCtrl.duration = const Duration(milliseconds: 2200);
    _playInnerCtrl.repeat();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        _playOuterCtrl.duration = const Duration(seconds: 11);
        _playOuterCtrl.repeat();
        _playInnerCtrl.duration = const Duration(seconds: 18);
        _playInnerCtrl.repeat();
      }
    });

    // Searching & Pressed scale
    setState(() {
      _searching = true;
      _pressed = true;
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _searching = false;
          _pressed = false;
        });
      }
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _kBG,
        body: LayoutBuilder(builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              // ── Background layers ──
              Positioned.fill(child: CustomPaint(painter: _NebulaPainter())),
              Positioned.fill(child: CustomPaint(painter: _GridPainter())),
              // Particles
              if (_ptsReady)
                AnimatedBuilder(
                  animation: _particlesCtrl,
                  builder: (_, __) {
                    _tickParticles(w, h);
                    return CustomPaint(painter: _ParticlesPainter(_pts));
                  },
                ),

              // ── Scrollable content ──
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildTopBar(),
                          _buildPlayerCard(),
                          _buildPlayHub(),
                          _buildTournamentBanner(),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomNav(),
                ],
              ),

              // ── Green flash overlay ──
              if (_showFlash)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(color: const Color(0x23008053)),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  TOP BAR
  // ══════════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 48, 14, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFA060210), Color(0xB21A0A2E)],
        ),
        border: Border(bottom: BorderSide(color: Color(0x1AFFD700))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
          // Right side buttons (RTL: right = start)
          Positioned(
            right: 0,
            child: Row(
              children: [
                _topBarBtn(em: '🔔', lbl: widget.isArabic ? 'الإشعارات' : 'Alerts', badge: '7'),
                const SizedBox(width: 8),
                _topBarBtn(em: '👥', lbl: widget.isArabic ? 'الأصدقاء' : 'Friends'),
              ],
            ),
          ),
          // Center: suits + shimmer title
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(4, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Text(
                    const ['♠', '♥', '♣', '♦'][i],
                    style: TextStyle(
                      fontSize: 10,
                      color: i.isEven ? const Color(0xA5FFD700) : const Color(0xA5FF5050),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 2),
              _goldShimmerText(widget.isArabic ? 'بلوت' : 'Baloot', fontSize: 28, letterSpacing: 2),
            ],
          ),
          // Left side buttons (RTL: left = end)
          Positioned(
            left: 0,
            child: Row(
              children: [
                _topBarBtn(em: '🃏', lbl: widget.isArabic ? 'بلوت' : 'Baloot'),
                const SizedBox(width: 8),
                _topBarBtn(em: '☰', lbl: widget.isArabic ? 'المزيد' : 'More'),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _topBarBtn({required String em, required String lbl, String? badge}) {
    return GestureDetector(
      onTap: () {},
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xD92C0C58), Color(0xEB140620)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x33FFD700)),
              boxShadow: const [
                BoxShadow(color: Color(0x72000000), blurRadius: 14, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(em, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 2),
                Text(lbl, style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xCCFFD700))),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -5, right: -5,
              child: Container(
                width: 17, height: 17,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFFFF2244), Color(0xFFAA001A)]),
                  boxShadow: [BoxShadow(color: Color(0xE5FF2244), blurRadius: 10)],
                ),
                alignment: Alignment.center,
                child: Text(badge, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Gold shimmer text ─────────────────────────────────────────
  Widget _goldShimmerText(String text, {required double fontSize, double letterSpacing = 0}) {
    return AnimatedBuilder(
      animation: _goldTextCtrl,
      builder: (_, __) {
        // Shift gradient from -1 to +3 over the animation
        final t = _goldTextCtrl.value;
        final begin = -1.0 + t * 4.0;
        final end = begin + 2.0;
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(begin, 0), end: Alignment(end, 0),
            colors: const [Color(0xFFC9A84C), Color(0xFFFFD700), Color(0xFFFFFBE0), Color(0xFFFFD700), Color(0xFFC9A84C)],
            stops: const [0.0, 0.22, 0.5, 0.78, 1.0],
          ).createShader(bounds),
          child: Text(text, style: GoogleFonts.cairo(
            fontSize: fontSize, fontWeight: FontWeight.w900, letterSpacing: letterSpacing, color: Colors.white,
          )),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  PLAYER CARD
  // ══════════════════════════════════════════════════════════════
  Widget _buildPlayerCard() {
    return AnimatedBuilder(
      animation: _cardGlowCtrl,
      builder: (_, child) {
        final glow = 22.0 + _cardGlowCtrl.value * 16.0;
        final innerAlpha = (0.13 + _cardGlowCtrl.value * 0.15).clamp(0.0, 1.0);
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xEB2A0C52), Color(0xF70F0526)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x38FFD700)),
            boxShadow: [
              const BoxShadow(color: Color(0x8C000000), blurRadius: 44, offset: Offset(0, 14)),
              BoxShadow(color: Color.fromARGB((innerAlpha * 255).round(), 255, 215, 0), blurRadius: glow),
              const BoxShadow(color: Color(0x8C000000), blurRadius: 1, offset: Offset(0, 0), spreadRadius: 1),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Card shimmer overlay
            AnimatedBuilder(
              animation: _shimmerCtrl,
              builder: (_, __) {
                final tx = (_shimmerCtrl.value * 2.0 - 0.5);
                return Positioned.fill(
                  child: Align(
                    alignment: Alignment(tx * 2 - 1, 0),
                    child: FractionallySizedBox(
                      widthFactor: 0.55,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0x0EFFD700), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Top seam
            Positioned(
              top: 0, left: 40, right: 40, height: 1,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0x80FFD700), Colors.transparent],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCurrencyBar(context),
                  const SizedBox(height: 13),
                  _buildPlayerRow1(context),
                  const SizedBox(height: 14),
                  _buildPlayerRow2(context),
                  const SizedBox(height: 14),
                  _buildXPBar(context),
                  const SizedBox(height: 14),
                  _buildSubscribeCTA(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Currency bar ──────────────────────────────────────────────
  Widget _buildCurrencyBar(BuildContext context) {
    final game = context.watch<GameProvider>();
    final stats = game.playerStats;
    final items = [
      (em: '💰', val: '${stats.blueStars}', color: _kG,   glow: const Color(0x80FFD700)),
      (em: '💎', val: '0',    color: _kCYN, glow: const Color(0x8000F5FF)),
      (em: '❤️', val: '0',     color: const Color(0xFFFF4466), glow: const Color(0x80FF2244)),
    ];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x12FFD700),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x2EFFD700)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Expanded(
            child: Row(
              children: [
                if (i > 0) Container(width: 1, height: 36, color: const Color(0x26FFD700)),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _coinFloatCtrl,
                    builder: (_, __) {
                      final dy = sin((_coinFloatCtrl.value + i * 0.3) * pi) * -2.0;
                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item.em, style: TextStyle(fontSize: 15, shadows: [Shadow(color: item.glow, blurRadius: 4)])),
                              const SizedBox(width: 6),
                              Text(item.val, style: GoogleFonts.cairo(
                                fontSize: 12, fontWeight: FontWeight.w800, color: item.color,
                                shadows: [Shadow(color: item.glow, blurRadius: 8)],
                              )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Player row 1: VIP | Name | Chest+Win ─────────────────────
  Widget _buildPlayerRow1(BuildContext context) {
    final stats = context.watch<GameProvider>().playerStats;
    return Row(
      children: [
        // VIP badge
        AnimatedBuilder(
          animation: _vipPulseCtrl,
          builder: (_, __) {
            final glow = 8.0 + _vipPulseCtrl.value * 30.0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF2244), Color(0xFFAA001A)]),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x4CFF6464)),
                boxShadow: [
                  BoxShadow(color: const Color(0xE5FF2244), blurRadius: glow),
                  const BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('👑', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text(widget.isArabic ? 'غير مشترك' : 'Free Tier', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            );
          },
        ),
        // Name + online
        Expanded(
          child: Column(
            children: [
              Text(stats.playerName, style: GoogleFonts.cairo(
                fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white,
                shadows: const [Shadow(color: Color(0x40FFD700), blurRadius: 14)],
              )),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _onlineDotCtrl,
                    builder: (_, __) {
                      final scale = 1.0 + _onlineDotCtrl.value * 0.15;
                      final glowSize = _onlineDotCtrl.value * 4.0;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, color: _kGRN,
                            boxShadow: [BoxShadow(color: _kGRN.withValues(alpha: 0.7), blurRadius: glowSize, spreadRadius: glowSize * 0.25)],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(widget.isArabic ? '1,240 متصل' : '1,240 Online', style: GoogleFonts.cairo(fontSize: 9.5, color: Colors.white38)),
                ],
              ),
            ],
          ),
        ),
        // Chest + Win
        Row(
          children: [
            _chestBtn(),
            const SizedBox(width: 7),
            _winBtn(),
          ],
        ),
      ],
    );
  }

  Widget _chestBtn() {
    return GestureDetector(
      onTap: () {},
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xE5320F5A), Color(0xF514052D)]),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0x52FFD700)),
              boxShadow: const [BoxShadow(color: Color(0x72000000), blurRadius: 12, offset: Offset(0, 5))],
            ),
            child: const Text('🎁', style: TextStyle(fontSize: 20)),
          ),
          Positioned(
            top: -5, right: -5,
            child: Container(
              width: 16, height: 16,
              decoration: const BoxDecoration(
                shape: BoxShape.circle, color: _kRED,
                boxShadow: [BoxShadow(color: Color(0xD9FF2244), blurRadius: 9)],
              ),
              alignment: Alignment.center,
              child: const Text('+', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _winBtn() {
    return GestureDetector(
      onTap: () {},
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [_kGL, _kG, _kGD, _kGX], stops: [0, 0.40, 0.78, 1]),
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(color: Color(0x61FFD700), blurRadius: 18),
                BoxShadow(color: Color(0x80000000), blurRadius: 14, offset: Offset(0, 5)),
              ],
            ),
            child: Text(widget.isArabic ? 'اربح' : 'Win', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF0A0A0A))),
          ),
          Positioned(
            top: -6, right: -6,
            child: Container(
              width: 17, height: 17,
              decoration: const BoxDecoration(
                shape: BoxShape.circle, color: _kCYN,
                boxShadow: [BoxShadow(color: _kCYN, blurRadius: 12)],
              ),
              alignment: Alignment.center,
              child: const Text('2', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF0A0A0A))),
            ),
          ),
        ],
      ),
    );
  }

  // ── Player row 2: chips | avatar | chips ─────────────────────
  Widget _buildPlayerRow2(BuildContext context) {
    final game = context.watch<GameProvider>();
    final stats = game.playerStats;
    final rank = game.playerRank;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left chips
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _chip(em: '❤️', val: '20', accent: const Color(0xFFFF4466)),
              const SizedBox(height: 7),
              _chip(em: '🥇', val: '${stats.medals}', accent: _kG),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Avatar column
        Column(
          children: [
            _buildAvatarFrame(),
            const SizedBox(height: 6),
            _buildRankBadge(widget.isArabic ? rank.arabicName : rank.englishName),
            const SizedBox(height: 6),
            _buildWinStreak(stats.currentWinStreak),
          ],
        ),
        const SizedBox(width: 10),
        // Right chips
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _chip(em: '⭐', val: '0', accent: _kCYN),
              const SizedBox(height: 7),
              _chip(em: '🌟', val: '0', accent: _kG),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip({required String em, required String val, required Color accent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3, height: 20,
            decoration: BoxDecoration(
              color: accent, borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: accent, blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 8),
          Text(em, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(val, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  // ── Avatar frame ──────────────────────────────────────────────
  Widget _buildAvatarFrame() {
    return SizedBox(
      width: 108, height: 108,
      child: Stack(
        children: [
          // Outer rotating conic ring
          AnimatedBuilder(
            animation: _avatarRingCtrl,
            builder: (_, __) {
              return Transform.rotate(
                angle: _avatarRingCtrl.value * 2 * pi,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [_kG, Colors.transparent, _kGD, Colors.transparent, _kG, Colors.transparent, _kGL, _kG],
                      stops: [0, 0.153, 0.333, 0.486, 0.639, 0.792, 0.944, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          // Dark gap
          Positioned(top: 3, left: 3, right: 3, bottom: 3,
            child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: _kBG))),
          // Inner gold ring
          Positioned(top: 6, left: 6, right: 6, bottom: 6,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x8CFFD700), width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x66FFD700), blurRadius: 18),
                  BoxShadow(color: Color(0x1AFFD700), blurRadius: 0, spreadRadius: 5),
                ],
              ),
            ),
          ),
          // Avatar face — floating
          AnimatedBuilder(
            animation: _avatarFloatCtrl,
            builder: (_, __) {
              final dy = (_avatarFloatCtrl.value * 2 - 1) * -5.0;
              return Positioned(
                top: 11 + dy, left: 11, right: 11, bottom: 11,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF3C0072), Color(0xFF1A0A2E), Color(0xFF0D0520)],
                      stops: [0, 0.6, 1],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      // Specular
                      Positioned(top: 8, left: 12,
                        child: Container(
                          width: 30, height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      const Center(child: Text('👤', style: TextStyle(fontSize: 44))),
                    ],
                  ),
                ),
              );
            },
          ),
          // Online dot
          AnimatedBuilder(
            animation: _onlineDotCtrl,
            builder: (_, __) {
              final scale = 1.0 + _onlineDotCtrl.value * 0.15;
              final glow = _onlineDotCtrl.value * 4.0;
              return Positioned(
                bottom: 8, right: 4,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: _kGRN,
                      border: Border.all(color: _kBG, width: 2.5),
                      boxShadow: [BoxShadow(color: _kGRN.withValues(alpha: 0.7), blurRadius: glow, spreadRadius: 1)],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Rank badge ────────────────────────────────────────────────
  Widget _buildRankBadge(String rank) {
    Color color; Color bg;
    if (rank == 'خبير' || rank == 'Expert') {
      color = _kG; bg = const Color(0xFF372800);
    } else if (rank == 'محترف' || rank == 'Pro') {
      color = _kCYN; bg = const Color(0xFF002837);
    } else if (rank == 'أسطورة' || rank == 'Legend') {
      color = _kRED; bg = const Color(0xFF370010);
    } else {
      color = _kGRN; bg = const Color(0xFF003716);
    }
    return ClipPath(
      clipper: _HexClipper(),
      child: Container(
        width: 72, height: 30, color: bg,
        alignment: Alignment.center,
        child: Text(
          '✦ $rank',
          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w900, color: color,
            shadows: [Shadow(color: color.withValues(alpha: 0.7), blurRadius: 8)]),
        ),
      ),
    );
  }

  // ── Win streak ────────────────────────────────────────────────
  Widget _buildWinStreak(int count) {
    if (count <= 0) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _streakCtrl,
      builder: (_, __) {
        final v = _streakCtrl.value;
        final opacity = (v > 0.9 && v < 0.94) || v > 0.97 ? 0.65 : 1.0;
        return Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0x38FF5000), Color(0x26FFA000)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x66FF8C00)),
              boxShadow: const [BoxShadow(color: Color(0x4DFF6400), blurRadius: 10)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Text(widget.isArabic ? '$count انتصارات' : '$count Wins', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFFF8C00))),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── XP bar ────────────────────────────────────────────────────
  Widget _buildXPBar(BuildContext context) {
    final game = context.watch<GameProvider>();
    final stats = game.playerStats;
    final rank = game.playerRank;
    
    // Get next threshold
    int currentThreshold = 0;
    int nextThreshold = 5000;
    for (int i = 0; i < RankCalculator.rankOrder.length; i++) {
      final r = RankCalculator.rankOrder[i];
      if (stats.medals >= RankCalculator.rankThresholds[r]!) {
        currentThreshold = RankCalculator.rankThresholds[r]!;
        if (i < RankCalculator.rankOrder.length - 1) {
          nextThreshold = RankCalculator.rankThresholds[RankCalculator.rankOrder[i + 1]]!;
        } else {
          nextThreshold = currentThreshold + 5000;
        }
      }
    }
    
    final progress = (stats.medals - currentThreshold) / (nextThreshold - currentThreshold);
    final isMax = rank.subLevel == 5 && rank.mainRank == MainRank.professional;
    final progressValue = isMax ? 1.0 : progress.clamp(0.0, 1.0);
    final targetPct = CurvedAnimation(parent: _xpFillCtrl, curve: Curves.easeOut).value * progressValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kG, _kGD]),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Color(0x72FFD700), blurRadius: 10)],
              ),
              child: Text(widget.isArabic ? rank.arabicName : rank.englishName, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF0A0A0A))),
            ),
            Text(isMax ? 'Max Rank' : '${stats.medals} / $nextThreshold XP', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0x8CFFD700))),
          ],
        ),
        const SizedBox(height: 5),
        // Bar track + fill
        LayoutBuilder(
          builder: (ctx, cst) {
            final trackWidth = cst.maxWidth;
            return Stack(
              children: [
                // Track
                Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0x24FFD700)),
                  ),
                ),
                // Animated fill
                AnimatedBuilder(
                  animation: _xpFillCtrl,
                  builder: (_, __) {
                    final pct = targetPct;
                    return Container(
                      width: trackWidth * pct,
                      height: 9,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kGD, _kG, _kGL]),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: const [BoxShadow(color: Color(0xB2FFD700), blurRadius: 12)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: AnimatedBuilder(
                          animation: _shimmerCtrl,
                          builder: (_, __) {
                            final tx = _shimmerCtrl.value * 5.0 - 1.0;
                            return FractionalTranslation(
                              translation: Offset(tx, 0),
                              child: FractionallySizedBox(
                                widthFactor: 0.3,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.transparent, Color(0x8CFFFFFF), Colors.transparent],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                // Star at end of fill
                if (_starVisible)
                  AnimatedBuilder(
                    animation: _xpStarCtrl,
                    builder: (_, __) {
                      final scale = _SpringCurve().transform(_xpStarCtrl.value);
                      return Positioned(
                        left: trackWidth * targetPct - 8,
                        top: -3,
                        child: Transform.scale(
                          scale: scale,
                          child: Text('✦', style: GoogleFonts.cairo(
                            fontSize: 14, color: _kG,
                            shadows: const [Shadow(color: _kG, blurRadius: 6)],
                          )),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ── Subscribe CTA ─────────────────────────────────────────────
  Widget _buildSubscribeCTA() {
    return Center(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_kGL, _kG, _kGD, _kGX], stops: [0, 0.35, 0.70, 1],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(color: Color(0x6BFFD700), blurRadius: 26),
              BoxShadow(color: Color(0x7A000000), blurRadius: 20, offset: Offset(0, 7)),
            ],
          ),
          child: Text(widget.isArabic ? '👑 احصل على VIP الآن' : '👑 Get VIP Now',
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0A0A0A))),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  PLAY HUB
  // ══════════════════════════════════════════════════════════════
  Widget _buildPlayHub() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xEB2E0C56), Color(0xF7120628)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x38FFD700)),
        boxShadow: const [BoxShadow(color: Color(0x8C000000), blurRadius: 44, offset: Offset(0, 14))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left buttons
          Expanded(
            child: Column(
              children: [
                _gameBtn(em: '🎙️', lbl: widget.isArabic ? 'جلسة صوتية' : 'Voice Room', glow: _kCYN),
                const SizedBox(height: 12),
                _gameBtn(em: '➕', lbl: widget.isArabic ? 'إنشاء جلسة' : 'Create Room', glow: _kG),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Center: PLAY
          _buildPlayButton(),
          const SizedBox(width: 12),
          // Right buttons
          Expanded(
            child: Column(
              children: [
                _gameBtn(em: '🤝', lbl: widget.isArabic ? 'لعبة ودية' : 'Friendly Match', glow: _kCYN),
                const SizedBox(height: 12),
                _gameBtn(em: '📋', lbl: widget.isArabic ? 'قائمة الجلسات' : 'Room List', glow: _kG),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameBtn({required String em, required String lbl, required Color glow}) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xEB2E0C56), Color(0xF7120628)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x42FFD700)),
          boxShadow: const [
            BoxShadow(color: Color(0x6B000000), blurRadius: 22, offset: Offset(0, 7)),
            BoxShadow(color: Color(0x1AFFD700), blurRadius: 0),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(em, style: TextStyle(fontSize: 22, shadows: [Shadow(color: glow.withValues(alpha: 0.4), blurRadius: 8)])),
            const SizedBox(height: 6),
            Text(lbl, textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xE0FFD700), height: 1.3)),
          ],
        ),
      ),
    );
  }

  // ── PLAY button ───────────────────────────────────────────────
  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _handlePlay,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFireRow(),
          const SizedBox(height: 8),
          SizedBox(
            width: 160, height: 160,
            child: Stack(
              children: [
                // Ripple rings
                ..._ripples.map((r) => _buildRippleRing(r)),
                // Outer rotating ring
                AnimatedBuilder(
                  animation: _playOuterCtrl,
                  builder: (_, __) {
                    return Transform.rotate(
                      angle: _playOuterCtrl.value * 2 * pi,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Colors.transparent, Color(0xA500C853), Colors.transparent,
                              Color(0x61FFD700), Colors.transparent, Color(0xA500C853),
                              Colors.transparent, Colors.transparent,
                            ],
                            stops: [0, 0.153, 0.306, 0.458, 0.611, 0.778, 0.931, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Dark gap 1
                Positioned(top: 5, left: 5, right: 5, bottom: 5,
                  child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFA080312)))),
                // Inner ring (counter-rotate)
                Positioned(top: 8, left: 8, right: 8, bottom: 8,
                  child: AnimatedBuilder(
                    animation: _playInnerCtrl,
                    builder: (_, __) {
                      return Transform.rotate(
                        angle: -_playInnerCtrl.value * 2 * pi,
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Colors.transparent, Color(0x59FFD700), Colors.transparent,
                                Colors.transparent, Color(0x59FFD700), Colors.transparent, Colors.transparent,
                              ],
                              stops: [0, 0.111, 0.222, 0.722, 0.833, 0.944, 1.0],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Dark gap 2
                Positioned(top: 12, left: 12, right: 12, bottom: 12,
                  child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFA080312)))),
                // Core button
                Positioned(top: 15, left: 15, right: 15, bottom: 15,
                  child: _buildPlayCore()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFireRow() {
    const sizes = [14.0, 18.0, 23.0, 18.0, 14.0];
    return SizedBox(
      height: 28,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(sizes.length, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: AnimatedBuilder(
              animation: _fireBurst ? _fireBurstCtrl : _fireCtrl[i],
              builder: (_, __) {
                if (_fireBurst) {
                  final val = _fireBurstCtrl.value;
                  final dy = -38.0 * val;
                  final scale = 1.0 + 0.7 * val;
                  final opacity = (1.0 - val).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, dy),
                      child: Transform.scale(
                        scale: scale,
                        child: Text('🔥', style: TextStyle(fontSize: sizes[i], height: 1)),
                      ),
                    ),
                  );
                } else {
                  final t = sin(_fireCtrl[i].value * pi);
                  final dy = -t * sizes[i] * 0.32;
                  final scale = 1.0 + t * 0.18;
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: Transform.scale(
                      scale: scale,
                      child: Text('🔥', style: TextStyle(fontSize: sizes[i], height: 1)),
                    ),
                  );
                }
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRippleRing(_Ripple ripple) {
    final idx = _ripples.indexOf(ripple);
    const borderColors = [Color(0xB200C853), Color(0x8000F5FF), Color(0x66FFD700)];
    final bc = borderColors[idx.clamp(0, borderColors.length - 1)];
    return AnimatedBuilder(
      animation: ripple.ctrl,
      builder: (_, __) {
        final t = CurvedAnimation(parent: ripple.ctrl, curve: Curves.easeOut).value;
        final scale = 1.0 + t * 1.6;
        final opacity = (1.0 - t).clamp(0.0, 0.8);
        return Positioned.fill(
          child: Transform.scale(
            scale: scale,
            child: Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: bc.withValues(alpha: opacity), width: 2.5),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayCore() {
    return AnimatedScale(
      scale: _pressed ? 0.86 : 1.0,
      duration: Duration(milliseconds: _pressed ? 80 : 300),
      curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
      child: AnimatedBuilder(
        animation: _playGlowCtrl,
        builder: (context, child) {
          final t = _playGlowCtrl.value;
          final blur1 = 22.0 + t * 14.0;
          final blur2 = 50.0 + t * 22.0;
          final blur3 = 90.0 + t * 30.0;
          
          final opacity1 = 0.65 + t * 0.3;
          final opacity2 = 0.35 + t * 0.25;
          final opacity3 = 0.15 + t * 0.13;
          
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.28, -0.4),
                colors: [Color(0xFF44FF88), Color(0xFF00C853), Color(0xFF006830), Color(0xFF002E15)],
                stops: [0, 0.42, 0.8, 1],
              ),
              border: Border.all(color: const Color(0x6100FF64), width: 2),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00C853).withValues(alpha: opacity1), blurRadius: blur1),
                BoxShadow(color: const Color(0xFF00C853).withValues(alpha: opacity2), blurRadius: blur2),
                BoxShadow(color: const Color(0xFF00C853).withValues(alpha: opacity3), blurRadius: blur3),
                if (t > 0.1)
                  BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: (t * 0.25).clamp(0.0, 0.25)), blurRadius: t * 10.0),
              ],
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Specular
            Positioned(top: 10, left: 14,
              child: Container(
                width: 42, height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
            ),
            // Inner ring line
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),
            // Label
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _searching ? _searchingLabel() : _playLabel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playLabel() {
    return Column(
      key: const ValueKey('play'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.isArabic ? 'العب بلوت' : 'Play Baloot', style: GoogleFonts.cairo(
          fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1,
          shadows: const [Shadow(color: Color(0x8C000000), blurRadius: 8, offset: Offset(0, 2))],
        )),
        Text('PLAY NOW', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white60)),
      ],
    );
  }

  Widget _searchingLabel() {
    return Column(
      key: const ValueKey('searching'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.isArabic ? 'جاري البحث' : 'Searching', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _searchDotsCtrl,
              builder: (_, __) {
                final val = (_searchDotsCtrl.value - i * 0.2) % 1.0;
                final double opacity = 0.2 + 0.8 * (sin(val * 2 * pi - pi / 2) * 0.5 + 0.5);
                final double dy = -3.0 * (sin(val * 2 * pi - pi / 2) * 0.5 + 0.5);
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  TOURNAMENT BANNER
  // ══════════════════════════════════════════════════════════════
  Widget _buildTournamentBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Column(
        children: [
          // Divider with title
          Row(
            children: [
              Expanded(child: Container(height: 1, decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, Color(0x47FFD700)])))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(widget.isArabic ? 'كأس بلوت' : 'Baloot Cup', style: GoogleFonts.cairo(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: const Color(0x80FFD700), letterSpacing: 3,
                )),
              ),
              Expanded(child: Container(height: 1, decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0x47FFD700), Colors.transparent])))),
            ],
          ),
          const SizedBox(height: 8),
          // Banner
          AnimatedBuilder(
            animation: _tournamentCtrl,
            builder: (_, child) {
              final glow = 22.0 + _tournamentCtrl.value * 28.0;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: const Color(0x61FFD700), blurRadius: glow)],
                ),
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () {},
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    // Base gradient
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF7A5A00), Color(0xFFB8860B), Color(0xFFFFD700),
                            Color(0xFFFFE44D), Color(0xFFFFD700), Color(0xFFC9A84C), Color(0xFF7A5A00),
                          ],
                          stops: [0, 0.18, 0.38, 0.55, 0.66, 0.82, 1],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 34)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.isArabic ? 'كأس رويال' : 'Royal Cup', style: GoogleFonts.cairo(
                                  fontSize: 19, fontWeight: FontWeight.w900, color: const Color(0xFF0A0A0A), height: 1)),
                                const SizedBox(height: 3),
                                Text(widget.isArabic ? 'انضم إلى البطولة الكبرى الآن' : 'Join the grand tournament now', style: GoogleFonts.cairo(
                                  fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0x94000000))),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Text('🃏', style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                                ),
                                child: Text(widget.isArabic ? '▶ العب' : '▶ Play', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF0A0A0A))),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Shimmer sweep
                    AnimatedBuilder(
                      animation: _shimmerCtrl,
                      builder: (_, __) {
                        final tx = (_shimmerCtrl.value * 2.0 - 0.5) * 400;
                        return Positioned.fill(
                          child: Transform.translate(
                            offset: Offset(tx, 0),
                            child: Container(
                              width: 80,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Color(0x52FFFFFF), Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Top line
                    Positioned(top: 0, left: 30, right: 30, height: 1,
                      child: Container(color: Colors.white.withValues(alpha: 0.32))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  BOTTOM NAV
  // ══════════════════════════════════════════════════════════════
  Widget _buildBottomNav() {
    final nav = [
      (id: 'store',       em: '🛍️', lbl: widget.isArabic ? 'المتجر' : 'Store'),
      (id: 'community',   em: '👥', lbl: widget.isArabic ? 'المجتمع' : 'Community'),
      (id: 'home',        em: '🃏', lbl: widget.isArabic ? 'الرئيسية' : 'Home'),
      (id: 'tournaments', em: '🏆', lbl: widget.isArabic ? 'الدوريات' : 'Tournaments'),
      (id: 'chat',        em: '💬', lbl: widget.isArabic ? 'دردشة' : 'Chat'),
    ];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFA0E051E), Color(0xFF05020C)],
        ),
        border: Border(top: BorderSide(color: Color(0x21FFD700))),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Top shimmer line
            Positioned(top: 0, left: 16, right: 16, height: 1,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent, Color(0x38FFD700),
                    Color(0x3800F5FF), Color(0x38FFD700), Colors.transparent,
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: nav.map((item) {
                  final on = item.id == _activeTab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = item.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: on ? const LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Color(0x1F00F5FF), Color(0x0A00F5FF)],
                            ) : null,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: on ? const Color(0x3800F5FF) : Colors.transparent),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Active indicator dot
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: on ? 24 : 0, height: 3,
                                decoration: BoxDecoration(
                                  color: on ? _kCYN : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: on ? const [
                                    BoxShadow(color: _kCYN, blurRadius: 14),
                                    BoxShadow(color: Color(0x6B00F5FF), blurRadius: 28),
                                  ] : null,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(item.em, style: TextStyle(
                                fontSize: 20,
                                shadows: on ? const [Shadow(color: _kCYN, blurRadius: 9)] : null,
                              )),
                              const SizedBox(height: 2),
                              Text(item.lbl, style: GoogleFonts.cairo(
                                fontSize: 9.5,
                                fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                                color: on ? _kCYN : const Color(0x6BFFD700),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════════════

class _NebulaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void drawNebula(Alignment center, Color color, double radius) {
      final cx = (center.x * 0.5 + 0.5) * size.width;
      final cy = (center.y * 0.5 + 0.5) * size.height;
      final r = radius * size.longestSide;
      final paint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60)
        ..shader = RadialGradient(
          colors: [color, Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    drawNebula(const Alignment(-0.76, -0.92), const Color(0xB82D0057), 0.42);
    drawNebula(const Alignment(0.76, -0.64),  const Color(0x0A00F5FF), 0.32);
    drawNebula(const Alignment(0.0, 0.76),    const Color(0x6B2D0057), 0.38);
    drawNebula(const Alignment(0.84, 0.24),   const Color(0x0700C853), 0.24);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x06FFD700)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ParticlesPainter extends CustomPainter {
  final List<_Pt> particles;
  const _ParticlesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final opacity = p.a.abs().clamp(0.0, 1.0) * 0.8;
      if (opacity <= 0.01) continue;
      final r = p.r * 2.8;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [p.c.withValues(alpha: opacity), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(p.x, p.y), radius: r));
      canvas.drawCircle(Offset(p.x, p.y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) => true;
}

// ── Hex clipper for rank badge ────────────────────────────────────
class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    return Path()
      ..moveTo(s.width * 0.1, 0)
      ..lineTo(s.width * 0.9, 0)
      ..lineTo(s.width, s.height * 0.3)
      ..lineTo(s.width * 0.9, s.height)
      ..lineTo(s.width * 0.1, s.height)
      ..lineTo(0, s.height * 0.3)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

// ── Spring curve for XP star pop ─────────────────────────────────
class _SpringCurve extends Curve {
  @override
  double transformInternal(double t) {
    const damping = 10.0;
    const frequency = 25.0;
    return 1.0 - exp(-damping * t) * cos(frequency * t);
  }
}
