import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../data/models/bot_difficulty.dart';
import '../game_provider.dart';

// ══════════════════════════════════════════════════════════════════
//  DIFFICULTY SELECTOR SHEET — Luxury Sandstone Dark Theme
//
//  Shows a localized modal bottom sheet before offline matches so the
//  player can choose AI difficulty (Easy / Medium / Hard).
// ══════════════════════════════════════════════════════════════════

class DifficultySelectorSheet extends StatefulWidget {
  const DifficultySelectorSheet({super.key});

  static Future<BotDifficulty?> show(BuildContext context) {
    return showModalBottomSheet<BotDifficulty>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const DifficultySelectorSheet(),
    );
  }

  @override
  State<DifficultySelectorSheet> createState() => _DifficultySelectorSheetState();
}

class _DifficultySelectorSheetState extends State<DifficultySelectorSheet> {
  BotDifficulty _selected = BotDifficulty.medium;

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<LocaleProvider>().isArabic;
    final titleFont = isAr ? GoogleFonts.cairo : GoogleFonts.readexPro;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1808), // bgCanvas
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFFC49028), width: 1.5)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Header Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF2C2210), // bgCard
              border: Border(
                top: BorderSide(color: Color(0xFF392C14), width: 1.0),
                bottom: BorderSide(color: Color(0xFF392C14), width: 2.5),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              isAr ? 'اختر مستوى الصعوبة' : 'Choose Difficulty',
              style: titleFont(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFDFAE45),
                letterSpacing: isAr ? 0 : 0.8,
                shadows: [
                  const Shadow(color: Color(0xFF392C14), offset: Offset(-1, -1)),
                  const Shadow(color: Color(0xFF392C14), offset: Offset(1, 1)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Cards Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _DiffCard(
                    title: isAr ? 'مبتدئ' : 'Beginner',
                    accent: Colors.greenAccent.shade700,
                    isSelected: _selected == BotDifficulty.easy,
                    isAr: isAr,
                    onTap: () => setState(() => _selected = BotDifficulty.easy),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DiffCard(
                    title: isAr ? 'عادي' : 'Regular',
                    accent: const Color(0xFFD4A017),
                    isSelected: _selected == BotDifficulty.medium,
                    isAr: isAr,
                    onTap: () => setState(() => _selected = BotDifficulty.medium),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DiffCard(
                    title: isAr ? 'خبير' : 'Expert',
                    accent: Colors.redAccent.shade700,
                    isSelected: _selected == BotDifficulty.hard,
                    isAr: isAr,
                    onTap: () => setState(() => _selected = BotDifficulty.hard),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Play Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () {
                context.read<GameProvider>().audioService.playGoldButton();
                Navigator.pop(context, _selected);
              },
              child: Container(
                width: double.infinity,
                height: 52,
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
                alignment: Alignment.center,
                child: Text(
                  isAr ? 'ابدأ اللعبة' : 'Start Game',
                  style: titleFont(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1808),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffCard extends StatelessWidget {
  final String title;
  final Color accent;
  final bool isSelected;
  final bool isAr;
  final VoidCallback onTap;

  const _DiffCard({
    required this.title,
    required this.accent,
    required this.isSelected,
    required this.isAr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleFont = isAr ? GoogleFonts.cairo : GoogleFonts.readexPro;
    final bodyFont = isAr ? GoogleFonts.tajawal : GoogleFonts.readexPro;

    return GestureDetector(
      onTap: () {
        context.read<GameProvider>().audioService.playNormalButton();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.15)
              : const Color(0xFF2C2210), // bgCard
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent : const Color(0xFF392C14),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon badge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accent : const Color(0xFF1E1808),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : accent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.smart_toy_rounded,
                color: isSelected ? Colors.black : accent,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: titleFont(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFFDFAE45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
