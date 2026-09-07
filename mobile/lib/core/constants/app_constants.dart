class AppConstants {
  static const appName = 'IIAS';
  static const tagline = 'Isapura Islamic United Organization';
  static const quote =
      '"The best of people are those who are most beneficial to others."';
  static const quoteAuthor = '— Prophet Muhammad ﷺ';
  static const currency = '৳';

  /// Laravel API base (`/api/v1`).
  ///
  /// Override at build/run time:
  /// `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1`
  ///
  /// Defaults to this Mac's LAN IP so a physical Android device can reach
  /// `php artisan serve --host=0.0.0.0`.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.60.197:8000/api/v1',
  );
}
