import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import 'game_mode_screen.dart';
import 'game_mode_result_screen.dart';
import 'package:baloot_game/core/painters/diamond_painter.dart';

import 'package:provider/provider.dart';
import 'package:baloot_game/core/l10n/locale_provider.dart';

// ------------------------------------------------------------------
//  TEST SCREEN 3 � Blue Clash-Royale-style Home Screen
//  Fully translated from React/TSX Test 2
// ------------------------------------------------------------------

class GameModeModel {
  final String id;
  final String name;
  final String icon;
  final String desc;
  final Color color;

  const GameModeModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.desc,
    required this.color,
  });
}

const List<GameModeModel> kGameModes = [
  GameModeModel(
      id: 'normal',
      name: 'Normal Session',
      icon: '??',
      desc: '4 players � Classic Baloot',
      color: Color(0xFF4A90D9)),
  GameModeModel(
      id: 'friendly',
      name: 'Friendly Game',
      icon: '??',
      desc: 'Play with friends',
      color: Color(0xFF5BB96E)),
  GameModeModel(
      id: 'voice',
      name: 'Voice Session',
      icon: '???',
      desc: 'With voice chat enabled',
      color: Color(0xFF9B59B6)),
  GameModeModel(
      id: 'create',
      name: 'Create Session',
      icon: '?',
      desc: 'Custom game settings',
      color: Color(0xFFE8920E)),
  GameModeModel(
      id: 'sessions',
      name: 'Browse Sessions',
      icon: '??',
      desc: 'Join existing games',
      color: Color(0xFFE74C3C)),
  GameModeModel(
      id: 'tournament',
      name: 'Tournament',
      icon: '??',
      desc: 'Compete for prizes',
      color: Color(0xFFF5A623)),
];

class TestScreen3 extends StatefulWidget {
  final bool isArabic;
  const TestScreen3({super.key, this.isArabic = false});

  @override
  State<TestScreen3> createState() => _TestScreen3State();
}

