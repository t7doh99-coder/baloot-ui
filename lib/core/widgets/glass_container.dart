import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// A reusable glassmorphism container with blur + gold border
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool showGoldBorder;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius = AppSizes.radiusMd,
    this.showGoldBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: showGoldBorder
                  ? AppColors.royalGold.withOpacity(0.5)
                  : AppColors.silverLining.withOpacity(0.1),
              width: showGoldBorder ? 1.5 : 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
