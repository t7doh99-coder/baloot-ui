import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_player_avatar.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/vip_background_shell.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../session/presentation/create_session_screen.dart';
import '../../game/presentation/game_table_screen.dart';
import '../../game/presentation/game_loading_screen.dart';
import '../../game/presentation/widgets/difficulty_selector_sheet.dart';
import '../../game/presentation/game_provider.dart';
import '../../game/presentation/table_background_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../game/presentation/widgets/playing_card.dart';
import '../../../data/models/card_model.dart';
import '../../../data/models/bot_difficulty.dart';
import 'game_mode_result_screen.dart';
import 'widgets/premium_subscription_popup.dart';
import 'navigation_shell.dart';
import 'alerts_screen.dart';
import 'player_profile_screen.dart';
import 'widgets/animated_flame_icon.dart';
import 'package:baloot_game/core/painters/diamond_painter.dart';
import '../../../data/models/rank_tier.dart';
import '../../../core/services/rank_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';
// (section)
// (section)
//  For "Test 3" menu item. No changes to the original home screen.
// (section)

// (section)
class _T3GameMode {
  final String id;
  final String? sectionHeader;
  final String name;
  final String? subtitleIcon;
  final String? desc;
  final Color leftColorStart;
  final Color leftColorEnd;
  final Color rightColorStart;
  final Color rightColorEnd;
  final IconData? rightIcon;
  final String? iconAsset;
  final String? patternType;

  const _T3GameMode({
    required this.id,
    this.sectionHeader,
    required this.name,
    this.subtitleIcon,
    this.desc,
    required this.leftColorStart,
    required this.leftColorEnd,
    required this.rightColorStart,
    required this.rightColorEnd,
    this.rightIcon,
    this.iconAsset,
    this.patternType,
  });
}

List<_T3GameMode> _getT3Modes(bool isArabic) => [
  _T3GameMode(
    id: 'trophy_road',
    name: isArabic ? 'بلوت' : 'Baloot',
    desc: isArabic ? 'أونلاين' : 'Online',
    leftColorStart: Color(0xFF392C14),  // bgElevated
    leftColorEnd: Color(0xFF2C2210),    // bgCard
    rightColorStart: Color(0xFF473618), // bgPanel
    rightColorEnd: Color(0xFF392C14),   // bgElevated
    rightIcon: Icons.emoji_events,
    iconAsset: 'assets/icons/cards.png',
  ),
  _T3GameMode(
    id: 'merge_tactics',
    name: isArabic ? 'بلوت أوفلاين' : 'Baloot Offline',
    desc: isArabic ? 'أوفلاين' : 'Offline',
    leftColorStart: Color(0xFF473618),  // bgPanel
    leftColorEnd: Color(0xFF2C2210),    // bgCard
    rightColorStart: Color(0xFFC49028), // sandGold
    rightColorEnd: Color(0xFF886018),   // sandGoldDark
    rightIcon: Icons.star_rounded,
    iconAsset: 'assets/icons/user.png',
  ),
  _T3GameMode(
    id: 'ranked',
    sectionHeader: isArabic ? 'الأطوار التنافسية' : 'Competitive Modes',
    name: isArabic ? 'إنشاء جلسة' : 'Create Session',
    desc: isArabic ? 'غرفة خاصة • العب مع الأصدقاء' : 'Private Room • Play with Friends',
    leftColorStart: Color(0xFF392C14),  // bgElevated
    leftColorEnd: Color(0xFF2C2210),    // bgCard
    rightColorStart: Color(0xFF473618), // bgPanel
    rightColorEnd: Color(0xFF392C14),   // bgElevated
    rightIcon: Icons.lock_rounded,
    patternType: 'diamonds',
    iconAsset: 'assets/icons/gamepad.png',
  ),
  _T3GameMode(
    id: 'classic_1v1',
    sectionHeader: isArabic ? 'الأطوار الكلاسيكية' : 'Classic Modes',
    name: isArabic ? 'الانضمام لجلسة' : 'Join Sessions',
    desc: isArabic ? 'انضم لغرفة • أدخل الرمز للعب' : 'Join Room • Enter Code to Play',
    leftColorStart: Color(0xFF2C2210),  // bgCard
    leftColorEnd: Color(0xFF1E1808),    // bgCanvas
    rightColorStart: Color(0xFF392C14), // bgElevated
    rightColorEnd: Color(0xFF2C2210),   // bgCard
    rightIcon: Icons.shield,
    iconAsset: 'assets/icons/vs.png',
  ),
];

// (section)
class _Ripple {
  final int id;
  final AnimationController ctrl;
  _Ripple({required this.id, required this.ctrl});
}

class HomeScreen extends StatefulWidget {
  final bool isArabic;
  const HomeScreen({super.key, this.isArabic = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 2; // Home is center tab

  // (section)
  String _selectedModeId = 'play';
  BotDifficulty _savedOfflineDifficulty = BotDifficulty.medium;
  bool _isNavigating = false;
  bool _showModePanel = false;

  _T3GameMode get _selectedMode {
    final isArabic = context.read<LocaleProvider>().isArabic;
    return _getT3Modes(isArabic).firstWhere((m) => m.id == _selectedModeId,
        orElse: () => _getT3Modes(isArabic).first);
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedModeId = prefs.getString('last_mode_id') ?? 'play';
      final diffIndex = prefs.getInt('last_difficulty_index') ?? 1;
      if (diffIndex >= 0 && diffIndex < BotDifficulty.values.length) {
        _savedOfflineDifficulty = BotDifficulty.values[diffIndex];
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // (section)
  void _onPlayNow() async {
    if (_selectedModeId == 'merge_tactics') {
      // Offline mode selected: Use saved difficulty immediately
      _startGameFlow(_savedOfflineDifficulty);
    } else if (_selectedModeId == 'ranked') {
      // Create Session mode selected: Show create session bottom sheet
      final created = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => const _CreateSessionBottomSheet(),
      );
      if (created != true) return; // User dismissed
      
      _startGameFlow(BotDifficulty.medium);
    } else {
      // Online or other modes
      _startGameFlow(BotDifficulty.medium);
    }
  }

  void _startGameFlow(BotDifficulty difficulty) {
    if (_isNavigating) return;
    _isNavigating = true;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameLoadingScreen(difficulty: difficulty),
      ),
    ).then((_) {
      if (mounted) {
        _isNavigating = false;
      }
    });
  }

  void _onVipAccess() {
    showDialog(
      context: context,
      builder: (_) => const PremiumSubscriptionPopup(),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<LocaleProvider>().isArabic
              ? '$feature — قريباً!'
              : '$feature — Coming Soon!',
          style: GoogleFonts.readexPro(
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
    final isArabic = locale.isArabic;

    // Tab names for Coming Soon
    final tabNames = isArabic
        ? ['المتجر', 'المجتمع', 'الرئيسية', 'الدردشة', 'الدوريات']
        : ['Shop', 'Community', 'Home', 'Chat', 'Leagues'];

    return Scaffold(
      backgroundColor: const Color(0xFF080F12),
      body: Stack(
        children: [
          // Premium Quilted Diamond Background
          Positioned.fill(
            child: CustomPaint(painter: DiamondOnlyPainter()),
          ),

          // Main content column — includes bottom nav so panel can cover it
          SafeArea(
            child: Column(
              children: [
                _T1TopBar(isArabic: isArabic),
                if (_currentIndex == 2) ...[
                  const _T1PlayerCard(),
                ],
                Expanded(
                  child: _currentIndex == 2
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              // Play button row (same as Test 1's _buildPlayHub)
                              Padding(
                                padding: const EdgeInsets.only(top: 40, left: 12, right: 12),
                                child: _T3BattleRow(
                                  selectedMode: _selectedMode,
                                  savedOfflineDifficulty: _savedOfflineDifficulty,
                                  onPlayPress: _onPlayNow,
                                  onModePress: () =>
                                      setState(() => _showModePanel = true),
                                ),
                              ),
                              // Tournament banner — below play button, same as Test 1
                              _TournamentBanner(isArabic: isArabic),
                              const SizedBox(height: 14),
                            ],
                          ),
                        )
                      : _ComingSoonPage(
                          title: tabNames[_currentIndex],
                          isArabic: isArabic,
                        ),
                ),
                // Bottom nav is inside the column so panel can cover it
                _BottomNav(
                  isArabic: isArabic,
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
              ],
            ),
          ),

          // Game mode panel — Positioned.fill covers EVERYTHING including bottom nav
          if (_showModePanel)
            Positioned.fill(
              child: _T3GameModePanel(
                selectedModeId: _selectedModeId,
                savedOfflineDifficulty: _savedOfflineDifficulty,
                onSelect: (id) async {
                  setState(() => _selectedModeId = id);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('last_mode_id', id);

                  if (id == 'merge_tactics') {
                    setState(() {
                      _showModePanel = false;
                    });
                    final difficulty = await DifficultySelectorSheet.show(context);
                    if (difficulty != null) {
                      setState(() {
                        _savedOfflineDifficulty = difficulty;
                      });
                      await prefs.setInt('last_difficulty_index', difficulty.index);
                      _startGameFlow(difficulty);
                    }
                  }
                },
                onConfirm: (id) {
                  setState(() {
                    _selectedModeId = id;
                    _showModePanel = false;
                  });
                  _onPlayNow();
                },
                onClose: () => setState(() => _showModePanel = false),
              ),
            ),
        ],
      ),
    );
  }
}

// (section)
//  TEST-1 BACKGROUND PAINTERS  (nebula + grid)
// (section)

class _NebulaBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final nebulae = [
      (dx: 0.18, dy: 0.22, r: 0.32, c: const Color(0x260D4F46)),
      (dx: 0.82, dy: 0.14, r: 0.26, c: const Color(0x1A0D1A1F)),
      (dx: 0.5,  dy: 0.6,  r: 0.42, c: const Color(0x131A8C7A)),
      (dx: 0.12, dy: 0.75, r: 0.22, c: const Color(0x1A0D4F46)),
      (dx: 0.88, dy: 0.82, r: 0.28, c: const Color(0x130D1A1F)),
    ];
    for (final n in nebulae) {
      paint.shader = RadialGradient(
        colors: [n.c, Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * n.dx, size.height * n.dy),
        radius: size.width * n.r,
      ));
      canvas.drawCircle(
        Offset(size.width * n.dx, size.height * n.dy),
        size.width * n.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_NebulaBgPainter _) => false;
}