class _TestScreen3State extends State<TestScreen3>
    with TickerProviderStateMixin {
  String _selectedModeId = 'normal';
  bool _showModePanel = false;
  String _activeTab = 'home';

  GameModeModel get _selectedMode =>
      kGameModes.firstWhere((m) => m.id == _selectedModeId,
          orElse: () => kGameModes.first);

  void _handleModeConfirm(String id) {
    setState(() {
      _selectedModeId = id;
      _showModePanel = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2660),
      body: Stack(
        children: [
          // -- Premium Quilted Background (Diamonds Only) --
          Positioned.fill(
            child: CustomPaint(
              painter: DiamondOnlyPainter(),
            ),
          ),

          // -- Top Glow --
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 256,
                height: 128,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.0,
                    colors: [
                      const Color(0xFF4A90D9).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),

          // -- Main Content --
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: _TopBar(
                    username: 'elpatron',
                    avatarUrl: null,
                    coins: '1.1M',
                    gems: '662',
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      // -- Main content --
                      Column(
                        children: [
                          // Space above the battle row (like Test 3)
                          const Spacer(flex: 5),

                          // -- Battle Row (Play button) --
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _BattleRow(
                              selectedMode: _selectedMode,
                              onPlayPress: () =>
                                  setState(() => _showModePanel = true),
                              onModePress: () =>
                                  setState(() => _showModePanel = true),
                            ),
                          ),

                          const SizedBox(height: 10),
                          const _TournamentBanner(),

                          // Space below
                          const Spacer(flex: 3),

                          _BottomNav(
                            activeTab: _activeTab,
                            onTabChange: (tab) =>
                                setState(() => _activeTab = tab),
                          ),
                        ],
                      ),

                      // -- Floating VIP side button --
                      Positioned(
                        left: 16,
                        top: 12,
                        child: _VipSideButton(
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // -- Game Mode Panel Overlay --
          if (_showModePanel)
            _GameModePanel(
              selectedModeId: _selectedModeId,
              onSelect: (id) => setState(() => _selectedModeId = id),
              onConfirm: _handleModeConfirm,
              onClose: () => setState(() => _showModePanel = false),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
//  COMPONENTS
// ------------------------------------------------------------------

// ------------------------------------------------------------------
//  TOP BAR � Avatar (2x) with rank + Currency with custom icons
//  Settings icon sits below currency row on the right.
// ------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final String coins;
  final String gems;

  const _TopBar({
    required this.username,
    this.avatarUrl,
    required this.coins,
    required this.gems,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // -- Profile chip (flexible width) --
          Flexible(
            child: _avatarChip(),
          ),
          // -- Currency bars with custom icons --
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CRCurrencyBar(
                    value: coins,
                    iconEmoji: '??',
                    barColor: const Color(0xFF3B2D10),
                    barBorder: const Color(0xFF7A6529),
                    btnColors: const [Color(0xFFD4AF37), Color(0xFFB8960B)],
                  ),
                  const SizedBox(width: 6),
                  _CRCurrencyBar(
                    value: gems,
                    iconEmoji: '??',
                    barColor: const Color(0xFF0D3326),
                    barBorder: const Color(0xFF2D7A5E),
                    btnColors: const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  ),
                ],
              ),
              // -- Quick Menu button below gems --
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _QuickMenuButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarChip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.royalGold.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // -- Avatar circle --
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.royalGold, width: 1.5),
              color: const Color(0xFF2B3140),
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.asset(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 26,
                        color: Color(0xFFD6B146),
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 26,
                      color: Color(0xFFD6B146),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          // -- Name + Rank --
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.readexPro(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                // -- Rank row --
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('?',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFFF5A623))),
                    const SizedBox(width: 4),
                    Text(
                      '532',
                      style: GoogleFonts.readexPro(
                        color: AppColors.royalGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
//  VIP SIDE BUTTON � Clash Royale style floating round button.
// ------------------------------------------------------------------

class _VipSideButton extends StatefulWidget {
  const _VipSideButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_VipSideButton> createState() => _VipSideButtonState();
}

class _VipSideButtonState extends State<_VipSideButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.88),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) {
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalGold.withValues(
                      alpha: 0.35 + (_pulseAnim.value * 0.35),
                    ),
                    blurRadius: 18 + (_pulseAnim.value * 12),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(0, -0.3),
                radius: 0.85,
                colors: [Color(0xFF2A2210), Color(0xFF12100A)],
              ),
              border: Border.all(
                color: AppColors.royalGold.withValues(alpha: 0.8),
                width: 3.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.royalGold.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.royalGold,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
//  CLASH ROYALE-STYLE CURRENCY BAR
// ------------------------------------------------------------------

class _CRCurrencyBar extends StatelessWidget {
  const _CRCurrencyBar({
    required this.value,
    required this.iconEmoji,
    required this.barColor,
    required this.barBorder,
    required this.btnColors,
  });

  final String value;
  final String iconEmoji;
  final Color barColor;
  final Color barBorder;
  final List<Color> btnColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: barBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The coloured '+' block on the left
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: btnColors,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                bottomLeft: Radius.circular(5),
              ),
              border: Border(
                right: BorderSide(
                  color: Colors.black.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
            ),
            child: const Center(
              child: Icon(Icons.add_rounded, size: 18, color: Colors.white),
            ),
          ),

          // -- Amount text --
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              value,
              style: GoogleFonts.readexPro(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // -- Currency emoji icon --
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(iconEmoji, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
//  QUICK MENU BUTTON � Hamburger opens a dropdown
// ------------------------------------------------------------------

class _QuickMenuButton extends StatelessWidget {
  const _QuickMenuButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showQuickMenu(context),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2129),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.royalGold.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.menu_rounded,
          color: AppColors.royalGold.withValues(alpha: 0.9),
          size: 22,
        ),
      ),
    );
  }

  void _showQuickMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset buttonPos = button.localToGlobal(Offset.zero);
    final double menuTop = buttonPos.dy - 60; // Shift up to align with the middle of the popup
    final double screenWidth = MediaQuery.of(context).size.width;
    final double menuRight = screenWidth - buttonPos.dx + 4; // Right side of the button + some padding

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'QuickMenu',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (dialogContext, _, __) {
        return Stack(
          children: [
            Positioned(
              top: menuTop,
              right: menuRight,
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: 245, // 230 main + 15 arrow space
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Main Popup Container
                      Container(
                        width: 230,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black87, width: 3),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _crMenuItem(context: dialogContext, icon: Icons.history_rounded, label: context.read<LocaleProvider>().isArabic ? '??? ?????????' : 'Match History', onTap: () {}),
                            const SizedBox(height: 4),
                            _crMenuItem(context: dialogContext, icon: Icons.emoji_events_rounded, label: context.read<LocaleProvider>().isArabic ? '?????????' : 'Achievements', onTap: () {}),
                            const SizedBox(height: 4),
                            _crMenuItem(context: dialogContext, icon: Icons.palette_rounded, label: context.read<LocaleProvider>().isArabic ? '???????' : 'Customisation', onTap: () {}),
                            _divider(),
                            _crMenuItem(context: dialogContext, icon: Icons.settings_rounded, label: context.read<LocaleProvider>().isArabic ? '?????????' : 'Settings', onTap: () {}),
                            const SizedBox(height: 4),
                            _crMenuItem(context: dialogContext, icon: Icons.language_rounded, label: 'Language', onTap: () {}),
                            _divider(),
                            _crMenuItem(context: dialogContext, icon: Icons.help_outline_rounded, label: context.read<LocaleProvider>().isArabic ? '???????? ??????' : 'Help & Support', onTap: () {}),
                            const SizedBox(height: 4),
                            _crMenuItem(context: dialogContext, icon: Icons.shield_rounded, label: context.read<LocaleProvider>().isArabic ? '????????' : 'Privacy', onTap: () {}),
                            _divider(),
                            _crMenuItem(context: dialogContext, icon: Icons.logout_rounded, label: context.read<LocaleProvider>().isArabic ? '????? ??????' : 'Log Out', onTap: () => Navigator.pop(dialogContext)),
                          ],
                        ),
                      ),
                      // Arrow pointing right
                      Positioned(
                        top: 24,
                        left: 222, // 230 - 8
                        child: Transform.rotate(
                          angle: 0.785398, // 45 degrees
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: Colors.black87, width: 3),
                                right: BorderSide(color: Colors.black87, width: 3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _crMenuItem({required BuildContext context, required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: const Color(0xFF1368C7), // Dark blue bottom edge
          border: Border.all(color: Colors.black87, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 2),
          ],
        ),
        child: Stack(
          children: [
            // The lighter blue gradient top
            Positioned(
              top: 0, left: 0, right: 0, bottom: 4, // Leaves 4px of the dark base exposed at the bottom
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4), bottom: Radius.circular(2)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xFF67B5F7), Color(0xFF3B97F0)],
                  ),
                ),
              ),
            ),
            // The content (icon and text) vertically centered
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2), // visually centers in the whole button
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(icon, color: Colors.white, size: 22, shadows: const [Shadow(color: Colors.black87, offset: Offset(0, 1.5), blurRadius: 2)]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          label.toUpperCase(),
                          style: GoogleFonts.cairo(
                            fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: const [
                              Shadow(color: Colors.black, offset: Offset(-1.5, -1.5)),
                              Shadow(color: Colors.black, offset: Offset(1.5, -1.5)),
                              Shadow(color: Colors.black, offset: Offset(1.5, 1.5)),
                              Shadow(color: Colors.black, offset: Offset(-1.5, 1.5)),
                              Shadow(color: Colors.black87, offset: Offset(0, 2.5), blurRadius: 1), // Drop shadow below stroke
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 42), // Balances the 12+22+8=42 on the left so the text is perfectly centered
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: Colors.grey.shade300,
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A7C), Color(0xFF0D2050)],
        ),
        border: Border.all(color: const Color(0xFFF5A623), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A623).withValues(alpha: 0.5),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            offset: const Offset(0, 1),
            blurRadius: 0,
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('??', style: TextStyle(fontSize: 16, height: 1)),
          Text(
            'DAILY',
            style: GoogleFonts.readexPro(
              color: Colors.white,
              fontSize: 7,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          const SizedBox(width: 48), // Space for absolute badge
          const _StatChip(
              icon: '?', value: '20', label: 'XP', color: Color(0xFFF5C842)),
          const SizedBox(width: 6),
          const _StatChip(icon: '??', value: '344', color: Color(0xFFE74C4C)),
          const SizedBox(width: 6),
          const _StatChip(icon: '?', value: '25,477', color: Color(0xFFF5A623)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF5A623).withValues(alpha: 0.2),
                  const Color(0xFFE8920E).withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFFF5A623).withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF5A623).withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('???', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  'EXPERT',
                  style: GoogleFonts.readexPro(
                    color: const Color(0xFFF5C842),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String value;
  final String? label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1C48).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: const Color(0xFF4A90D9).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.readexPro(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: GoogleFonts.readexPro(
                  color: const Color(0xFF8DB4E8), fontSize: 12),
            ),
          ]
        ],
      ),
    );
  }
}

