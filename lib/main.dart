import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/locale_provider.dart';
import 'core/l10n/app_localizations.dart';
import 'core/providers/user_provider.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-cache fonts to avoid download delay on splash screen
  GoogleFonts.config.allowRuntimeFetching = true;
  await Future.wait([
    GoogleFonts.pendingFonts([
      GoogleFonts.cairo(),
      GoogleFonts.montserrat(),
      GoogleFonts.tajawal(),
    ]),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const AntigravittyBalootApp(),
    ),
  );
}

class AntigravittyBalootApp extends StatelessWidget {
  const AntigravittyBalootApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Royal Baloot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(
        textTheme: AppTheme.localizedTextTheme(localeProvider.locale),
      ),
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}

