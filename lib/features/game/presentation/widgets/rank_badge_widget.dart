import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../data/models/rank_tier.dart';
import '../../../../core/constants/app_colors.dart';

class RankBadgeWidget extends StatelessWidget {
  final RankTier rank;
  final bool compact;

  const RankBadgeWidget({
    super.key,
    required this.rank,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final name = isArabic ? rank.arabicName : rank.englishName;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 16,
        vertical: compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: rank.badgeColor.withValues(alpha: 0.15),
        border: Border.all(color: rank.badgeColor.withValues(alpha: 0.5), width: 1.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: rank.badgeColor.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield, // We can use custom SVGs later, standard icon for now
            color: rank.badgeColor,
            size: compact ? 16 : 24,
          ),
          SizedBox(width: compact ? 6 : 10),
          Text(
            name,
            style: TextStyle(
              color: rank.badgeColor,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12 : 16,
            ),
          ),
          SizedBox(width: compact ? 4 : 8),
          _buildSuitIcons(),
        ],
      ),
    );
  }

  Widget _buildSuitIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rank.suitIconCount, (index) {
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Icon(
            Icons.diamond, // Generic indicator
            color: rank.badgeColor,
            size: compact ? 10 : 14,
          ),
        );
      }),
    );
  }
}
