import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../settings/presentation/settings_screen.dart';

// ══════════════════════════════════════════════════════════════════
//  NAVIGATION SHELL — Luxury Minimalism Game Hub
//  Client directive: "1–2 taps to game. No clutter. Premium."
//
//  ARCHITECTURE NOTES:
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
  int _currentIndex = 2; // Home is center tab, default active

  // Medallion pulsing glow
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.15, end: 0.4).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  // ── Hub action callbacks ──
  // LOGIC_PLUG_IN: Replace these with ILobbyController methods

  void _onPlayNow() {
    // TODO: Implement matchmaking / open game table
    debugPrint('[LobbyAction] Play Now tapped');
  }

  void _onCreateSession() {
    // TODO: Navigate to session creation flow
    debugPrint('[LobbyAction] Create Session tapped');
  }

  void _onJoinSessions() {
    // TODO: Navigate to session browser / list
    debugPrint('[LobbyAction] Join Sessions tapped');
  }

  void _onVipAccess() {
    // TODO: Navigate to VIP subscription / paywall
    debugPrint('[LobbyAction] VIP Access tapped');
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final userProvider = context.watch<UserProvider>();
    final isArabic = localeProvider.isArabic;
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: AppColors.antigravityBlack,
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Stack(
          children: [
            // ── Layer 0: Static premium dark background ──
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFF1C1F26),
                    Color(0xFF0A0C10),
                    Color(0xFF050608),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // ── Layer 1: Content ──
            SafeArea(
              child: Column(
                children: [
                  // ── Top Bar ──
                  _CompactTopBar(
                    username: user.username,
                    coins: user.coinsFormatted,
                    gems: user.gemsFormatted,
                  ),

                  // ── Game Hub (centered) ──
                  Expanded(
                    child: Center(
                      child: _GameHub(
                        isArabic: isArabic,
                        glowAnim: _glowAnim,
                        onPlay: _onPlayNow,
                        onCreateSession: _onCreateSession,
                        onJoinSessions: _onJoinSessions,
                        onVipAccess: _onVipAccess,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
//  COMPACT TOP BAR — Profile chip + Currency + Settings
//  No language toggle here (moved to Settings screen)
// ══════════════════════════════════════════════════════════════════

class _CompactTopBar extends StatelessWidget {
  const _CompactTopBar({
    required this.username,
    required this.coins,
    required this.gems,
  });

  /// All data comes from UserProvider — no hardcoded strings
  final String username;
  final String coins;
  final String gems;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          // ── Profile chip ──
          _profileChip(),
          const Spacer(),
          // ── Currency pills ──
          _currencyPill(coins, Icons.monetization_on,
              const [Color(0xFFFFD700), Color(0xFFB45309)]),
          const SizedBox(width: 6),
          _currencyPill(gems, Icons.diamond,
              const [Color(0xFF4ADE80), Color(0xFF14532D)]),
          const SizedBox(width: 6),
          // ── Settings (3-bar menu) ──
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: Container(
              width: 34,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0x991C1F26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.18)),
              ),
              child: Icon(
                Icons.menu,
                color: AppColors.royalGold.withValues(alpha: 0.6),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileChip() {
    return Container(
      height: 38,
      padding: const EdgeInsets.fromLTRB(4, 3, 12, 3),
      decoration: BoxDecoration(
        color: const Color(0x991C1F26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.royalGold, width: 1.2),
            ),
            child: const CircleAvatar(
              backgroundColor: Color(0xFF2B3140),
              child: Icon(Icons.person, size: 16, color: Color(0xFFD6B146)),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            username,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencyPill(String value, IconData icon, List<Color> gradient) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: gradient),
            ),
            child: Icon(icon, size: 11, color: Colors.white),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  GAME HUB — Play medallion + 3 actions in cross layout
//  All callbacks are exposed as required parameters.
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

  /// LOGIC_PLUG_IN: Wire these to ILobbyController
  final VoidCallback onPlay;
  final VoidCallback onCreateSession;
  final VoidCallback onJoinSessions;
  final VoidCallback onVipAccess;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Top action: Create Session ──
        _ActionChip(
          icon: Icons.add_circle_outline,
          labelEn: 'Create Session',
          labelAr: 'إنشاء جلسة',
          isArabic: isArabic,
          onTap: onCreateSession,
        ),
        const SizedBox(height: 20),

        // ── Middle row: Join | PLAY | VIP ──
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionChip(
              icon: Icons.list_alt_outlined,
              labelEn: 'Join\nSessions',
              labelAr: 'انضم\nللجلسات',
              isArabic: isArabic,
              onTap: onJoinSessions,
            ),
            const SizedBox(width: 16),
            _PlayMedallion(
              isArabic: isArabic,
              glowAnim: glowAnim,
              onTap: onPlay,
            ),
            const SizedBox(width: 16),
            _ActionChip(
              icon: Icons.workspace_premium_outlined,
              labelEn: 'VIP\nAccess',
              labelAr: 'عضوية\nVIP',
              isArabic: isArabic,
              onTap: onVipAccess,
              highlighted: true,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Bottom: Quick Match ──
        _ActionChip(
          icon: Icons.sports_esports_outlined,
          labelEn: 'Quick Match',
          labelAr: 'مباراة سريعة',
          isArabic: isArabic,
          onTap: onPlay, // Same as play for now
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  ACTION CHIP — Glassmorphism tile with exposed onTap callback
// ══════════════════════════════════════════════════════════════════

class _ActionChip extends StatefulWidget {
  const _ActionChip({
    required this.icon,
    required this.labelEn,
    required this.labelAr,
    required this.isArabic,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String labelEn;
  final String labelAr;
  final bool isArabic;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.94),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 100,
          height: 68,
          decoration: BoxDecoration(
            color: widget.highlighted
                ? AppColors.royalGold.withValues(alpha: 0.08)
                : const Color(0x800A0C10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.highlighted
                  ? AppColors.royalGold.withValues(alpha: 0.5)
                  : AppColors.royalGold.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: AppColors.royalGold.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                widget.isArabic ? widget.labelAr : widget.labelEn,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFFF4E4B7).withValues(alpha: 0.8),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  height: 1.3,
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
//  PLAY MEDALLION — The hero. Pulsing gold glow. Exposed onTap.
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
    setState(() => _scale = 1.06);
    Future.delayed(const Duration(milliseconds: 150), () {
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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: widget.glowAnim,
          builder: (_, __) {
            return Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.royalGold.withValues(alpha: 0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalGold
                        .withValues(alpha: widget.glowAnim.value),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 136,
                  height: 136,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.royalGold, width: 1.5),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1C22), Color(0xFF0D0F14)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '♠',
                        style: TextStyle(
                          color: AppColors.royalGold,
                          fontSize: 36,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isArabic ? 'العب' : 'Play',
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFFF4E4B7),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isArabic ? 'الآن' : 'Now',
                        style: GoogleFonts.montserrat(
                          color: AppColors.royalGold.withValues(alpha: 0.6),
                          fontSize: 11,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  BOTTOM NAV — Refined gold/grey states
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
        ? ['المتجر', 'المجتمع', 'الرئيسية', 'الدوريات', 'الدردشة']
        : ['Store', 'Community', 'Home', 'Tournaments', 'Chat'];
    final icons = [
      Icons.storefront_outlined,
      Icons.people_outline,
      Icons.home_rounded,
      Icons.emoji_events_outlined,
      Icons.chat_bubble_outline,
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F14),
        border: Border(
          top: BorderSide(
            color: AppColors.royalGold.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: List.generate(5, (i) {
          final active = currentIndex == i;
          final isHome = i == 2;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Gold dot indicator for active
                  if (active)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.royalGold,
                      ),
                    )
                  else
                    const SizedBox(height: 8),

                  Icon(
                    icons[i],
                    size: isHome ? 26 : 20,
                    color: active
                        ? AppColors.royalGold
                        : AppColors.royalGold.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 0.3,
                      color: active
                          ? const Color(0xFFF4E4B7)
                          : AppColors.royalGold.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
