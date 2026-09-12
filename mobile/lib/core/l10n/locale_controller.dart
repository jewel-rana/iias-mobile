import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../l10n/app_localizations.dart';

const _localeStorageKey = 'app_locale';

final localeProvider = StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController();
});

class LocaleController extends StateNotifier<Locale> {
  LocaleController({
    FlutterSecureStorage? storage,
    Locale initial = AppLocalizations.defaultLocale,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        super(initial);

  final FlutterSecureStorage _storage;

  Future<void> restore() async {
    final code = await _storage.read(key: _localeStorageKey);
    if (code == 'bn') {
      state = const Locale('bn');
    } else {
      state = AppLocalizations.defaultLocale;
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _storage.write(key: _localeStorageKey, value: locale.languageCode);
  }
}

Future<Locale> loadSavedLocale() async {
  const storage = FlutterSecureStorage();
  final code = await storage.read(key: _localeStorageKey);
  return code == 'bn' ? const Locale('bn') : AppLocalizations.defaultLocale;
}
