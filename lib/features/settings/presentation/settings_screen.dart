import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/locale_provider.dart';

// ══════════════════════════════════════════════════════════════════
//  SETTINGS PANEL — Clash Royale-inspired modal overlay
//  Opens as a dialog, not a full page.
//
//  Usage:
//    SettingsPanel.show(context);
// ══════════════════════════════════════════════════════════════════

class SettingsPanel {
  SettingsPanel._();

  /// Show the settings panel as a centered modal dialog
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, __) => const _SettingsPanelContent(),
    );
  }
}

class _SettingsPanelContent extends StatelessWidget {
  const _SettingsPanelContent();

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isArabic = locale.isArabic;

    return Center(
      child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          margin: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: const Color(0xFF141720),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.royalGold.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.royalGold.withValues(alpha: 0.08),
                blurRadius: 30,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header: Title + Close ──
                _header(context, isArabic),

                // ── Body ──
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Account Section ──
                        _sectionCard(
                          children: [
                            _accountRow(isArabic),
                            const SizedBox(height: 10),
                            _connectedBadge(isArabic),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ── Audio & Language Row ──
                        Row(
                          children: [
                            Expanded(
                              child: _settingsButton(
                                isArabic: isArabic,
                                label: isArabic ? 'الصوت' : 'Audio',
                                sublabel: isArabic ? 'الصوت' : 'Audio',
                                icon: Icons.volume_up_rounded,
                                onTap: () {
                                  // LOGIC_PLUG_IN: Toggle audio
                                  debugPrint('[Settings] Audio tapped');
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _settingsButton(
                                isArabic: isArabic,
                                label: isArabic ? 'اللغة' : 'Language',
                                sublabel: isArabic ? 'عربي' : 'English',
                                icon: Icons.language_rounded,
                                onTap: locale.toggleLocale,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // ── Change Name (full width) ──
                        _settingsButton(
                          isArabic: isArabic,
                          label: isArabic ? 'تغيير الاسم' : 'Change Name',
                          icon: Icons.edit_rounded,
                          onTap: () {
                            // LOGIC_PLUG_IN: Open name change dialog
                            debugPrint('[Settings] Change Name tapped');
                          },
                        ),

                        const SizedBox(height: 10),

                        // ── Notifications ──
                        _settingsButton(
                          isArabic: isArabic,
                          label: isArabic ? 'الإشعارات' : 'Notifications',
                          icon: Icons.notifications_none_rounded,
                          onTap: () {
                            debugPrint('[Settings] Notifications tapped');
                          },
                        ),

                        const SizedBox(height: 18),

                        // ── Divider ──
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.royalGold.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── Bottom Links Grid ──
                        Row(
                          children: [
                            Expanded(
                              child: _linkButton(
                                isArabic,
                                isArabic ? 'المساعدة' : 'Help & Support',
                                () => debugPrint('[Settings] Help'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _linkButton(
                                isArabic,
                                isArabic ? 'الخصوصية' : 'Privacy',
                                () => debugPrint('[Settings] Privacy'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _linkButton(
                                isArabic,
                                isArabic ? 'شروط الخدمة' : 'Terms of Service',
                                () => debugPrint('[Settings] Terms'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _linkButton(
                                isArabic,
                                isArabic ? 'حول' : 'Credits',
                                () => debugPrint('[Settings] Credits'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ── Player ID ──
                        Center(
                          child: Text(
                            'Player ID: #MOCK001',
                            style: GoogleFonts.readexPro(
                              color: AppColors.royalGold.withValues(alpha: 0.3),
                              fontSize: 9,
                              letterSpacing: isArabic ? 0 : 0.5,
                            ),
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

  // ── Header ──
  Widget _header(BuildContext context, bool isArabic) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.royalGold.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          Text(
            isArabic ? 'الإعدادات' : 'Settings',
            style: GoogleFonts.readexPro(
              color: const Color(0xFFF4E4B7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: isArabic ? 0 : 1,
            ),
          ),
          const Spacer(),
          // ── Back chevron (no box) ──
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

  // ── Account Section Card ──
  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.royalGold.withValues(alpha: 0.1),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _accountRow(bool isArabic) {
    return Row(
      children: [
        // ── Avatar ──
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.royalGold, width: 1.5),
            color: const Color(0xFF2B3140),
          ),
          child: const Icon(Icons.person, size: 20, color: Color(0xFFD6B146)),
        ),
        const SizedBox(width: 12),
        // ── App Identity ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Royal Baloot',
                style: GoogleFonts.readexPro(
                  color: const Color(0xFFF4E4B7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: isArabic ? 0 : 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isArabic
                    ? 'اربط حسابك للعب على أجهزة متعددة'
                    : 'Connect to play on multiple devices',
                style: GoogleFonts.readexPro(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 9,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _connectedBadge(bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D3326).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF4ADE80)),
          const SizedBox(width: 6),
          Text(
            isArabic ? 'متصل' : 'CONNECTED',
            style: GoogleFonts.readexPro(
              color: const Color(0xFF4ADE80),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: isArabic ? 0 : 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Gold Settings Button ──
  Widget _settingsButton({
    required bool isArabic,
    required String label,
    String? sublabel,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A2415), Color(0xFF1E1A10)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.royalGold.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.royalGold),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (sublabel != null)
                  Text(
                    sublabel,
                    style: GoogleFonts.readexPro(
                      color: AppColors.royalGold.withValues(alpha: 0.5),
                      fontSize: 7,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  label,
                  style: GoogleFonts.readexPro(
                    color: const Color(0xFFF4E4B7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: isArabic ? 0 : 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Link Button ──
  Widget _linkButton(bool isArabic, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.royalGold.withValues(alpha: 0.12),
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.readexPro(
              color: const Color(0xFFF4E4B7).withValues(alpha: 0.6),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              letterSpacing: isArabic ? 0 : 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
