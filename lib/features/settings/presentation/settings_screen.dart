import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/locale_provider.dart';

/// Settings Screen — Language control + future settings
/// LOGIC_PLUG_IN: Add account, notifications, sound, etc.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final isArabic = localeProvider.isArabic;

    return Scaffold(
      backgroundColor: AppColors.antigravityBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0F14),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.royalGold.withValues(alpha: 0.7),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isArabic ? 'الإعدادات' : 'Settings',
          style: GoogleFonts.montserrat(
            color: const Color(0xFFF4E4B7),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.royalGold.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // ── Language ──
            _SettingsTile(
              icon: Icons.language,
              title: isArabic ? 'اللغة' : 'Language',
              trailing: _LanguageToggle(
                isArabic: isArabic,
                onToggle: localeProvider.toggleLocale,
              ),
            ),

            const SizedBox(height: 12),

            // ── Placeholder sections ──
            _SettingsTile(
              icon: Icons.person_outline,
              title: isArabic ? 'الحساب' : 'Account',
              trailing: _comingSoonLabel(),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.notifications_none,
              title: isArabic ? 'الإشعارات' : 'Notifications',
              trailing: _comingSoonLabel(),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.volume_up_outlined,
              title: isArabic ? 'الصوت' : 'Sound',
              trailing: _comingSoonLabel(),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.info_outline,
              title: isArabic ? 'حول التطبيق' : 'About',
              trailing: _comingSoonLabel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comingSoonLabel() {
    return Text(
      'Soon',
      style: GoogleFonts.montserrat(
        color: AppColors.royalGold.withValues(alpha: 0.3),
        fontSize: 11,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Settings Tile ──
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x991C1F26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.royalGold.withValues(alpha: 0.6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.montserrat(
                color: const Color(0xFFF4E4B7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// ── Language Toggle Switch ──
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.isArabic,
    required this.onToggle,
  });

  final bool isArabic;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langPill('EN', !isArabic),
            _langPill('عربي', isArabic),
          ],
        ),
      ),
    );
  }

  Widget _langPill(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.royalGold.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: active
            ? Border.all(color: AppColors.royalGold.withValues(alpha: 0.5))
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          color: active ? const Color(0xFFF4E4B7) : AppColors.royalGold.withValues(alpha: 0.4),
          fontSize: 11,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
