import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const appName = 'IIAS';
  static const tagline = 'Isapura Islamic United Organization';
  static const quote =
      '"The best of people are those who are most beneficial to others."';
  static const quoteAuthor = '— Prophet Muhammad ﷺ';
  static const currency = '৳';

  static const _defaultApiBaseUrl = 'http://127.0.0.1:8000/api/v1';

  /// Laravel API base (`/api/v1`).
  ///
  /// Reads `API_BASE_URL` from `.env`. Optional compile-time override:
  /// `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1`
  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;

    if (dotenv.isInitialized) {
      final fromEnv = dotenv.env['API_BASE_URL']?.trim();
      if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    }

    return _defaultApiBaseUrl;
  }
}
