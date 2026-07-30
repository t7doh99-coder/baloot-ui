import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_assets.dart';

class CustomPlayerAvatar extends StatelessWidget {
  final int seatIndex;
  final String? customAvatarPath;
  final BoxFit fit;

  const CustomPlayerAvatar({
    Key? key,
    required this.seatIndex,
    this.customAvatarPath,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (seatIndex == 0 && customAvatarPath != null && customAvatarPath!.isNotEmpty) {
      final file = File(customAvatarPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
        );
      }
    }
    
    // Fallback to default asset
    return Image.asset(
      AppAssets.playerAvatarPath(seatIndex),
      fit: fit,
    );
  }
}