class _GridBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0D1A8C7A)
      ..strokeWidth = 0.5;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridBgPainter _) => false;
}

// ------------------------------------------------------------------------------------------
//  TEST-1 TOP BAR  (Baloot logo + suits + Alerts/Friends/Baloot/More)
// ------------------------------------------------------------------------------------------

class _T1TopBar extends StatelessWidget {
  final bool isArabic;
  const _T1TopBar({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(14, 8 + topPadding, 14, 12),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Center: both logo words forming a circle (with spacing between top & bottom arches)
            SizedBox(
              width: 140,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 1,
                    child: Image.asset(
                      'assets/images/logo-text2.png',
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    bottom: 1,
                    child: Image.asset(
                      'assets/images/logo-text1.png',
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            // Left: Alerts button (icon only)
            Positioned(
              left: 0,
              child: Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(builder: (_) => AlertsScreen(isArabic: isArabic)),
                    );
                  },
                  child: Container(
                    width: 50, height: 50,
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Image.asset('assets/icons/notification.png', width: 40, height: 40),
                  ),
                ),
              ),
            ),
            // Right: More button (icon only)
            Positioned(
              right: 0,
              child: Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => _showQuickMenu(ctx),
                  child: Container(
                    width: 50, height: 50,
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Image.asset('assets/icons/setting.png', width: 40, height: 40),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBarBtn({required String em, required String lbl, String? badge, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2210),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x12C49028)),
              boxShadow: const [
                BoxShadow(color: Color(0x72000000), blurRadius: 14, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(em, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 2),
                Text(lbl, style: GoogleFonts.readexPro(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF886018))),
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

  void _showQuickMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset buttonPos = button.localToGlobal(Offset.zero);
    final double menuTop = buttonPos.dy; // Align with the button
    final double screenWidth = MediaQuery.of(context).size.width;
    final double menuRight = screenWidth - buttonPos.dx + 4;

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
                          color: const Color(0xFF2C2210),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x42C49028), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _crMenuItem(context: dialogContext, icon: Icons.history_rounded, label: isArabic ? 'سجل المباريات' : 'Match History', onTap: () {}),
                            const SizedBox(height: 4),
                            _crMenuItem(context: dialogContext, icon: Icons.emoji_events_rounded, label: isArabic ? 'الإنجازات' : 'Achievements', onTap: () {}),
                            const SizedBox(height: 4),
                            _crMenuItem(context: dialogContext, icon: Icons.palette_rounded, label: isArabic ? 'التخصيص' : 'Customisation', onTap: () {}),
                            _divider(),
                            _crMenuItem(context: dialogContext, icon: Icons.settings_rounded, label: isArabic ? 'الإعدادات' : 'Settings', onTap: () {
                              Navigator.pop(dialogContext);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(isArabic: isArabic)));
                            }),
                            const SizedBox(height: 4),
                            _crMenuItem(context: dialogContext, icon: Icons.language_rounded, label: isArabic ? 'Language : ARABIC' : 'Language : EN', onTap: () {
                              Navigator.pop(dialogContext);
                              context.read<LocaleProvider>().toggleLocale();
                            }),
                            _divider(),
                            _crMenuItem(context: dialogContext, icon: Icons.help_outline_rounded, label: isArabic ? 'المساعدة والدعم' : 'Help & Support', onTap: () {}),
                            const SizedBox(height: 4),
                            _crMenuItem(context: dialogContext, icon: Icons.shield_rounded, label: isArabic ? 'الخصوصية' : 'Privacy', onTap: () {
                              Navigator.pop(dialogContext);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const NavigationShell()));
                            }),
                            _divider(),
                            _crMenuItem(context: dialogContext, icon: Icons.logout_rounded, label: isArabic ? 'تسجيل الخروج' : 'Log Out', onTap: () => Navigator.pop(dialogContext)),
                          ],
                        ),
                      ),
                      // Arrow pointing right
                      Positioned(
                        top: 24,
                        left: 222, // 230 - 8 (center over border)
                        child: Transform.rotate(
                          angle: 0.785398, // 45 degrees
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2C2210),
                              border: Border(
                                top: BorderSide(color: Color(0x42C49028), width: 1.5),
                                right: BorderSide(color: Color(0x42C49028), width: 1.5),
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
          color: const Color(0xFFC49028), // Dark blue bottom edge -> actually Gold bottom edge
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
                    colors: [Color(0xFFE5C170), Color(0xFFC49028)],
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
                          style: GoogleFonts.readexPro(
                            fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white,
                            letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 0.5,
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
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: const Color(0x42C49028),
    );
  }
}

// (section)
//  TEST-1 PLAYER CARD  (full animated card from NewHomeScreenPreview)
// (section)

class _T1PlayerCard extends StatefulWidget {
  const _T1PlayerCard();

  @override
  State<_T1PlayerCard> createState() => _T1PlayerCardState();
}

class _AnimatedChestBtn extends StatefulWidget {
  const _AnimatedChestBtn();
  @override
  State<_AnimatedChestBtn> createState() => _AnimatedChestBtnState();
}

