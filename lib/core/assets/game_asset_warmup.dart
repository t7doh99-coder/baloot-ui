import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_assets.dart';

/// Loads card backs, seat avatars, and Majlis SVG maps into caches so the first
/// [GameTableScreen] paint does not block on IO/decode (reduces jank after Play).
Future<void> warmHeavyGameAssets(BuildContext context) async {
  final bundle = DefaultAssetBundle.of(context);
  final pngPaths = <String>[
    AppAssets.cardBackRed,
    AppAssets.cardBackBlue,
    ...AppAssets.playerSeatAvatars,
  ];

  await Future.wait<void>([
    for (final p in pngPaths) precacheImage(AssetImage(p, bundle: bundle), context),
    (const SvgAssetLoader(AppAssets.majlisTableMap)).loadBytes(context),
    (const SvgAssetLoader(AppAssets.majlisTableMap2)).loadBytes(context),
  ]);
}