class _ArenaDisplay extends StatelessWidget {
  final GameModeModel selectedMode;

  const _ArenaDisplay({required this.selectedMode});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: SizedBox(
          width: 220,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow
              Container(
                width: 200,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4A90D9).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A90D9).withValues(alpha: 0.15),
                      blurRadius: 40,
                    ),
                  ],
                ),
              ),

              // Card table surface
              Container(
                width: 190,
                height: 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F3A1A),
                      Color(0xFF144D22),
                      Color(0xFF0F3A1A)
                    ],
                    stops: [0.0, 0.4, 1.0],
                  ),
                  border: Border.all(
                      color: const Color(0xFFF5A623).withValues(alpha: 0.6),
                      width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFF5A623).withValues(alpha: 0.25),
                        blurRadius: 20),
                  ],
                ),
                child: Stack(
                  children: [
                    // Inner felt ring
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFF5A623)
                                    .withValues(alpha: 0.25)),
                          ),
                        ),
                      ),
                    ),

                    // Center Icon & Name
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedMode.id == 'normal'
                                ? '?'
                                : selectedMode.icon,
                            style: TextStyle(
                              fontSize: 48,
                              color: Colors.white,
                              height: 1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  offset: const Offset(0, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          if (selectedMode.id != 'normal')
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: selectedMode.color
                                        .withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                selectedMode.name,
                                style: GoogleFonts.readexPro(
                                  color: selectedMode.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Corner cards (approximated positions)
              const Positioned(
                  top: 20, left: 24, child: _Card(suit: '?', rotate: -0.2)),
              const Positioned(
                  top: 20,
                  right: 24,
                  child:
                      _Card(suit: '?', rotate: 0.2, color: Color(0xFFE74C4C))),
              const Positioned(
                  bottom: 20, left: 24, child: _Card(suit: '?', rotate: 0.14)),
              const Positioned(
                  bottom: 20,
                  right: 24,
                  child: _Card(
                      suit: '?', rotate: -0.14, color: Color(0xFFE74C4C))),

              // Badges
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1C48).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF5BB95B).withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5BB95B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF5BB95B), blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('1,247 online',
                          style: GoogleFonts.readexPro(
                              color: Colors.white, fontSize: 10)),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1C48).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFE8920E).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Text('??', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        'HOT',
                        style: GoogleFonts.readexPro(
                            color: const Color(0xFFF5C842),
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String suit;
  final double rotate;
  final Color color;

  const _Card(
      {required this.suit,
      required this.rotate,
      this.color = const Color(0xFFE8E8F0)});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate,
      child: Container(
        width: 28,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0EEE8), Color(0xFFE4E0D8)],
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          suit,
          style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1),
        ),
      ),
    );
  }
}

