import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/l10n/locale_controller.dart';
import 'core/push/push_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/app_repository.dart';
import 'features/shell/app_router.dart';
import 'l10n/app_localizations.dart';

bool _backgroundServicesStarted = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnv();
  final localeChoice = await loadLocaleChoice();
  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(
          (ref) => LocaleController(initial: localeChoice.locale),
        ),
        localeChosenProvider.overrideWith((ref) => localeChoice.chosen),
      ],
      child: const UmmahConnectApp(),
    ),
  );
}

Future<void> _loadEnv() async {
  await dotenv.load(
    fileName: '.env.example',
    overrideWithFiles: const ['.env'],
    isOptional: true,
  );
}

Future<void> _startBackgroundServices() async {
  await Future.wait([
    initializeDateFormatting('bn'),
    initializeDateFormatting('en'),
    PushService.instance.initialize(),
  ]);
  PushService.instance.flushPending();
}

class UmmahConnectApp extends ConsumerWidget {
  const UmmahConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_backgroundServicesStarted) {
      _backgroundServicesStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_startBackgroundServices());
      });
    }

    final locale = ref.watch(localeProvider);
    final authReady = ref.watch(authReadyProvider);
    final theme = AppTheme.light(locale);
    const List<LocalizationsDelegate<dynamic>> delegates = [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

    return authReady.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localeResolutionCallback: (device, supported) => locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: delegates,
        theme: theme,
        home: const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localeResolutionCallback: (device, supported) => locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: delegates,
        theme: theme,
        home: Scaffold(
          body: Center(child: Text('Startup error: $e')),
        ),
      ),
      data: (_) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          title: 'IIAS',
          debugShowCheckedModeBanner: false,
          locale: locale,
          localeResolutionCallback: (device, supported) => locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: delegates,
          theme: theme,
          routerConfig: router,
        );
      },
    );
  }
}
