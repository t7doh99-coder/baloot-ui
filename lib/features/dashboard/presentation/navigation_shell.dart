import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/vip_background_shell.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../session/presentation/create_session_screen.dart';
import '../../game/presentation/finding_game_popup.dart';
import '../../settings/presentation/settings_screen.dart';

// ══════════════════════════════════════════════════════════════════
//  NAVIGATION SHELL — Modern Game Hub
//
//  CLIENT DIRECTIVE:
//  • 1–2 taps to reach a game
//  • One clear primary action: "Play"
//  • Three satellite actions: Create Session, Join Sessions, VIP
//  • No clutter, no heavy animations, luxury experience
//
//  ARCHITECTURE:
//  • All user data flows from UserProvider (no hardcoded values)
//  • All hub actions exposed via onTap callbacks
//  • LOGIC_PLUG_IN markers show where to connect backend
// ══════════════════════════════════════════════════════════════════

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 2; // Home is center tab

  // Subtle pulsing glow on the Play medallion
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.12, end: 0.35).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  // ── Hub action callbacks ──
  // LOGIC_PLUG_IN: Replace with ILobbyController implementation

  void _onPlayNow() {
    FindingGamePopup.show(context);
  }

  void _onCreateSession() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateSessionScreen()),
    );
  }

  void _onJoinSessions() {
    // TODO: Navigate to session browser
    debugPrint('[LobbyAction] Join Sessions');
  }

  void _onVipAccess() {
    _showComingSoon('VIP Store');
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature — Coming Soon!',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1A1D25),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final user = context.watch<UserProvider>().user;
    final isArabic = locale.isArabic;

    // Tab names for Coming Soon
    const tabNames = ['Shop', 'Community', 'Home', 'Chat', 'Leagues'];

    return Scaffold(
      backgroundColor: AppColors.antigravityBlack,
      body: Stack(
          children: [
            // ── Background: Static suit pattern (painted once, cached) ──
            const VipStaticBackground(),

            // ── Content ──
            SafeArea(
              child: Column(
                children: [
                  // ── Thin Top Bar: Avatar (left) + Currency (right) ──
                  _TopBar(
                    username: user.username,
                    coins: user.coinsFormatted,
                    gems: user.gemsFormatted,
                  ),

                  // ── Tab Content ──
                  Expanded(
                    child: _currentIndex == 2
                        ? Center(
                            child: _GameHub(
                              isArabic: isArabic,
                              glowAnim: _glowAnim,
                              onPlay: _onPlayNow,
                              onCreateSession: _onCreateSession,
                              onJoinSessions: _onJoinSessions,
                              onVipAccess: _onVipAccess,
                            ),
                          )
                        : _ComingSoonPage(
                            title: tabNames[_currentIndex],
                            isArabic: isArabic,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      bottomNavigationBar: _BottomNav(
        isArabic: isArabic,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TOP BAR — Avatar (2x) with rank + Currency with custom icons
//  Settings icon sits below currency row on the right.
// ══════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.username,
    required this.coins,
    required this.gems,
  });

  final String username;
  final String coins;
  final String gems;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      child: Column(
        children: [
          // ── Row 1: Avatar + Currency bars ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile chip (2x bigger) ──
              _avatarChip(),
              const Spacer(),
              // ── Currency bars with custom icons ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      _CRCurrencyBar(
                        value: coins,
                        iconImage: 'assets/images/dollar.png',
                        barColor: const Color(0xFF3B2D10),
                        barBorder: const Color(0xFF7A6529),
                        btnColors: const [Color(0xFFD4AF37), Color(0xFFB8960B)],
                      ),
                      const SizedBox(width: 4),
                      _CRCurrencyBar(
                        value: gems,
                        iconImage: 'assets/images/gem.png',
                        barColor: const Color(0xFF0D3326),
                        barBorder: const Color(0xFF2D7A5E),
                        btnColors: const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      ),
                    ],
                  ),
                  // ── Menu button (bigger) ──
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _QuickMenuButton(
                      onLanguage: () {
                        final locale = context.read<LocaleProvider>();
                        locale.toggleLocale();
                      },
                      onAlerts: () {
                        // LOGIC_PLUG_IN: Open alerts/notifications
                        debugPrint('[Menu] Alerts tapped');
                      },
                      onSettings: () {
                        SettingsPanel.show(context);
                      },
                    ),
                  ),
                ],
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
          // ── Avatar circle (2x bigger: 52px) ──
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.royalGold, width: 1.5),
              color: const Color(0xFF2B3140),
            ),
            child: const Icon(Icons.person, size: 26, color: Color(0xFFD6B146)),
          ),
          const SizedBox(width: 8),
          // ── Name + Rank ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                username,
                style: GoogleFonts.montserrat(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              // ── Rank row ──
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/ranking.png',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '532',
                    style: GoogleFonts.montserrat(
                      color: AppColors.royalGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  CLASH ROYALE-STYLE CURRENCY BAR
//  Layout: [Green + button] [amount text] [custom icon image]
// ══════════════════════════════════════════════════════════════════

class _CRCurrencyBar extends StatelessWidget {
  const _CRCurrencyBar({
    required this.value,
    required this.iconImage,
    required this.barColor,
    required this.barBorder,
    required this.btnColors,
  });

  final String value;
  final String iconImage;
  final Color barColor;
  final Color barBorder;
  final List<Color> btnColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: barBorder, width: 1),
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
          Container(
            width: 22,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: btnColors,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(Icons.add_rounded, size: 18, color: Colors.white),
            ),
          ),

          // ── Amount text ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // ── Custom currency icon (dollar.png / gem.png) ──
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Image.asset(
              iconImage,
              width: 22,
              height: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  GAME HUB — Play hero + 3 satellite actions
//  Layout: Medallion centered, 3 actions in a row below
// ══════════════════════════════════════════════════════════════════

class _GameHub extends StatelessWidget {
  const _GameHub({
    required this.isArabic,
    required this.glowAnim,
    required this.onPlay,
    required this.onCreateSession,
    required this.onJoinSessions,
    required this.onVipAccess,
  });

  final bool isArabic;
  final Animation<double> glowAnim;
  final VoidCallback onPlay;
  final VoidCallback onCreateSession;
  final VoidCallback onJoinSessions;
  final VoidCallback onVipAccess;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── The Hero: Play Medallion ──
          _PlayMedallion(
            isArabic: isArabic,
            glowAnim: glowAnim,
            onTap: onPlay,
          ),

          const SizedBox(height: 36),

          // ── 3 Satellite Actions ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SatelliteAction(
                icon: Icons.add_rounded,
                labelEn: 'Create\nSession',
                labelAr: 'إنشاء\nجلسة',
                isArabic: isArabic,
                onTap: onCreateSession,
              ),
              _SatelliteAction(
                icon: Icons.login_rounded,
                labelEn: 'Join\nSessions',
                labelAr: 'انضمام\nللجلسات',
                isArabic: isArabic,
                onTap: onJoinSessions,
              ),
              _SatelliteAction(
                icon: Icons.workspace_premium_rounded,
                labelEn: 'VIP\nStore',
                labelAr: 'متجر\nVIP',
                isArabic: isArabic,
                onTap: onVipAccess,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  SATELLITE ACTION — Small, elegant action tile
// ══════════════════════════════════════════════════════════════════

class _SatelliteAction extends StatefulWidget {
  const _SatelliteAction({
    required this.icon,
    required this.labelEn,
    required this.labelAr,
    required this.isArabic,
    required this.onTap,
  });

  final IconData icon;
  final String labelEn;
  final String labelAr;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  State<_SatelliteAction> createState() => _SatelliteActionState();
}

class _SatelliteActionState extends State<_SatelliteAction> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.93),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 90,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.royalGold.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: AppColors.royalGold.withValues(alpha: 0.55),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                widget.isArabic ? widget.labelAr : widget.labelEn,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFFF4E4B7).withValues(alpha: 0.65),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  PLAY MEDALLION — The only hero. Subtle pulsing glow.
// ══════════════════════════════════════════════════════════════════

class _PlayMedallion extends StatefulWidget {
  const _PlayMedallion({
    required this.isArabic,
    required this.glowAnim,
    required this.onTap,
  });

  final bool isArabic;
  final Animation<double> glowAnim;
  final VoidCallback onTap;

  @override
  State<_PlayMedallion> createState() => _PlayMedallionState();
}

class _PlayMedallionState extends State<_PlayMedallion> {
  double _scale = 1.0;

  void _handleTap() {
    setState(() => _scale = 1.05);
    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _scale = 1.0);
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: 170,
          height: 170,
          child: Stack(
            children: [
              // ── Layer 1: Animated glow only (repaints each frame) ──
              AnimatedBuilder(
                animation: widget.glowAnim,
                builder: (_, __) {
                  return Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.royalGold
                              .withValues(alpha: widget.glowAnim.value),
                          blurRadius: 50,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ── Layer 2: Static medallion content (never repaints) ──
              RepaintBoundary(
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.royalGold.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    gradient: const RadialGradient(
                      center: Alignment(0, -0.3),
                      radius: 0.9,
                      colors: [Color(0xFF1E2028), Color(0xFF0E1014)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '♠',
                        style: TextStyle(
                          color: AppColors.royalGold,
                          fontSize: 40,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.isArabic ? 'العب' : 'PLAY',
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFFF4E4B7),
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
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
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  BOTTOM NAV — Clash Royale style.
//  Active tab: icon pops bigger with gold bg box + label.
//  Inactive: smaller muted icon, no label.
// ══════════════════════════════════════════════════════════════════

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.isArabic,
    required this.currentIndex,
    required this.onTap,
  });

  final bool isArabic;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final labels = isArabic
        ? ['المتجر', 'المجتمع', 'الرئيسية', 'الدردشة', 'الدوريات']
        : ['Shop', 'Community', 'Home', 'Chat', 'Leagues'];

    // Filled, bold icons (like Clash Royale)
    final activeIcons = [
      Icons.storefront_rounded,
      Icons.people_rounded,
      Icons.home_rounded,
      Icons.chat_rounded,
      Icons.emoji_events_rounded,
    ];
    final inactiveIcons = [
      Icons.storefront_outlined,
      Icons.people_outline_rounded,
      Icons.home_outlined,
      Icons.chat_bubble_outline_rounded,
      Icons.emoji_events_outlined,
    ];

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D12),
        border: Border(
          top: BorderSide(
            color: AppColors.royalGold.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(5, (i) {
          final active = currentIndex == i;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                color: active
                    ? AppColors.royalGold.withValues(alpha: 0.12)
                    : Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: active ? 1.25 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        active ? activeIcons[i] : inactiveIcons[i],
                        size: 22,
                        color: active
                            ? AppColors.royalGold
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    // Label only for active tab
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: active
                          ? Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: AppColors.royalGold,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
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
}

// ══════════════════════════════════════════════════════════════════
//  QUICK MENU BUTTON — Clash Royale-style side popup
//  Tapping ☰ shows a small panel with 3 options:
//  1. Language  2. Alerts  3. Settings
// ══════════════════════════════════════════════════════════════════

class _QuickMenuButton extends StatelessWidget {
  const _QuickMenuButton({
    required this.onLanguage,
    required this.onAlerts,
    required this.onSettings,
  });

  final VoidCallback onLanguage;
  final VoidCallback onAlerts;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showQuickMenu(context),
      child: Container(
        width: 40,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.royalGold.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.menu_rounded,
          color: AppColors.royalGold.withValues(alpha: 0.8),
          size: 20,
        ),
      ),
    );
  }

  void _showQuickMenu(BuildContext context) {
    final locale = context.read<LocaleProvider>();
    final isArabic = locale.isArabic;

    // Get the button position to attach the menu right below it
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset buttonPos = button.localToGlobal(Offset.zero);
    final double menuTop = buttonPos.dy + button.size.height + 4;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Layout is always LTR — menu button is always on the right
    final double menuRight = screenWidth - buttonPos.dx - button.size.width;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'QuickMenu',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.15),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, _, __) {
        return Stack(
          children: [
            Positioned(
              top: menuTop,
              right: menuRight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 175,
                  decoration: BoxDecoration(
                    color: const Color(0xFF171A22),
                    // No rounded corner on top-right to visually connect to button
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                      topRight: Radius.circular(4),
                    ),
                    border: Border.all(
                      color: AppColors.royalGold.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Language toggle ──
                      _menuItem(
                        icon: isArabic
                            ? const Text('ع', style: TextStyle(color: AppColors.royalGold, fontSize: 15, fontWeight: FontWeight.w700))
                            : const Text('EN', style: TextStyle(color: AppColors.royalGold, fontSize: 11, fontWeight: FontWeight.w800)),
                        label: isArabic ? 'عربي' : 'English',
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          onLanguage();
                        },
                      ),
                      _divider(),
                      // ── Alerts ──
                      _menuItem(
                        icon: Icon(Icons.notifications_none_rounded, size: 18, color: AppColors.royalGold),
                        label: isArabic ? 'التنبيهات' : 'Alerts',
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          onAlerts();
                        },
                      ),
                      _divider(),
                      // ── Settings ──
                      _menuItem(
                        icon: Icon(Icons.settings_rounded, size: 18, color: AppColors.royalGold),
                        label: isArabic ? 'الإعدادات' : 'Settings',
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          onSettings();
                        },
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

  Widget _menuItem({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 22, child: Center(child: icon)),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: const Color(0xFFF4E4B7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AppColors.royalGold.withValues(alpha: 0.1),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  COMING SOON PAGE — Placeholder for unbuilt tabs
// ══════════════════════════════════════════════════════════════════

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({
    required this.title,
    required this.isArabic,
  });

  final String title;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Lock icon ──
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(
                color: AppColors.royalGold.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: AppColors.royalGold.withValues(alpha: 0.4),
              size: 30,
            ),
          ),

          const SizedBox(height: 20),

          // ── Title ──
          Text(
            title,
            style: GoogleFonts.montserrat(
              color: AppColors.royalGold.withValues(alpha: 0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 8),

          // ── Coming Soon ──
          Text(
            isArabic ? 'قريباً...' : 'Coming Soon',
            style: GoogleFonts.montserrat(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
