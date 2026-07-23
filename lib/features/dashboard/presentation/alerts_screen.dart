import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baloot_game/core/painters/diamond_painter.dart';

// ══════════════════════════════════════════════════════════════════
//  ALERTS SCREEN — Premium Sandstone UI (Option H)
//  Features: staggered animations · accent bars · segmented tabs
//            · unread badges · gold divider headers · glow rings
// ══════════════════════════════════════════════════════════════════

// ── Sandstone colour tokens ──────────────────────────────────────
const _kBgCanvas   = Color(0xFF1E1808);
const _kBgCard     = Color(0xFF2C2210);
const _kBgElevated = Color(0xFF392C14);
const _kSandGold   = Color(0xFFC49028);
const _kSandLight  = Color(0xFFDFAE45);
const _kSandDark   = Color(0xFF886018);
const _kHoney      = Color(0xFFB87818);
const _kTextPrim   = Color(0xFFF8EDD8);
const _kTextSec    = Color(0xFFC8A868);
const _kTextMuted  = Color(0xFF806840);
const _kSandBorder = Color(0x42C49028);

class AlertsScreen extends StatefulWidget {
  final bool isArabic;
  const AlertsScreen({super.key, this.isArabic = false});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;

  // Tab labels with unread counts
  final List<({String label, int unread})> _tabs = [
    (label: 'All',         unread: 3),
    (label: 'Social',      unread: 1),
    (label: 'Rewards',     unread: 1),
    (label: 'Tournaments', unread: 1),
  ];

  // All alert data
  late final List<_AlertData> _alerts;

  @override
  void initState() {
    super.initState();
    _alerts = [
      _AlertData(
        type: _AlertType.social,
        emoji: '👥',
        title: 'Ahmad sent you a friend request',
        subtitle: 'Expert • 847 wins',
        time: '1h ago',
        unread: true,
        group: 'TODAY',
      ),
      _AlertData(
        type: _AlertType.tournament,
        emoji: '🏆',
        title: 'Kamlana Cup round starts in 2 hours',
        subtitle: 'You have 2 tickets ready',
        time: '3h ago',
        unread: true,
        group: 'TODAY',
      ),
      _AlertData(
        type: _AlertType.reward,
        emoji: '🎁',
        title: 'Your daily reward is ready!',
        subtitle: 'Tap to claim 50 stars + 2 Cup tickets',
        time: '1d ago',
        unread: false,
        group: 'YESTERDAY',
      ),
      _AlertData(
        type: _AlertType.progression,
        emoji: '📈',
        title: 'Rank Up: Expert!',
        subtitle: 'You have successfully reached Expert rank.',
        time: '1d ago',
        unread: false,
        group: 'YESTERDAY',
      ),
      _AlertData(
        type: _AlertType.system,
        emoji: '📢',
        title: 'World Cup Event is Live!',
        subtitle: 'Join the 40,000 SAR prize tournament now.',
        time: '3d ago',
        unread: false,
        group: 'THIS WEEK',
      ),
      _AlertData(
        type: _AlertType.account,
        emoji: '⚙️',
        title: 'VIP Subscription renewing',
        subtitle: 'Your VIP status will auto-renew in 3 days.',
        time: '5d ago',
        unread: false,
        group: 'THIS WEEK',
      ),
    ];
  }