class _BattleRow extends StatefulWidget {
  final GameModeModel selectedMode;
  final VoidCallback onPlayPress;
  final VoidCallback onModePress;

  const _BattleRow(
      {required this.selectedMode,
      required this.onPlayPress,
      required this.onModePress});

  @override
  State<_BattleRow> createState() => _BattleRowState();
}

class _BattleRowState extends State<_BattleRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E2458), Color(0xFF091640)],
        ),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: const Color(0xFF4A90D9).withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF040C24).withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Left Mode Box
          GestureDetector(
            onTap: widget.onModePress,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1C4080), Color(0xFF0F2456)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  top: BorderSide(color: Color(0x8C5096E6), width: 2),
                  left: BorderSide(color: Color(0x405096E6), width: 1.5),
                  right: BorderSide(color: Color(0x80040C24), width: 1.5),
                  bottom: BorderSide(color: Color(0x33040C24), width: 2),
                ),
                boxShadow: [
                  const BoxShadow(
                      color: Color(0xB2040C24), offset: Offset(0, 4)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.selectedMode.color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: widget.selectedMode.color
                              .withValues(alpha: 0.26)),
                    ),
                    alignment: Alignment.center,
                    child: Text(widget.selectedMode.icon,
                        style: const TextStyle(fontSize: 20)),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8920E),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: const Text('?',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Center Play Button
          Expanded(
            child: GestureDetector(
              onTap: widget.onPlayPress,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, child) {
                  return Container(
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFE566),
                          Color(0xFFF5A820),
                          Color(0xFFD47808)
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(
                        top: BorderSide(color: Color(0x8CFFFFFF), width: 2),
                        left: BorderSide(color: Color(0x80FFDC50), width: 1.5),
                        right: BorderSide(color: Color(0x668C4600), width: 1.5),
                        bottom: BorderSide(color: Color(0x338C4600), width: 2),
                      ),
                      boxShadow: [
                        const BoxShadow(
                            color: Color(0xB2643200), offset: Offset(0, 4)),
                        BoxShadow(
                          color: const Color(0xFFF5B423)
                              .withValues(alpha: 0.45 + _pulseCtrl.value * 0.3),
                          blurRadius: 22 + _pulseCtrl.value * 16,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 25,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.28),
                                  Colors.transparent
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(10)),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            'PLAY',
                            style: GoogleFonts.readexPro(
                              color: const Color(0xFF5C2800),
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    offset: const Offset(0, 1)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Right Mode Picker Box
          GestureDetector(
            onTap: widget.onModePress,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1C4080), Color(0xFF0F2456)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  top: BorderSide(color: Color(0x8C5096E6), width: 2),
                  left: BorderSide(color: Color(0x405096E6), width: 1.5),
                  right: BorderSide(color: Color(0x80040C24), width: 1.5),
                  bottom: BorderSide(color: Color(0x33040C24), width: 2),
                ),
                boxShadow: [
                  const BoxShadow(
                      color: Color(0xB2040C24), offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.keyboard_arrow_down,
                      color: Color(0xFF4A90D9), size: 20),
                  Text(
                    'MODE',
                    style: GoogleFonts.readexPro(
                      color: const Color(0xFF6AA0D4),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentBanner extends StatelessWidget {
  const _TournamentBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A4A8C), Color(0xFF0D2A60), Color(0xFF1A3A7C)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFF5A623).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFF5A623).withValues(alpha: 0.12),
              blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF5A623).withValues(alpha: 0.25),
                  const Color(0xFFE8920E).withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFF5A623).withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: const Text('??', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Baloot Cup Championship',
                  style: GoogleFonts.readexPro(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5BB95B),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF5BB95B), blurRadius: 4)
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live now � 342 players competing',
                      style: GoogleFonts.readexPro(
                          color: const Color(0xFF8DB4E8), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5C842), Color(0xFFE8920E)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFF5A623).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              'Join',
              style: GoogleFonts.readexPro(
                  color: const Color(0xFF1A0A00),
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChange;

  const _BottomNav({required this.activeTab, required this.onTabChange});

  final _tabs = const [
    {'id': 'store', 'icon': '???', 'label': 'Store'},
    {'id': 'friends', 'icon': '??', 'label': 'Friends'},
    {'id': 'home', 'icon': '??', 'label': 'Home'},
    {'id': 'chat', 'icon': '??', 'label': 'Chat'},
    {'id': 'trophy', 'icon': '??', 'label': 'Trophy'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071540), Color(0xFF050F2E)],
        ),
        border: Border(
            top: BorderSide(
                color: const Color(0xFF4A90D9).withValues(alpha: 0.25))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: _tabs.map((tab) {
            final isActive = tab['id'] == activeTab;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTabChange(tab['id']!),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isActive)
                        Positioned(
                          top: -10,
                          child: Container(
                            width: 32,
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFFF5C842),
                                Color(0xFFE8920E)
                              ]),
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(3)),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFFF5A623)
                                        .withValues(alpha: 0.6),
                                    blurRadius: 8)
                              ],
                            ),
                          ),
                        ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tab['icon']!,
                            style: TextStyle(
                              fontSize: 20,
                              height: 1,
                              shadows: isActive
                                  ? [
                                      Shadow(
                                          color: const Color(0xFFF5A623)
                                              .withValues(alpha: 0.6),
                                          blurRadius: 6)
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab['label']!,
                            style: GoogleFonts.readexPro(
                              color: isActive
                                  ? const Color(0xFFF5A623)
                                  : const Color(0xFF4A6A9A),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _GameModePanel extends StatelessWidget {
  final String selectedModeId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onConfirm;
  final VoidCallback onClose;

  const _GameModePanel({
    required this.selectedModeId,
    required this.onSelect,
    required this.onConfirm,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final sections = [
      {
        'label': null,
        'ids': ['normal', 'friendly', 'voice']
      },
      {
        'label': 'Competitive Modes',
        'ids': ['tournament']
      },
      {
        'label': 'Classic Modes',
        'ids': ['create', 'sessions']
      },
    ];

    final cardColors = {
      'normal': [const Color(0xFF0D3E82), const Color(0xFF1558A8)],
      'friendly': [const Color(0xFF0D3E82), const Color(0xFF1E6B2C)],
      'voice': [const Color(0xFF0D3E82), const Color(0xFF3A2080)],
      'tournament': [const Color(0xFF3A1E7A), const Color(0xFF6028A0)],
      'create': [const Color(0xFF0D3E82), const Color(0xFF1558A8)],
      'sessions': [const Color(0xFF0D3E82), const Color(0xFF1E4A8C)],
    };

    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.58)),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1258B0), Color(0xFF0E4898)],
              ),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF000064).withValues(alpha: 0.6),
                    blurRadius: 40,
                    offset: const Offset(0, -8))
              ],
            ),
            child: Column(
              children: [
                // Header (Tab + Title)
                Column(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 86,
                          padding: const EdgeInsets.only(top: 9, bottom: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF3AB2FF), Color(0xFF1A82E8)],
                            ),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(13)),
                            border: const Border(
                              top: BorderSide(
                                  color: Color(0xCCA0E6FF), width: 2.5),
                              left: BorderSide(
                                  color: Color(0x99A0E6FF), width: 2.5),
                              right: BorderSide(
                                  color: Color(0x99A0E6FF), width: 2.5),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 44,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF1A6AD4), Color(0xFF1050B8)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0x8C64BEFF), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    blurRadius: 0,
                                    offset: const Offset(0, 1),
                                    blurStyle: BlurStyle.inner),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF2290FF), Color(0xFF1468D0)],
                        ),
                        border: Border(
                          top: BorderSide(color: Color(0xBF8CDCFF), width: 2.5),
                          bottom:
                              BorderSide(color: Color(0xCC1450B4), width: 2.5),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Game Modes',
                        style: GoogleFonts.readexPro(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          shadows: [
                            const Shadow(
                                color: Color(0x99003CA0), offset: Offset(0, 1)),
                            Shadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                offset: const Offset(0, 2),
                                blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Scrollable List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    itemCount: sections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      final label = section['label'] as String?;
                      final ids = section['ids'] as List<String>;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (label != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Container(
                                          height: 1,
                                          color: Colors.white
                                              .withValues(alpha: 0.2))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      label.toUpperCase(),
                                      style: GoogleFonts.readexPro(
                                          color: Colors.white
                                              .withValues(alpha: 0.6),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1),
                                    ),
                                  ),
                                  Expanded(
                                      child: Container(
                                          height: 1,
                                          color: Colors.white
                                              .withValues(alpha: 0.2))),
                                ],
                              ),
                            ),
                          ...ids.map((id) {
                            final mode =
                                kGameModes.firstWhere((m) => m.id == id);
                            final isSelected = selectedModeId == id;
                            final colors = cardColors[id]!;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: GestureDetector(
                                onTap: () => onSelect(id),
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xE6F5C432)
                                          : Colors.white.withValues(alpha: 0.1),
                                      width: 2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            const BoxShadow(
                                                color: Color(0x66F5C432),
                                                blurRadius: 12),
                                            const BoxShadow(
                                                color: Color(0x8C001450),
                                                offset: Offset(0, 3)),
                                          ]
                                        : [
                                            const BoxShadow(
                                                color: Color(0x73001450),
                                                offset: Offset(0, 3))
                                          ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: colors[0],
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                                    left: Radius.circular(10)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                mode.name,
                                                style: GoogleFonts.readexPro(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w900,
                                                  shadows: [
                                                    Shadow(
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.4),
                                                        offset:
                                                            const Offset(0, 1),
                                                        blurRadius: 3)
                                                  ],
                                                ),
                                              ),
                                              Text(mode.desc,
                                                  style: GoogleFonts.readexPro(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.6),
                                                      fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                          width: 2,
                                          color: Colors.black
                                              .withValues(alpha: 0.25)),
                                      Container(
                                        width: 64,
                                        decoration: BoxDecoration(
                                          color: colors[1],
                                          borderRadius:
                                              const BorderRadius.horizontal(
                                                  right: Radius.circular(10)),
                                        ),
                                        alignment: Alignment.center,
                                        child: isSelected
                                            ? Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient:
                                                      const LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Color(0xFFF5C842),
                                                      Color(0xFFE8920E)
                                                    ],
                                                  ),
                                                  border: Border.all(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.35),
                                                      width: 2),
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: const Color(
                                                                0xFFF5A623)
                                                            .withValues(
                                                                alpha: 0.5),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 2))
                                                  ],
                                                ),
                                                child: const Icon(Icons.check,
                                                    color: Colors.white,
                                                    size: 20),
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),

                // Play Button Pinned to Bottom
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: GestureDetector(
                    onTap: () => onConfirm(selectedModeId),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFF5C842),
                            Color(0xFFE8920E),
                            Color(0xFFC4720A)
                          ],
                          stops: [0.0, 0.6, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: const Border(
                            top:
                                BorderSide(color: Color(0x66FFFFFF), width: 2)),
                        boxShadow: [
                          const BoxShadow(
                              color: Color(0x99643200), offset: Offset(0, 4)),
                          BoxShadow(
                              color: const Color(0xFFF5A623)
                                  .withValues(alpha: 0.35),
                              blurRadius: 18),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '?   PLAY NOW',
                        style: GoogleFonts.readexPro(
                            color: const Color(0xFF3A1400),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------
//  PAINTERS
// ------------------------------------------------------------------

class _DiamondTilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A90D9).withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    const tileSize = 22.0;
    const halfTile = tileSize / 2;

    for (double y = 0; y < size.height + tileSize; y += halfTile) {
      final isStaggered = (y / halfTile).round() % 2 != 0;
      for (double x = 0; x < size.width + tileSize; x += tileSize) {
        final cx = isStaggered ? x + halfTile : x;
        final cy = y;

        final path = Path()
          ..moveTo(cx, cy - halfTile)
          ..lineTo(cx + halfTile, cy)
          ..lineTo(cx, cy + halfTile)
          ..lineTo(cx - halfTile, cy)
          ..close();

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}