class _AnimatedChestBtnState extends State<_AnimatedChestBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat();
  }
  
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        // Wiggle only during a short portion of the cycle
        double angle = 0.0;
        double scale = 1.0;
        if (t < 0.2) {
          final p = t / 0.2; // 0 to 1
          angle = math.sin(p * math.pi * 4) * 0.15;
          scale = 1.0 + math.sin(p * math.pi) * 0.15;
        }
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2C2210),
            border: Border.all(color: const Color(0xFFC0962B), width: 2.5),
            boxShadow: [
              if (t < 0.2)
                const BoxShadow(
                  color: Color(0x66FFD700),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
            ],
          ),
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: Image.asset(
                'assets/icons/gift.png',
                width: 26,
                height: 26,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _T1PlayerCardState extends State<_T1PlayerCard>
    with TickerProviderStateMixin {
  // Design tokens — Sandstone palette
  static const _kG   = Color(0xFFC49028);  // sandGold
  static const _kGL  = Color(0xFF886018);  // sandGoldDark
  static const _kGD  = Color(0xFF886018);  // sandGoldDark
  static const _kGX  = Color(0xFF7A4E10);  // honeyDark
  static const _kCYN = Color(0xFFC49028);  // sandGold (for star chip)
  static const _kRED = Color(0xFF8B2020);  // crimson
  static const Color _bgTop    = Color(0xFF2C2210);  // bgCard
  static const Color _bgBot    = Color(0xFF1E1808);  // bgCanvas
  static const Color _tileTop  = Color(0xFF392C14);  // bgElevated
  static const Color _tileMid  = Color(0xFF2C2210);  // bgCard
  static const Color _tileBot  = Color(0xFF1E1808);  // bgCanvas
  static const Color _tileShdw = Color(0x60080400);  // near-black warm shadow
  static const Color _tileDark = Color(0xFF141008);  // very dark sandy bevel
  static const Color _tileLight= Color(0xFF4A3818);  // muted sandy light bevel
  static const _kGRN = Color(0xFF886018);
  static const _kBG  = Color(0xFF2C2210);  // bgCard

  late final AnimationController _avatarRingCtrl;
  late final AnimationController _avatarFloatCtrl;
  late final AnimationController _xpFillCtrl;
  late final AnimationController _xpStarCtrl;
  late final AnimationController _cardGlowCtrl;
  late final AnimationController _vipPulseCtrl;
  late final AnimationController _onlineDotCtrl;
  late final AnimationController _streakCtrl;
  late final AnimationController _coinFloatCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _goldTextCtrl;
  bool _starVisible = false;

  @override
  void initState() {
    super.initState();
    _avatarRingCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();
    _avatarFloatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat(reverse: true);
    _xpFillCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
    _xpStarCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _cardGlowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat(reverse: true);
    _vipPulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _onlineDotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _streakCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _coinFloatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5500))..repeat();
    _goldTextCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _starVisible = true);
        _xpStarCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cardGlowCtrl,
      builder: (_, child) {
        final glow = 22.0 + _cardGlowCtrl.value * 16.0;
        final innerAlpha = (0.13 + _cardGlowCtrl.value * 0.15).clamp(0.0, 1.0);
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2210),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x42C49028)),  // sandBorder
            boxShadow: [
              const BoxShadow(color: Color(0x8C000000), blurRadius: 44, offset: Offset(0, 14)),
              BoxShadow(color: Color.fromARGB((innerAlpha * 255).round(), 196, 144, 40), blurRadius: glow),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Shimmer overlay
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
                            colors: [Colors.transparent, Color(0x0EC49028), Colors.transparent],
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
                    colors: [Colors.transparent, Color(0x38C49028), Colors.transparent],
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
                  const SizedBox(height: 16),
                  _buildPlayerProfile(context),
                  const SizedBox(height: 16),
                  _buildXPBar(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyBar(BuildContext context) {
    final game = context.watch<GameProvider>();
    final stats = game.playerStats;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _chip(em: '⭐', val: '${stats.blueStars}', accent: const Color(0xFFC9A84C), idx: 0, iconWidget: Image.asset('assets/icons/gold_star.png', width: 20, height: 20))),
        const SizedBox(width: 8),
        Expanded(child: _chip(em: '🌟', val: '0', accent: const Color(0xFFB87818), idx: 1, iconWidget: Image.asset('assets/icons/silver_star.png', width: 20, height: 20))),
        const SizedBox(width: 8),
        Expanded(child: _chip(em: '❤️', val: '0', accent: const Color(0xFF8B2A38), idx: 2, iconWidget: Image.asset('assets/icons/heart.png', width: 20, height: 20))),
      ],
    );
  }

  Widget _buildPlayerProfile(BuildContext context) {
    final stats = context.watch<GameProvider>().playerStats;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSubscribeCTA(),
            _chestBtn(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerProfileScreen(isArabic: context.read<LocaleProvider>().isArabic)));
              },
              child: _buildAvatarFrame(),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(stats.playerName, style: GoogleFonts.readexPro(
                  fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white,
                  height: 1.1,
                  shadows: const [Shadow(color: Color(0x40FFD700), blurRadius: 14)],
                )),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _buildCardFan(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCardFan() {
    return SizedBox(
      width: 100,
      height: 60,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Rightmost card (Face up, rendered first so it sits at the BOTTOM)
          Positioned(
            left: 45,
            bottom: 0,
            child: Transform.rotate(
              angle: 0.25, // Leans Right
              alignment: Alignment.bottomLeft,
              child: const PlayingCard(
                faceUp: true,
                card: CardModel(suit: Suit.spades, rank: Rank.seven),
                size: CardSize.small,
              ),
            ),
          ),
          // Middle card (Face down, sits in the middle)
          Positioned(
            left: 45,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.05, // Almost straight up, leans slightly Left
              alignment: Alignment.bottomLeft,
              child: const PlayingCard(faceUp: false, back: CardBack.blue, size: CardSize.small),
            ),
          ),
          // Leftmost card (Face down, rendered last so it sits ON TOP of all others)
          Positioned(
            left: 45,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.35, // Leans strongly Left
              alignment: Alignment.bottomLeft,
              child: const PlayingCard(faceUp: false, back: CardBack.blue, size: CardSize.small),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({required String em, required String val, required Color accent, int idx = 0, Widget? iconWidget}) {
    // Heart pill gets crimson bg, others get sand-based bg
    final bool isHeart = em == '❤️';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isHeart ? const Color(0xFF1A080C) : const Color(0x1A392C14),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: isHeart ? const Color(0x668B2A38) : const Color(0x47C49028)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _FadingLeftBorderPainter(accent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 2), // small spacer from the colored edge
          Expanded(
            child: AnimatedBuilder(
              animation: _coinFloatCtrl,
              builder: (_, __) {
                double scale = 1.0;
                double dy = math.sin((_coinFloatCtrl.value + idx * 0.3) * math.pi) * -2.0;
                
                if (em == '❤️') {
                  final t = _coinFloatCtrl.value;
                  if (t < 0.1) {
                    scale = 1.0 + math.sin(t * 10 * math.pi) * 0.2;
                  } else if (t > 0.15 && t < 0.25) {
                    scale = 1.0 + math.sin((t - 0.15) * 10 * math.pi) * 0.2;
                  }
                }
                
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.scale(
                    scale: scale,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        iconWidget ?? Text(em, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(val, style: GoogleFonts.readexPro(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldenBadge() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF161510),
        border: Border.all(color: const Color(0xFFC0962B), width: 3.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FFD700),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/icons/ticket.png',
        width: 28,
        height: 28,
      ),
    );
  }

  Widget _chestBtn() {
    return const _AnimatedChestBtn();
  }

  Widget _buildAvatarFrame() {
    return SizedBox(
      width: 108, height: 108,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _avatarRingCtrl,
            builder: (_, __) {
              return Transform.rotate(
                angle: _avatarRingCtrl.value * 2 * math.pi,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [Color(0xFF886018), Color(0xFF4A3408), Color(0xFFC49028), Color(0xFF886018)],  // sandy gold conic ring
                      stops: [0.0, 0.40, 0.70, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(top: 3, left: 3, right: 3, bottom: 3,
            child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2C2A1F)))),
          Positioned(top: 6, left: 6, right: 6, bottom: 6,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x8C886018), width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x66886018), blurRadius: 18),
                  BoxShadow(color: Color(0x1A4A3818), blurRadius: 0, spreadRadius: 5),
                ],
              ),
            ),
          ),
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
                      colors: [Color(0xFF2C2210), Color(0xFF1E1808), Color(0xFF141008)],  // bgCard to bgCanvas
                      stops: [0, 0.6, 1],
                    ),
                  ),
                   alignment: Alignment.center,
                   child: Stack(
                     children: [
                       // Avatar Image
                       Positioned.fill(
                         child: ClipOval(
                           child: Consumer<GameProvider>(
                             builder: (context, game, _) => CustomPlayerAvatar(
                               seatIndex: 0,
                               customAvatarPath: game.playerStats.customAvatarPath,
                             ),
                           ),
                         ),
                       ),
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
                     ],
                   ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(String rank) {
    const color = Color(0xFFC49028);  // sandGold
    const bg = Color(0xFF080F12);     // bgCanvas on sand badge
    return ClipPath(
      clipper: _T1HexClipper(),
      child: Container(
        width: 72, height: 30, color: bg,
        alignment: Alignment.center,
        child: Text(
          '✶ $rank',
          style: GoogleFonts.readexPro(fontSize: 11, fontWeight: FontWeight.w900, color: color,
            shadows: [Shadow(color: color.withValues(alpha: 0.7), blurRadius: 8)]),
        ),
      ),
    );
  }


  Widget _buildWinStreak(int count) {
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
              gradient: const LinearGradient(colors: [Color(0x38886018), Color(0x26C49028)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x66C49028)),
              boxShadow: const [BoxShadow(color: Color(0x4DC49028), blurRadius: 10)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Text('$count Wins', style: GoogleFonts.readexPro(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFC49028))),
              ],
            ),
          ),
        );
      },
    );
  }

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
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset('assets/icons/medal.png', width: 22, height: 22),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x1F392C14),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x47C49028), width: 1.2),
              ),
              child: Text(
                rank.englishName,
                style: GoogleFonts.readexPro(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFC49028),
                  letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 1.2,
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  isMax ? 'Max Rank' : '${stats.medals} of $nextThreshold',
                  style: GoogleFonts.readexPro(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF886018)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (ctx, cst) {
            final trackWidth = cst.maxWidth;
            return Stack(
              children: [
                Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0x14C49028)),
                  ),
                ),
                AnimatedBuilder(
                  animation: _xpFillCtrl,
                  builder: (_, __) {
                    final pct = targetPct;
                    return Container(
                      width: trackWidth * pct,
                      height: 9,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF886018), Color(0xFFC49028), Color(0xFFDFAE45)]),  // sandy gold gradient
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: const [BoxShadow(color: Color(0xB2C49028), blurRadius: 12)],
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

  Widget _buildSubscribeCTA() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => const PremiumSubscriptionPopup(),
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2C2210),
          border: Border.all(color: const Color(0xFF886018), width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33C49028),
              blurRadius: 12,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Image.asset(
          'assets/icons/ticket.png',
          width: 28,
          height: 28,
        ),
      ),
    );
  }
}