  List<_AlertData> get _filteredAlerts {
    if (_selectedTabIndex == 0) return _alerts;
    final types = [
      null,
      [_AlertType.social],
      [_AlertType.reward],
      [_AlertType.tournament],
    ];
    final filter = types[_selectedTabIndex];
    if (filter == null) return _alerts;
    return _alerts.where((a) => filter.contains(a.type)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1808),
      body: Stack(
        children: [
          // ── Diamond background — matches home screen game feel ──
          Positioned.fill(
            child: CustomPaint(painter: DiamondOnlyPainter()),
          ),
          // ── Content ──
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildGoldDivider(),
                const SizedBox(height: 12),
                _buildTabBar(),
                const SizedBox(height: 12),
                Expanded(child: _buildAlertList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    final unreadTotal = _alerts.where((a) => a.unread).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          // Back button — game-mode handle style
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: CustomPaint(
              painter: _BackHandlePainter(),
              child: SizedBox(
                width: 64,
                height: 40,
                child: Center(
                  child: CustomPaint(
                    size: const Size(11, 20),
                    painter: _BackChevronPainter(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title + badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.isArabic ? 'التنبيهات' : 'Alerts',
                style: GoogleFonts.cairo(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [_kSandDark, _kSandLight, _kSandGold],
                    ).createShader(const Rect.fromLTWH(0, 0, 130, 36)),
                ),
              ),
              if (unreadTotal > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kSandGold, _kSandDark]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Color(0x44C49028), blurRadius: 8)],
                  ),
                  child: Text(
                    '$unreadTotal',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _kBgCanvas,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          // Mark all as read
          GestureDetector(
            onTap: () => setState(() {
              for (final a in _alerts) { a.unread = false; }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _kBgElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kSandBorder),
                boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.done_all_rounded, color: _kSandGold, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    widget.isArabic ? 'قراءة الكل' : 'Mark read',
                    style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: _kTextSec),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Gold shimmer divider ────────────────────────────────────────
  Widget _buildGoldDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, _kSandGold, Color(0xFFDFAE45), _kSandGold, Colors.transparent],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
    );
  }

  // ── Segmented tab bar ───────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _kBgCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kSandBorder),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final tab = _tabs[i];
          final isSelected = _selectedTabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected ? _kSandGold : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? const [BoxShadow(color: Color(0x44C49028), blurRadius: 8)]
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      tab.label,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? _kBgCanvas : _kTextMuted,
                      ),
                    ),
                    if (tab.unread > 0 && !isSelected)
                      Positioned(
                        top: 3, right: 4,
                        child: Container(
                          width: 7, height: 7,
                          decoration: const BoxDecoration(
                            color: _kSandGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Alert list with staggered animation ────────────────────────
  Widget _buildAlertList() {
    final filtered = _filteredAlerts;
    // Group the alerts
    final groups = <String, List<_AlertData>>{};
    for (final a in filtered) {
      groups.putIfAbsent(a.group, () => []).add(a);
    }
    final groupOrder = ['TODAY', 'YESTERDAY', 'THIS WEEK'];

    final items = <Widget>[];
    for (final g in groupOrder) {
      if (!groups.containsKey(g)) continue;
      items.add(_buildDateHeader(g));
      for (final alert in groups[g]!) {
        items.add(_AlertCard(
          data: alert,
          index: items.length,
          onMarkRead: () => setState(() => alert.unread = false),
        ));
      }
    }
    items.add(const SizedBox(height: 32));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  // ── Date group header ───────────────────────────────────────────
  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Row(
        children: [
          Container(
            height: 1,
            width: 20,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _kSandBorder],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: _kTextMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kSandBorder, Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  ALERT DATA MODEL
// ══════════════════════════════════════════════════════════════════
enum _AlertType { social, tournament, reward, progression, account, system }

class _AlertData {
  final _AlertType type;
  final String emoji;
  final String title;
  final String subtitle;
  final String time;
  bool unread;
  final String group;

  _AlertData({
    required this.type, required this.emoji, required this.title,
    required this.subtitle, required this.time, required this.unread,
    required this.group,
  });

  Color get accentColor => switch (type) {
    _AlertType.social      => _kSandGold,
    _AlertType.tournament  => _kHoney,
    _AlertType.reward      => _kSandLight,
    _AlertType.progression => _kSandDark,
    _AlertType.account     => _kTextMuted,
    _AlertType.system      => _kHoney,
  };
}

// ══════════════════════════════════════════════════════════════════
//  ALERT CARD — Animated, with left accent bar + glow ring
// ══════════════════════════════════════════════════════════════════
class _AlertCard extends StatefulWidget {
  final _AlertData data;
  final int index;
  final VoidCallback onMarkRead;

  const _AlertCard({required this.data, required this.index, required this.onMarkRead});

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Staggered start
    Future.delayed(Duration(milliseconds: widget.index * 45), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final accent = d.accentColor;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: d.unread
                ? Color.lerp(_kBgCard, accent.withValues(alpha: 0.18), 0.35)!
                : _kBgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: d.unread ? accent.withValues(alpha: 0.4) : _kSandBorder,
              width: d.unread ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: d.unread ? accent.withValues(alpha: 0.10) : const Color(0x30000000),
                blurRadius: d.unread ? 18 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left accent bar ──
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [accent, accent.withValues(alpha: 0.3)],
                      ),
                    ),
                  ),
                  // ── Content ──
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon with glow ring
                          _buildIconCircle(d.emoji, accent, d.unread),
                          const SizedBox(width: 12),
                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        d.title,
                                        style: GoogleFonts.cairo(
                                          color: _kTextPrim,
                                          fontSize: 13.5,
                                          fontWeight: d.unread ? FontWeight.w700 : FontWeight.w600,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    if (d.unread)
                                      Container(
                                        width: 8, height: 8,
                                        margin: const EdgeInsets.only(top: 4, left: 6),
                                        decoration: BoxDecoration(
                                          color: accent,
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: accent, blurRadius: 6)],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  d.subtitle,
                                  style: GoogleFonts.cairo(color: _kTextSec, fontSize: 12, height: 1.35),
                                ),
                                const SizedBox(height: 8),
                                // Bottom row: time pill + action
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Time chip
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _kBgElevated,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: _kSandBorder),
                                      ),
                                      child: Text(
                                        d.time,
                                        style: GoogleFonts.cairo(color: _kTextMuted, fontSize: 10, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    // Action widget
                                    if (d.type == _AlertType.social)
                                      _buildSocialActions()
                                    else if (!d.unread)
                                      const Icon(Icons.chevron_right_rounded, color: _kTextMuted, size: 18),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconCircle(String emoji, Color accent, bool unread) {
    return Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withValues(alpha: unread ? 0.55 : 0.30),
          width: unread ? 2 : 1.5,
        ),
        boxShadow: unread
            ? [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 1)]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 20)),
    );
  }

  Widget _buildSocialActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onMarkRead,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _kBgElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kSandBorder),
            ),
            child: Text('Decline', style: GoogleFonts.cairo(color: _kTextMuted, fontSize: 10.5, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: widget.onMarkRead,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kSandLight, _kSandGold]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x44C49028), blurRadius: 8)],
            ),
            child: Text('Accept', style: GoogleFonts.cairo(color: _kBgCanvas, fontSize: 10.5, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}

// ── Gold trapezoid back-button painters (matches game mode handle style) ──────

class _BackHandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double inset = 8.0;
    final double slope = 10.0;
    final double r = 8.0;

    // Outer trapezoid (dark bg)
    final outerPath = Path()
      ..moveTo(inset + r, 0)
      ..lineTo(size.width - inset - r, 0)
      ..quadraticBezierTo(size.width - inset, 0, size.width - inset + slope * 0.4, size.height * 0.4)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(inset - slope * 0.4, size.height * 0.4)
      ..quadraticBezierTo(inset, 0, inset + r, 0)
      ..close();

    canvas.drawPath(
      outerPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF392C14), Color(0xFF1E1808)],
        ).createShader(Offset.zero & size),
    );

    // Gold border (top 3 sides)
    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(inset - slope * 0.4, size.height * 0.4)
      ..quadraticBezierTo(inset, 0, inset + r, 0)
      ..lineTo(size.width - inset - r, 0)
      ..quadraticBezierTo(size.width - inset, 0, size.width - inset + slope * 0.4, size.height * 0.4)
      ..lineTo(size.width, size.height);

    canvas.drawPath(
      borderPath,
      Paint()
        ..color = const Color(0xFFC49028)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner gold pill (the actual button)
    const double px = 10, py = 6;
    final innerRect = Rect.fromLTRB(px, py, size.width - px, size.height - py);
    final innerRRect = RRect.fromRectAndRadius(innerRect, const Radius.circular(6));

    // Bevel shadow
    canvas.drawRRect(
      innerRRect.shift(const Offset(0, 2)),
      Paint()..color = const Color(0xFF141008),
    );
    // Gold gradient fill
    canvas.drawRRect(
      innerRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC49028), Color(0xFF886018)],
        ).createShader(innerRect),
    );
    // Gloss reflection
    final glossRect = Rect.fromLTRB(px, py, size.width - px, py + (size.height - py * 2) * 0.45);
    canvas.drawRRect(
      RRect.fromRectAndRadius(glossRect, const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x99FFFFFF), Color(0x00FFFFFF)],
        ).createShader(glossRect),
    );
    // Gold border
    canvas.drawRRect(
      innerRRect,
      Paint()
        ..color = const Color(0xFFDFAE45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _BackChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Left-pointing chevron (< shape)
    final path = Path()
      ..moveTo(size.width * 0.8, 0)
      ..lineTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.8, size.height);

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF141008)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
