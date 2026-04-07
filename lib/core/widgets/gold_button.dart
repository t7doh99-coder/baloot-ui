import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Premium gold gradient button with shimmer hover effect
class GoldButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isOutlined;
  final double? width;

  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.width,
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOutlined) {
      return SizedBox(
        width: widget.width,
        child: OutlinedButton(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.royalGold, width: 1.5),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
          ),
          child: _buildContent(AppColors.royalGold),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return SizedBox(
          width: widget.width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color(0xFFB8860B),
                  Color(0xFFD4AF37),
                  Color(0xFFFFE066),
                  Color(0xFFD4AF37),
                  Color(0xFFB8860B),
                ],
                stops: [
                  0.0,
                  _shimmerController.value * 0.5,
                  _shimmerController.value,
                  _shimmerController.value * 0.5 + 0.5,
                  1.0,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.royalGold.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: MaterialButton(
              onPressed: widget.onPressed,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: _buildContent(AppColors.antigravityBlack),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(Color color) {
    final style = GoogleFonts.montserrat(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 0.5,
    );

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: color, size: AppSizes.iconMd),
          const SizedBox(width: AppSizes.sm),
          Text(widget.label, style: style),
        ],
      );
    }
    return Text(widget.label, style: style);
  }
}
