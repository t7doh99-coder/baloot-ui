import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../game_provider.dart';

class QaydhaResultOverlay extends StatelessWidget {
  const QaydhaResultOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isAr = context.watch<LocaleProvider>().isArabic;
    final font = isAr ? GoogleFonts.tajawal : GoogleFonts.readexPro;

    final result = game.qaydhaChallengeResult;
    if (result == null) return const SizedBox.shrink();
    final isSuccess = result.isCorrect;

    // Theming based on success or failure
    final primaryColor = isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
    final bgColor = isSuccess ? const Color(0xFF1B3B22) : const Color(0xFF3B1B1B);
    final iconData = isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined;
    
    final title = isSuccess
        ? (isAr ? 'قيد صحيح' : 'Successful Challenge')
        : (isAr ? 'قيد خاطئ' : 'Failed Challenge');
        
    final description = isSuccess
        ? (isAr ? 'تم إثبات حالة الغش بنجاح' : 'Cheating was successfully proven')
        : (isAr ? 'اتهام باطل، لم يتم إثبات الغش' : 'False accusation, cheating was not proven');

    final pointsText = isSuccess
        ? (isAr ? '+152 لك ولصديقك' : '+152 for you and your partner')
        : (isAr ? '+152 للفريق الخصم' : '+152 for the opposing team');

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {}, // Blocks taps
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Circle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: primaryColor, size: 64),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      title,
                      style: font(color: AppColors.pureWhite, fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    // Description
                    Text(
                      description,
                      style: font(color: const Color(0xFFAAAAAA), fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Points Mockup
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF444444)),
                      ),
                      child: Text(
                        pointsText,
                        style: font(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Continue Button
                    GestureDetector(
                      onTap: () {
                        game.closeQaydhaResult();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isAr ? 'متابعة' : 'Continue',
                          style: font(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
