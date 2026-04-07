import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/locale_provider.dart';
import 'core/l10n/app_localizations.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
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
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.translate('app_name'),
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => localeProvider.toggleLocale(),
              child: Text(
                l10n.translate('switch_language'),
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
