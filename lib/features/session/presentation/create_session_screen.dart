import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/locale_provider.dart';
// ══════════════════════════════════════════════════════════════════
//  CREATE SESSION SCREEN — Plain & simple session creation
//
//  LOGIC_PLUG_IN:
//  • onCreateSession callback sends session config to backend
//  • All form values are captured via local state
//  • Replace debugPrint calls with ILobbyController methods
// ══════════════════════════════════════════════════════════════════

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _nameController = TextEditingController();

  // Form state
  int _gameType = 1; // 0 = Restricted, 1 = Free Play
  int _gameSpeed = 1; // 0 = 30s, 1 = 10s, 2 = 5s
  int _minLevel = 0; // 0 = Beginner, 1 = Intermediate, 2 = Expert

  final _gameTypes = ['Restricted Play', 'Free Play'];
  final _speeds = ['30 sec', '10 sec', '5 sec'];
  final _levels = ['Beginner', 'Intermediate', 'Expert'];

  // Arabic labels
  final _gameTypesAr = ['لعب مقيد', 'لعب حر'];
  final _speedsAr = ['30 ثانية', '10 ثوانٍ', '5 ثوانٍ'];
  final _levelsAr = ['مبتدئ', 'متوسط', 'خبير'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onCreate() {
    // LOGIC_PLUG_IN: Send session config to backend
    debugPrint('[CreateSession] name: ${_nameController.text}');
    debugPrint('[CreateSession] type: ${_gameTypes[_gameType]}');
    debugPrint('[CreateSession] speed: ${_speeds[_gameSpeed]}');
    debugPrint('[CreateSession] level: ${_levels[_minLevel]}');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      backgroundColor: AppColors.antigravityBlack,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            _topBar(context, isArabic),

            // ── Form ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Session Name ──
                    _sectionLabel(isArabic ? 'اسم الجلسة' : 'Session Name', isArabic),
                    const SizedBox(height: 8),
                    _nameField(isArabic),

                    const SizedBox(height: 24),

                    // ── Game Type ──
                    _sectionLabel(isArabic ? 'نوع اللعب' : 'Game Type', isArabic),
                    const SizedBox(height: 8),
                    _segmentedPicker(
                      isArabic: isArabic,
                      items: isArabic ? _gameTypesAr : _gameTypes,
                      selected: _gameType,
                      onTap: (i) => setState(() => _gameType = i),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _gameType == 0
                          ? (isArabic
                              ? 'لا يمكن القطع أو التقييد'
                              : 'Standard rules, no cutting allowed')
                          : (isArabic
                              ? 'يمكنك القطع والتقييد'
                              : 'Free Play lets you cut and restrict'),
                      style: GoogleFonts.readexPro(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Game Speed ──
                    _sectionLabel(isArabic ? 'سرعة اللعب' : 'Game Speed', isArabic),
                    const SizedBox(height: 8),
                    _segmentedPicker(
                      isArabic: isArabic,
                      items: isArabic ? _speedsAr : _speeds,
                      selected: _gameSpeed,
                      onTap: (i) => setState(() => _gameSpeed = i),
                    ),

                    const SizedBox(height: 24),

                    // ── Minimum Play Level ──
                    _sectionLabel(
                        isArabic ? 'الحد الأدنى للمستوى' : 'Minimum Play Level', isArabic),
                    const SizedBox(height: 8),
                    _segmentedPicker(
                      isArabic: isArabic,
                      items: isArabic ? _levelsAr : _levels,
                      selected: _minLevel,
                      onTap: (i) => setState(() => _minLevel = i),
                    ),
                  ],
                ),
              ),
            ),

            // ── Create Button ──
            _createButton(isArabic),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ──
  Widget _topBar(BuildContext context, bool isArabic) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.royalGold.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Invisible spacer to keep title centered
          const SizedBox(width: 36),
          const Spacer(),
          Text(
            isArabic ? 'إنشاء جلسة' : 'Create Session',
            style: GoogleFonts.readexPro(
              color: const Color(0xFFF4E4B7),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: isArabic ? 0 : 0.5,
            ),
          ),
          const Spacer(),
          // Back chevron (top-right)
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/chevron-left.png',
                width: 28,
                height: 28,
                color: AppColors.royalGold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Label ──
  Widget _sectionLabel(String text, bool isArabic) {
    return Text(
      text,
      style: GoogleFonts.readexPro(
        color: AppColors.royalGold.withValues(alpha: 0.6),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: isArabic ? 0 : 0.5,
      ),
    );
  }

  // ── Name Input ──
  Widget _nameField(bool isArabic) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.royalGold.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          // Lock icon
          Container(
            width: 42,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.royalGold.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
            child: Icon(
              Icons.lock_outline,
              color: AppColors.royalGold.withValues(alpha: 0.5),
              size: 18,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _nameController,
              style: GoogleFonts.readexPro(
                color: const Color(0xFFF4E4B7),
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: isArabic ? 'اسم الجلسة' : 'Session Name',
                hintStyle: GoogleFonts.readexPro(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Segmented Picker ──
  Widget _segmentedPicker({
    required bool isArabic,
    required List<String> items,
    required int selected,
    required ValueChanged<int> onTap,
  }) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.royalGold.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.royalGold.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: active
                      ? Border.all(
                          color: AppColors.royalGold.withValues(alpha: 0.4),
                          width: 1,
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    items[i],
                    style: GoogleFonts.readexPro(
                      color: active
                          ? const Color(0xFFF4E4B7)
                          : Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: isArabic ? 0 : 0.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Create Session Button (no cost) ──
  Widget _createButton(bool isArabic) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: GestureDetector(
        onTap: _onCreate,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF37), Color(0xFFB8960B)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.royalGold.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              isArabic ? 'إنشاء جلسة' : 'Create Session',
              style: GoogleFonts.readexPro(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: isArabic ? 0 : 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