// (section)
//  HEX CLIPPER  (for rank badge shape)
// (section)

class _T1HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    const r = 8.0;
    return Path()
      ..moveTo(r * 1.4, 0)
      ..lineTo(s.width - r * 1.4, 0)
      ..lineTo(s.width, s.height / 2)
      ..lineTo(s.width - r * 1.4, s.height)
      ..lineTo(r * 1.4, s.height)
      ..lineTo(0, s.height / 2)
      ..close();
  }

  @override
  bool shouldReclip(_T1HexClipper _) => false;
}

// (section)
// (section)
// (section)

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
          // (section)
          Flexible(
            child: _avatarChip(context.watch<LocaleProvider>().isArabic),
          ),
          // (section)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CRCurrencyBar(
                    value: coins,
                    iconImage: 'assets/images/dollar.png',
                    barColor: const Color(0xFF3B2D10),
                    barBorder: const Color(0xFF7A6529),
                    btnColors: const [Color(0xFFD4AF37), Color(0xFFB8960B)],
                  ),
                  const SizedBox(width: 6),
                  _CRCurrencyBar(
                    value: gems,
                    iconImage: 'assets/images/gem.png',
                    barColor: const Color(0xFF3B2D10),
                    barBorder: const Color(0xFF7A6529),
                    btnColors: const [Color(0xFFD4AF37), Color(0xFFB8960B)],
                  ),
                ],
              ),
              // (section)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _QuickMenuButton(
                  onLanguage: () {
                    final locale = context.read<LocaleProvider>();
                    locale.toggleLocale();
                  },
                  onAlerts: () {
                    debugPrint('[Menu] Alerts tapped');
                  },
                  onSettings: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarChip(bool isArabic) {
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
          // (section)
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
          // (section)
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
                    letterSpacing: isArabic ? 0 : 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                // (section)
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

// (section)
// (section)
// (section)

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

// (section)
//  CLASH ROYALE-STYLE CURRENCY BAR
// (section)

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
          // The green 'add' block on the left
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

          // (section)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              value,
              style: GoogleFonts.readexPro(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing:
                    context.read<LocaleProvider>().isArabic ? 0 : 0.3,
              ),
            ),
          ),

          // (section)
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

// (section)
// (section)
// (section)

class _T3BattleRow extends StatefulWidget {
  final _T3GameMode selectedMode;
  final VoidCallback onPlayPress;
  final VoidCallback onModePress;
  final BotDifficulty savedOfflineDifficulty;

  const _T3BattleRow({
    required this.selectedMode,
    required this.onPlayPress,
    required this.onModePress,
    required this.savedOfflineDifficulty,
  });

  @override
  State<_T3BattleRow> createState() => _T3BattleRowState();
}

class _BeltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rectHeight = 74.0;
    final rectTop = (size.height - rectHeight) / 2;
    final circleRadius = size.height / 2;

    final path = Path.combine(
      PathOperation.union,
      Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, rectTop, size.width, rectHeight),
          const Radius.circular(22),
        )),
      Path()
        ..addOval(Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: circleRadius,
        )),
    );

    // Shadow
    canvas.drawPath(
      path.shift(const Offset(0, 2)),
      Paint()
        ..color = const Color(0xFF040C24).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Fill
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2C2210), Color(0xFF1E1808)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFFC49028).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BoldChevronUp extends StatelessWidget {
  final double size;
  const _BoldChevronUp({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.6),
      painter: _BoldChevronPainter(),
    );
  }
}

class _BoldChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final padding = 3.0;
    final path = Path()
      ..moveTo(padding, size.height - padding)
      ..lineTo(size.width / 2, padding)
      ..lineTo(size.width - padding, size.height - padding);

    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _T3BattleRowState extends State<_T3BattleRow>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<LocaleProvider>().isArabic;
    return SizedBox(
      height: 130, // The height of the central belt bulge
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // (section)
          Positioned.fill(
            child: CustomPaint(
              painter: _BeltPainter(),
            ),
          ),

          // (section)
          Positioned(
            left: isAr ? null : 0,
            right: isAr ? 0 : null,
            width: (MediaQuery.sizeOf(context).width - 32 - 130) / 2,
            child: Center(
              child: GestureDetector(
                onTap: widget.onModePress,
                child: AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 120),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0x12C49028),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0xB22C2210), offset: Offset(0, 4))
                      ],
                    ),
                    child: Image.asset(
                      widget.selectedMode.iconAsset ?? 'assets/icons/vs.png',
                      width: 36,
                      height: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // (section)
          Positioned(
            right: isAr ? null : 0,
            left: isAr ? 0 : null,
            width: (MediaQuery.sizeOf(context).width - 32 - 130) / 2,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onModePress,
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    Text(
                      widget.selectedMode.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.readexPro(
                        color: const Color(0xFFC49028),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 3),
                        ],
                      ),
                    ),
                    if (widget.selectedMode.id == 'merge_tactics') ...[
                      const SizedBox(height: 1),
                      Text(
                        isAr
                          ? 'الطور : ${switch (widget.savedOfflineDifficulty) {
                              BotDifficulty.easy => 'مبتدئ',
                              BotDifficulty.medium => 'عادي',
                              BotDifficulty.hard => 'خبير',
                            }}'
                          : 'MODE : ${switch (widget.savedOfflineDifficulty) {
                              BotDifficulty.easy => 'BEGINNER',
                              BotDifficulty.medium => 'REGULAR',
                              BotDifficulty.hard => 'EXPERT',
                            }}',
                        style: GoogleFonts.readexPro(
                          color: const Color(0xFFC49028),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 3),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    const _BoldChevronUp(size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),

          // (section)
          _T3GreenPlayButton(
            onPlay: widget.onPlayPress,
          ),
        ],
      ),
    );
  }
}

