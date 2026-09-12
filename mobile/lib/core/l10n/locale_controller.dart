import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../l10n/app_localizations.dart';

const _localeStorageKey = 'app_locale';

class LocaleChoice {
  const LocaleChoice({required this.locale, required this.chosen});

  final Locale locale;
  final bool chosen;
}

final localeProvider = StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController();
});

final localeChosenProvider = StateProvider<bool>((ref) => false);

class LocaleController extends StateNotifier<Locale> {
  LocaleController({
    FlutterSecureStorage? storage,
    Locale initial = AppLocalizations.defaultLocale,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        super(initial);

  final FlutterSecureStorage _storage;

  void preview(Locale locale) {
    state = locale;
  }

  Future<void> restore() async {
    final choice = await loadLocaleChoice();
    state = choice.locale;
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _storage.write(key: _localeStorageKey, value: locale.languageCode);
  }
}

Future<LocaleChoice> loadLocaleChoice() async {
  const storage = FlutterSecureStorage();
  final code = await storage.read(key: _localeStorageKey);
  if (code == 'bn') {
    return const LocaleChoice(locale: Locale('bn'), chosen: true);
  }
  if (code == 'en') {
    return const LocaleChoice(locale: Locale('en'), chosen: true);
  }
  return const LocaleChoice(
    locale: AppLocalizations.defaultLocale,
    chosen: false,
  );
}

Future<Locale> loadSavedLocale() async {
  return (await loadLocaleChoice()).locale;
}
