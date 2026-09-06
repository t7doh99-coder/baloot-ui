import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../game_provider.dart';
import 'qaydha_types.dart';

/// Qaid 3-Option Popup Menu: False Ekka, Wrong Sawa, Reveal Cards.
/// Placed directly above the Qaid button, overlapping cards on the left.
/// Intercepts all taps with HitTestBehavior.opaque to prevent selecting cards underneath.
class QaidPopupMenuWidget extends StatelessWidget {
  const QaidPopupMenuWidget({super.key});

  void _showInactiveHint(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 2200),
        backgroundColor: const Color(0xFF2C2210),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 130, left: 20, right: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFC49028), width: 1.5),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFF8EDD8),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: GoogleFonts.readexPro().fontFamily,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isAr = context.watch<LocaleProvider>().isArabic;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Absorb all taps inside the menu box container so they never pass to the cards below
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF231A0E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC49028), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0xCC000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. False Akka
            _buildMenuItem(
              context: context,
              label: isAr ? 'أكة خاطئة' : 'False Akka',
              isActive: game.isFalseEkkaWindowOpen,
              inactiveHint: isAr
                  ? 'متاحة فقط عند إعلان الخصم لورقة (أكة)'
                  : 'Active only when an opponent plays and declares an Akka!',
              onTap: () {
                game.closeQaidMenu();
                game.handleQaydhaMenuSelection(QaydhaActionType.wrongTrick);
              },
            ),
            const SizedBox(height: 6),
            // 2. False Sawa
            _buildMenuItem(
              context: context,
              label: isAr ? 'سوا خطأ' : 'False Sawa',
              isActive: game.isFalseSawaWindowOpen,
              inactiveHint: isAr
                  ? 'متاح فقط خلال الـ 7 ثوانٍ عندما يعلن الخصم (سوا)'
                  : 'Active only during the 7s countdown when an opponent claims Sawa!',
              onTap: () {
                game.closeQaidMenu();
                game.handleQaydhaMenuSelection(QaydhaActionType.wrongSawa);
              },
            ),
            const SizedBox(height: 6),
            // 3. Reveal Cards
            _buildMenuItem(
              context: context,
              label: isAr ? 'اكشف الورق' : 'Reveal Cards',
              isActive: game.canClaimQaid,
              inactiveHint: isAr
                  ? 'متاح فقط بعد انتهاء الأكلة الأولى'
                  : 'Active only after the first trick has been played!',
              onTap: () {
                game.closeQaidMenu();
                game.handleQaydhaMenuSelection(QaydhaActionType.reviewTricks);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String label,
    required bool isActive,
    required String inactiveHint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isActive) {
          onTap();
        } else {
          HapticFeedback.lightImpact();
          if (inactiveHint.isNotEmpty) {
            _showInactiveHint(context, inactiveHint);
          }
        }
      },
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2C2210) : const Color(0xFF1B140B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFFFFD54F) : const Color(0x22C49028),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFC49028).withValues(alpha: 0.35),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive) ...[
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF00E87A),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF7A6850),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: GoogleFonts.readexPro().fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