// (section)
//  T3 GREEN PLAY BUTTON (Ported from Test 1)
// (section)
class _T3GreenPlayButton extends StatefulWidget {
  final VoidCallback onPlay;
  const _T3GreenPlayButton({required this.onPlay});

  @override
  State<_T3GreenPlayButton> createState() => _T3GreenPlayButtonState();
}

class _T3GreenPlayButtonState extends State<_T3GreenPlayButton>
    with TickerProviderStateMixin {
  late AnimationController _playOuterCtrl;
  late AnimationController _playInnerCtrl;
  late List<AnimationController> _fireCtrl;
  late AnimationController _fireBurstCtrl;
  late AnimationController _searchDotsCtrl;
  late AnimationController _playGlowCtrl;

  bool _searching = false;
  bool _pressed = false;
  bool _fireBurst = false;
  final List<_Ripple> _ripples = [];
  int _rippleId = 0;

  @override
  void initState() {
    super.initState();
    _playOuterCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 11))
          ..repeat();
    _playInnerCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 18))
          ..repeat();

    _fireCtrl = List.generate(5, (i) {
      return AnimationController(
          vsync: this, duration: Duration(milliseconds: 2200 + i * 200))
        ..repeat(reverse: true);
    });

    _fireBurstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _searchDotsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
    _playGlowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _playOuterCtrl.dispose();
    _playInnerCtrl.dispose();
    for (final c in _fireCtrl) {
      c.dispose();
    }
    for (final r in _ripples) {
      r.ctrl.dispose();
    }
    _fireBurstCtrl.dispose();
    _searchDotsCtrl.dispose();
    _playGlowCtrl.dispose();
    super.dispose();
  }

  void _handlePlay() {
    if (_searching) return;
    
    // Play the golden play button sound
    context.read<GameProvider>().audioService.playEffect('ply button sound.mp3');

    // Ripple
    final id = _rippleId++;
    final ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 720));
    setState(() => _ripples.add(_Ripple(id: id, ctrl: ctrl)));
    ctrl.forward().then((_) {
      if (mounted) {
        setState(() => _ripples.removeWhere((r) => r.id == id));
        ctrl.dispose();
      }
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

    // Searching state
    setState(() {
      _searching = true;
      _pressed = true;
    });

    // Call the parent callback
    widget.onPlay();

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _searching = false;
          _pressed = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Transform to make it fit nicely in the belt shape height
    return Transform.scale(
      scale: 0.88, // Scaled up slightly for the new belt shape
      child: GestureDetector(
        onTap: _handlePlay,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            clipBehavior: Clip.none,
            children: [


              // Ripple rings
              ..._ripples.map((r) => _buildRippleRing(r)),
              // Outer rotating ring
              AnimatedBuilder(
                animation: _playOuterCtrl,
                builder: (_, __) {
                  return Transform.rotate(
                    angle: _playOuterCtrl.value * 2 * 3.14159,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xA5C49028),
                            Colors.transparent,
                            Color(0x61FFD700),
                            Colors.transparent,
                            Color(0xA5C49028),
                            Colors.transparent,
                            Colors.transparent,
                          ],
                          stops: [
                            0,
                            0.153,
                            0.306,
                            0.458,
                            0.611,
                            0.778,
                            0.931,
                            1.0
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Dark gap 1
              Positioned(
                  top: 5,
                  left: 5,
                  right: 5,
                  bottom: 5,
                  child: Container(
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFA080312)))),
              // Inner ring (counter-rotate)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                bottom: 8,
                child: AnimatedBuilder(
                  animation: _playInnerCtrl,
                  builder: (_, __) {
                    return Transform.rotate(
                      angle: -_playInnerCtrl.value * 2 * 3.14159,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Colors.transparent,
                              Color(0x59FFD700),
                              Colors.transparent,
                              Colors.transparent,
                              Color(0x59FFD700),
                              Colors.transparent,
                              Colors.transparent,
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
              Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Container(
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFA080312)))),
              // Core button
              Positioned(
                  top: 15,
                  left: 15,
                  right: 15,
                  bottom: 15,
                  child: _buildPlayCore()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurvedFire(int i) {
    const sizes = [14.0, 18.0, 23.0, 18.0, 14.0];
    const angles = [-2.27, -1.92, -1.57, -1.22, -0.87];
    final angle = angles[i];
    const radius = 108.0;
    const cx = 80.0;
    const cy = 80.0;

    return Positioned(
      left: cx - sizes[i] / 2 + radius * math.cos(angle),
      top: cy - sizes[i] / 2 + radius * math.sin(angle),
      child: Transform.rotate(
        angle: angle + math.pi / 2,
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
                    child: SvgPicture.asset(
                      'assets/icons/flame.svg',
                      width: sizes[i] * 2.2,
                      height: sizes[i] * 2.2,
                      colorFilter: const ColorFilter.mode(Color(0xFFC49028), BlendMode.srcIn),
                    ),
                  ),
                ),
              );
            } else {
              final curve = Curves.easeInOutSine.transform(_fireCtrl[i].value);
              final dy = -(curve * sizes[i] * 0.32);
              final scale = 1.0 + curve * 0.18;
              return Transform.translate(
                offset: Offset(0, dy),
                child: Transform.scale(
                  scale: scale,
                  child: SvgPicture.asset(
                    'assets/icons/flame.svg',
                    width: sizes[i] * 2.2,
                    height: sizes[i] * 2.2,
                    colorFilter: const ColorFilter.mode(Color(0xFFC49028), BlendMode.srcIn),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildRippleRing(_Ripple ripple) {
    final idx = _ripples.indexOf(ripple);
    const borderColors = [
      Color(0xB2C49028),
      Color(0x80886018),
      Color(0x66FFD700)
    ];
    final bc = borderColors[idx.clamp(0, borderColors.length - 1)];
    return AnimatedBuilder(
      animation: ripple.ctrl,
      builder: (_, __) {
        final t =
            CurvedAnimation(parent: ripple.ctrl, curve: Curves.easeOut).value;
        final scale = 1.0 + t * 1.6;
        final opacity = (1.0 - t).clamp(0.0, 0.8);
        return Positioned.fill(
          child: Transform.scale(
            scale: scale,
            child: Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: bc.withValues(alpha: opacity), width: 2.5),
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
                colors: [
                  Color(0xFFE5C170),
                  Color(0xFFC49028),
                  Color(0xFF886018),
                  Color(0xFF392C14)
                ],
                stops: [0, 0.42, 0.8, 1],
              ),
              border: Border.all(color: const Color(0x61C49028), width: 2),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFC49028).withValues(alpha: opacity1),
                    blurRadius: blur1),
                BoxShadow(
                    color: const Color(0xFFC49028).withValues(alpha: opacity2),
                    blurRadius: blur2),
                BoxShadow(
                    color: const Color(0xFF886018).withValues(alpha: opacity3),
                    blurRadius: blur3),
                if (t > 0.1)
                  BoxShadow(
                      color: const Color(0xFFFFD700)
                          .withValues(alpha: (t * 0.25).clamp(0.0, 0.25)),
                      blurRadius: t * 10.0),
              ],
            ),
            child: child,
          );
        },
        child: Stack(
          children: [

            // Inner ring line
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
    final isArabic = context.read<LocaleProvider>().isArabic;
    return Text(
      isArabic ? '\u0627\u0644\u0639\u0628' : 'Play',
      key: const ValueKey('play'),
      style: GoogleFonts.readexPro(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 1.5,
        shadows: const [
          Shadow(
            color: Color(0x8C000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
    );
  }

  Widget _searchingLabel() {
    final isArabic = context.read<LocaleProvider>().isArabic;
    return Column(
      key: const ValueKey('searching'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(isArabic ? '\u062c\u0627\u0631\u064a \u0627\u0644\u0628\u062d\u062b' : 'Searching',
            style: GoogleFonts.readexPro(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _searchDotsCtrl,
              builder: (_, __) {
                final val = (_searchDotsCtrl.value - i * 0.2) % 1.0;
                // Using a simplified animation for the dots rather than direct sin math
                final double opacity =
                    0.2 + 0.8 * Curves.easeInOutSine.transform(val);
                final double dy = -3.0 * Curves.easeInOutSine.transform(val);
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white
                          .withValues(alpha: opacity.clamp(0.0, 1.0)),
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
}

// (section)
// (section)
// (section)

class _HandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw outer handle
    final outerPath = Path();
    final double oInset = 28.0;
    final double oR = 12.0;
    
    outerPath.moveTo(oInset + oR, 0);
    outerPath.lineTo(size.width - oInset - oR, 0);
    outerPath.quadraticBezierTo(size.width - oInset, 0, size.width - oInset + oR*0.3, oR*0.8);
    outerPath.lineTo(size.width, size.height);
    outerPath.lineTo(0, size.height);
    outerPath.lineTo(oInset - oR*0.3, oR*0.8);
    outerPath.quadraticBezierTo(oInset, 0, oInset + oR, 0);
    outerPath.close();

    final outerFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF392C14), Color(0xFF1E1808)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(outerPath, outerFill);

    final outerBorder = Paint()
      ..color = const Color(0xFFC49028)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final oBorderPath = Path();
    oBorderPath.moveTo(0, size.height);
    oBorderPath.lineTo(oInset - oR*0.3, oR*0.8);
    oBorderPath.quadraticBezierTo(oInset, 0, oInset + oR, 0);
    oBorderPath.lineTo(size.width - oInset - oR, 0);
    oBorderPath.quadraticBezierTo(size.width - oInset, 0, size.width - oInset + oR*0.3, oR*0.8);
    oBorderPath.lineTo(size.width, size.height);
    canvas.drawPath(oBorderPath, outerBorder);

    // 2. Draw inner button
    final double iTopY = 8.0;
    final double iBottomY = size.height - 8.0;
    final double iLeftBottomX = 14.0;
    final double iRightBottomX = size.width - 14.0;
    final double iSlope = 22.0; 
    final double iLeftTopX = iLeftBottomX + iSlope;
    final double iRightTopX = iRightBottomX - iSlope;
    final double iRTop = 8.0;
    final double iRBot = 6.0;

    final innerPath = Path();
    innerPath.moveTo(iLeftTopX + iRTop, iTopY);
    innerPath.lineTo(iRightTopX - iRTop, iTopY);
    innerPath.quadraticBezierTo(iRightTopX, iTopY, iRightTopX + iRTop*0.3, iTopY + iRTop*0.8);
    innerPath.lineTo(iRightBottomX - iRBot*0.3, iBottomY - iRBot*0.8);
    innerPath.quadraticBezierTo(iRightBottomX, iBottomY, iRightBottomX - iRBot, iBottomY);
    innerPath.lineTo(iLeftBottomX + iRBot, iBottomY);
    innerPath.quadraticBezierTo(iLeftBottomX, iBottomY, iLeftBottomX + iRBot*0.3, iBottomY - iRBot*0.8);
    innerPath.lineTo(iLeftTopX - iRTop*0.3, iTopY + iRTop*0.8);
    innerPath.quadraticBezierTo(iLeftTopX, iTopY, iLeftTopX + iRTop, iTopY);
    innerPath.close();

    final bevelPath = innerPath.shift(const Offset(0, 3));
    final bevelPaint = Paint()..color = const Color(0xFF141008);
    canvas.drawPath(bevelPath, bevelPaint);

    final innerFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC49028), Color(0xFF886018)],
      ).createShader(Rect.fromLTRB(0, iTopY, 0, iBottomY));
    canvas.drawPath(innerPath, innerFill);

    // 3. Draw Glossy Top Reflection
    final glossPath = Path();
    final double gBotY = iTopY + (iBottomY - iTopY) * 0.45;
    final double gLeftBotX = iLeftTopX - (iSlope * 0.45);
    final double gRightBotX = iRightTopX + (iSlope * 0.45);
    
    glossPath.moveTo(iLeftTopX + iRTop, iTopY);
    glossPath.lineTo(iRightTopX - iRTop, iTopY);
    glossPath.quadraticBezierTo(iRightTopX, iTopY, iRightTopX + iRTop*0.3, iTopY + iRTop*0.8);
    glossPath.lineTo(gRightBotX, gBotY);
    glossPath.quadraticBezierTo(size.width / 2, gBotY + 3, gLeftBotX, gBotY);
    glossPath.lineTo(iLeftTopX - iRTop*0.3, iTopY + iRTop*0.8);
    glossPath.quadraticBezierTo(iLeftTopX, iTopY, iLeftTopX + iRTop, iTopY);
    glossPath.close();

    final glossPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x99FFFFFF), Color(0x11FFFFFF)],
      ).createShader(Rect.fromLTRB(0, iTopY, 0, gBotY));
    canvas.drawPath(glossPath, glossPaint);

    final innerBorder = Paint()
      ..color = const Color(0xFFDFAE45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(innerPath, innerBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.2);
    path.lineTo(size.width * 0.5, size.height * 0.8);
    path.lineTo(size.width, size.height * 0.2);

    final strokePaint = Paint()
      ..color = const Color(0xFF141008)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _T3GameModePanel extends StatelessWidget {
  final String selectedModeId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onConfirm;
  final VoidCallback onClose;
  final BotDifficulty savedOfflineDifficulty;

  const _T3GameModePanel({
    required this.selectedModeId,
    required this.onSelect,
    required this.onConfirm,
    required this.onClose,
    required this.savedOfflineDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Panel is now in Positioned.fill on the body Stack,
        // so constraints.maxHeight = full body height (above bottom nav).
        // 75% reaches up to mid-player-card area.
        final panelHeight = constraints.maxHeight * 0.62;
        return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.6)),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: panelHeight,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // The main bar
                    Container(
                      margin: const EdgeInsets.only(top: 46),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2C2210),
                        border: Border(
                          top: BorderSide(color: Color(0xFFC49028), width: 1.5),
                          bottom: BorderSide(color: Color(0xFF392C14), width: 3.0),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        context.read<LocaleProvider>().isArabic ? 'أطوار اللعب' : 'Game Modes',
                        style: GoogleFonts.readexPro(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFDFAE45),
                          letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 1.2,
                          shadows: [
                            const Shadow(color: Color(0xFF392C14), offset: Offset(-1, -1)),
                            const Shadow(color: Color(0xFF392C14), offset: Offset(1, 1)),
                          ],
                        ),
                      ),
                    ),
                    // The handle
                    Positioned(
                      top: 0,
                      child: GestureDetector(
                        onTap: onClose,
                        child: CustomPaint(
                          painter: _HandlePainter(),
                          child: Container(
                            width: 150,
                            height: 48,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.only(top: 2), // Adjust arrow position
                            child: CustomPaint(
                              size: const Size(22, 11),
                              painter: _ChevronPainter(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1808),  // bgCanvas
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + MediaQuery.paddingOf(context).bottom),
                      itemCount: _getT3Modes(context.read<LocaleProvider>().isArabic).length,
                      itemBuilder: (context, i) {
                        final mode = _getT3Modes(context.read<LocaleProvider>().isArabic)[i];
                        
                        Widget card = _T3TicketCard(
                          mode: mode,
                          isSelected: mode.id == selectedModeId,
                          onSelect: () => onSelect(mode.id),
                          savedOfflineDifficulty: savedOfflineDifficulty,
                        );

                        if (mode.sectionHeader != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: Container(height: 1, color: const Color(0x47C49028))),  // sandBorder
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      mode.sectionHeader!,
                                      style: GoogleFonts.readexPro(
                                        color: const Color(0xFF886018),  // sandGoldDark
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Container(height: 1, color: const Color(0x47C49028))),  // sandBorder
                                ],
                              ),
                              const SizedBox(height: 14),
                              card,
                            ],
                          );
                        }

                        return card;
                      },
                    ),
                ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
      },
    );
  }
}

// (section)
class _T3SheetOption extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _T3SheetOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  State<_T3SheetOption> createState() => _T3SheetOptionState();
}

class _T3SheetOptionState extends State<_T3SheetOption> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: const Color(0xFFD4AF37).withValues(alpha: 0.75),
                size: 22,
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.readexPro(
                      color: const Color(0xFFF4E4B7),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 0.3,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: GoogleFonts.readexPro(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class _TicketPainter extends CustomPainter {
  final Color leftStart;
  final Color leftEnd;
  final Color rightStart;
  final Color rightEnd;
  final bool isSelected;
  final String? patternType;

  _TicketPainter({
    required this.leftStart,
    required this.leftEnd,
    required this.rightStart,
    required this.rightEnd,
    this.isSelected = false,
    this.patternType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double rightPanelWidth = 80.0;
    final double radius = 12.0;
    final double notchRadius = 6.0;
    
    // Main ticket path
    final path = Path();
    path.moveTo(radius, 0);
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius));
    
    // Top right notch
    path.lineTo(size.width, size.height * 0.25 - notchRadius);
    path.arcToPoint(Offset(size.width, size.height * 0.25 + notchRadius), 
        radius: Radius.circular(notchRadius), clockwise: false);
        
    // Bottom right notch
    path.lineTo(size.width, size.height * 0.75 - notchRadius);
    path.arcToPoint(Offset(size.width, size.height * 0.75 + notchRadius), 
        radius: Radius.circular(notchRadius), clockwise: false);
        
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(Offset(size.width - radius, size.height), radius: Radius.circular(radius));
    
    path.lineTo(radius, size.height);
    path.arcToPoint(Offset(0, size.height - radius), radius: Radius.circular(radius));
    path.lineTo(0, radius);
    path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
    path.close();

    // Clip to path for painting halves
    canvas.save();
    canvas.clipPath(path);

    // Left half
    final leftRect = Rect.fromLTRB(0, 0, size.width - rightPanelWidth, size.height);
    final leftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [leftStart, leftEnd],
      ).createShader(leftRect);
    canvas.drawRect(leftRect, leftPaint);

    // Pattern for left half
    if (patternType == 'diamonds') {
      final patternPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      double spacing = 20.0;
      for (double i = -size.height; i < size.width; i += spacing) {
        canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), patternPaint);
        canvas.drawLine(Offset(i + size.height, 0), Offset(i, size.height), patternPaint);
      }
    }

    // Right half
    final rightRect = Rect.fromLTRB(size.width - rightPanelWidth, 0, size.width, size.height);
    final rightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [rightStart, rightEnd],
      ).createShader(rightRect);
    canvas.drawRect(rightRect, rightPaint);

    canvas.restore(); // Restore clip

    // Inner shadow / 3D Bevel
    final bevelPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));
    canvas.translate(1, 1);
    canvas.drawPath(path, bevelPaint);
    canvas.restore();
    
    final shadowBevelPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));
    canvas.translate(-1, -1);
    canvas.drawPath(path, shadowBevelPaint);
    canvas.restore();

    // Divider line
    final dividerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 2.0;
    canvas.drawLine(
        Offset(size.width - rightPanelWidth, 0), 
        Offset(size.width - rightPanelWidth, size.height), 
        dividerPaint);

    // Border if selected
    if (isSelected) {
      final borderPaint = Paint()
        ..color = const Color(0xFFF5C432)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawPath(path, borderPaint);
    } else {
      final borderPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TicketPainter oldDelegate) {
    return oldDelegate.leftStart != leftStart ||
           oldDelegate.isSelected != isSelected;
  }
}

class _T3TicketCard extends StatelessWidget {
  final _T3GameMode mode;
  final bool isSelected;
  final VoidCallback onSelect;
  final BotDifficulty savedOfflineDifficulty;

  const _T3TicketCard({
    required this.mode,
    required this.isSelected,
    required this.onSelect,
    required this.savedOfflineDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 80,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0x662BB89F) : const Color(0x66000000),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: CustomPaint(
          painter: _TicketPainter(
            leftStart: mode.leftColorStart,
            leftEnd: mode.leftColorEnd,
            rightStart: mode.rightColorStart,
            rightEnd: mode.rightColorEnd,
            isSelected: isSelected,
            patternType: mode.patternType,
          ),
          child: Row(
            children: [
              // Left Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mode.name,
                        style: GoogleFonts.readexPro(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          shadows: const [
                            Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 2),
                            Shadow(color: Colors.black87, offset: Offset(-1, 1), blurRadius: 2),
                          ],
                        ),
                      ),
                      if (mode.desc != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (mode.subtitleIcon != null) ...[
                              Text(mode.subtitleIcon!, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              mode.id == 'merge_tactics' 
                                  ? '${mode.desc!} • ${savedOfflineDifficulty.name.toUpperCase()}'
                                  : mode.desc!,
                              style: GoogleFonts.readexPro(
                                color: const Color(0xFFFFD700),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                              ),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              // Right Icon
              SizedBox(
                width: 80,
                child: Center(
                  child: Image.asset(
                    mode.iconAsset ?? 'assets/icons/vs.png',
                    width: 48,
                    height: 48,
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

// (section)
// (section)
// (section)

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.isArabic,
    required this.currentIndex,
    required this.onTap,
  });

  final bool isArabic;
  final int currentIndex;
  final ValueChanged<int> onTap;

  // Sandy gold — active nav (Sandstone palette)
  static const _kCYN = Color(0xFFDFAE45);  // sandGoldLight — active nav

  @override
  Widget build(BuildContext context) {
    final nav = [
      (icon: 'assets/icons/backpack.png', lbl: isArabic ? 'المتجر' : 'Store'),
      (icon: 'assets/icons/team.png', lbl: isArabic ? 'المجتمع' : 'Community'),
      (icon: 'assets/icons/home.png', lbl: isArabic ? 'الرئيسية' : 'Home'),
      (icon: 'assets/icons/trophy.png', lbl: isArabic ? 'البطولات' : 'Tournament'),
      (icon: 'assets/icons/chat.png', lbl: isArabic ? 'دردشة' : 'Chat'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1808),  // bgCanvas
        border: Border(top: BorderSide(color: Color(0x21FFFFFF))),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Top shimmer line
            Positioned(
              top: 0, left: 16, right: 16, height: 1,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    Color(0x38C49028),
                    Color(0x38DFAE45),
                    Color(0x38C49028),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: nav.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final on = currentIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          decoration: BoxDecoration(
                            color: on ? const Color(0x1FC49028) : null,  // sandGold tint
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: on ? const Color(0x38C49028) : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Active indicator dot
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: on ? 24 : 0,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: on ? _kCYN : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: on
                                      ? const [
                                          BoxShadow(color: Color(0xFFDFAE45), blurRadius: 14),
                                          BoxShadow(color: Color(0x6BDFAE45), blurRadius: 28),
                                        ]
                                      : null,
                                ),
                              ),
                              Opacity(
                                opacity: on ? 1.0 : 0.5,
                                child: Image.asset(
                                  item.icon,
                                  width: 26,
                                  height: 26,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  item.lbl,
                                  maxLines: 1,
                                  style: GoogleFonts.readexPro(
                                    fontSize: 9.5,
                                    fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                                    color: on ? _kCYN : const Color(0xFF806840),
                                  ),
                                ),
                              ),
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

// ---------------------------------------------------------------------------
//  COMING SOON PAGE  (placeholder for non-home tabs)
// ---------------------------------------------------------------------------

class _ComingSoonPage extends StatelessWidget {
  final String title;
  final bool isArabic;
  const _ComingSoonPage({required this.title, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_rounded, size: 64, color: Color(0x40FFD700)),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.readexPro(
              fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0x80FFD700),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic ? 'Coming Soon...' : 'Coming Soon',
            style: GoogleFonts.readexPro(fontSize: 14, color: const Color(0x40FFD700)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  QUICK MENU BUTTON  (used by _TopBar legacy nav shell)
// ---------------------------------------------------------------------------

class _QuickMenuButton extends StatelessWidget {
  final VoidCallback onLanguage;
  final VoidCallback onAlerts;
  final VoidCallback onSettings;
  const _QuickMenuButton({
    required this.onLanguage,
    required this.onAlerts,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _menuBtn(context, icon: Icons.language_rounded, onTap: onLanguage),
        const SizedBox(width: 8),
        _menuBtn(context, icon: Icons.notifications_outlined, onTap: onAlerts),
        const SizedBox(width: 8),
        _menuBtn(context, icon: Icons.settings_rounded, onTap: onSettings),
      ],
    );
  }

  Widget _menuBtn(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: const Color(0x26FFD700)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: const Color(0x8CFFD700)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TOURNAMENT BANNER  (ported 1:1 from Test 1)
// ══════════════════════════════════════════════════════════════

class _TournamentBanner extends StatefulWidget {
  final bool isArabic;
  const _TournamentBanner({required this.isArabic});

  @override
  State<_TournamentBanner> createState() => _TournamentBannerState();
}

class _TournamentBannerState extends State<_TournamentBanner>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;    // 2.5s glow pulse
  late AnimationController _shimmerCtrl; // 3.5s shimmer sweep

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Column(
        children: [
          // ── "Baloot Cup" divider title ──────────────────────
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0x591A8C7A)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '· · · Live now · · ·',
                  style: GoogleFonts.readexPro(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: const Color(0x59C49028),  // sandGold muted
                    letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 3,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x59C49028), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Animated glow wrapper ───────────────────────────
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, child) {
              final glow = 22.0 + _glowCtrl.value * 28.0;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                   boxShadow: [
                    BoxShadow(color: const Color(0x61C49028), blurRadius: glow),  // sandGold glow
                  ],
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
                    // Base dark teal gradient card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF151108),  // very dark sandy warm
                            Color(0xFF1E1A0A),  // mid sandy warm
                            Color(0xFF181408),  // dark sandy base
                          ],
                          stops: [0, 0.4, 1],
                        ),
                        border: Border.all(color: const Color(0x33C49028)),  // sandBorder rgba(196,144,40,0.20)
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Text('🏆',
                              style: TextStyle(fontSize: 34)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isArabic
                                    ? 'كأس رويال'
                                    : 'Royal Cup',
                                  style: GoogleFonts.readexPro(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFC49028),  // sandGold
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.isArabic
                                      ? 'مباشر الآن · ادخل الكأس'
                                      : 'Live now · Enter the cup',
                                  style: GoogleFonts.readexPro(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                   color: const Color(0x73B87818),  // honey muted — subtitle
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Text('🃏',
                                  style: TextStyle(fontSize: 28)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Shimmer sweep overlay
                    AnimatedBuilder(
                      animation: _shimmerCtrl,
                      builder: (_, __) {
                        final tx =
                            (_shimmerCtrl.value * 2.0 - 0.5) * 400;
                        return Positioned.fill(
                          child: Transform.translate(
                            offset: Offset(tx, 0),
                            child: Container(
                              width: 80,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0x52FFFFFF),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Top highlight line
                    Positioned(
                      top: 0, left: 30, right: 30, height: 1,
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FadingLeftBorderPainter extends CustomPainter {
  final Color color;
  _FadingLeftBorderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(50));
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [color, color.withValues(alpha: 0.0)],
        stops: const [0.0, 0.45], // Fades out completely by the middle
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _FadingLeftBorderPainter old) => old.color != color;
}

// (section)
//  DIFFICULTY BOTTOM SHEET (Sandstone Dark themed)
// (section)

// (removed old _DifficultyBottomSheet in favor of public DifficultySelectorSheet)

// (section)
//  CREATE SESSION BOTTOM SHEET (Sandstone Dark themed)
// (section)

class _CreateSessionBottomSheet extends StatefulWidget {
  const _CreateSessionBottomSheet();

  @override
  State<_CreateSessionBottomSheet> createState() => _CreateSessionBottomSheetState();
}

class _CreateSessionBottomSheetState extends State<_CreateSessionBottomSheet> {
  bool _isPrivate = false;
  int _playType = 1; // 0: Restricted, 1: Free
  int _playSpeed = 1; // 0: 30s, 1: 10s, 2: 5s

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.readexPro(
          color: const Color(0xFFB5A992), // textSec
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 0.5,
        ),
      ),
    );
  }

  Widget _buildSegmentedControl({
    required List<String> items,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1808), // bgCanvas
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF392C14), width: 1.5),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF392C14) : Colors.transparent, // bgElevated
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: const Color(0xFFC49028), width: 1.5) // sandGold
                      : Border.all(color: Colors.transparent, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  items[index],
                  style: GoogleFonts.readexPro(
                    color: isSelected ? const Color(0xFFF8EDD8) : const Color(0xFFB5A992),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1808), // bgCanvas
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFFC49028), width: 1.5)),
      ),
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF2C2210), // bgCard
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(color: Color(0xFF392C14), width: 3.0),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'Create Session',
              style: GoogleFonts.readexPro(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFDFAE45),
                letterSpacing: context.read<LocaleProvider>().isArabic ? 0 : 1.2,
                shadows: [
                  const Shadow(color: Color(0xFF392C14), offset: Offset(-1, -1)),
                  const Shadow(color: Color(0xFF392C14), offset: Offset(1, 1)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Privacy Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionLabel('Private Room (Friends Only)'),
                    Switch(
                      value: _isPrivate,
                      activeColor: const Color(0xFF1E1808),
                      activeTrackColor: const Color(0xFFC49028),
                      inactiveThumbColor: const Color(0xFFB5A992),
                      inactiveTrackColor: const Color(0xFF2C2210),
                      onChanged: (val) => setState(() => _isPrivate = val),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Play Type
                _buildSectionLabel('Play Type'),
                _buildSegmentedControl(
                  items: const ['Restricted', 'Free Play'],
                  selectedIndex: _playType,
                  onSelect: (idx) => setState(() => _playType = idx),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    _playType == 1 ? 'Free Play lets you cut and restrict.' : 'Standard rules.',
                    style: GoogleFonts.readexPro(
                      color: const Color(0xFFB5A992).withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),

                // Play Speed
                _buildSectionLabel('Play Speed'),
                _buildSegmentedControl(
                  items: const ['🐢 30s', '🐇 10s', '🚀 5s'],
                  selectedIndex: _playSpeed,
                  onSelect: (idx) => setState(() => _playSpeed = idx),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 36),

          // Create Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () => Navigator.pop(context, true), // Return true to indicate creation
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDFAE45), Color(0xFFB8860B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDFAE45).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create Session',
                      style: GoogleFonts.readexPro(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E1808),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1808).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '100',
                            style: GoogleFonts.readexPro(
                              color: const Color(0xFF1E1808),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



