class AppConstants {
  static const appName = 'Ummah Connect';
  static const tagline = 'Together for a Better Tomorrow';
  static const quote =
      '"The best of people are those who are most beneficial to others."';
  static const quoteAuthor = '— Prophet Muhammad ﷺ';
  static const currency = '৳';

  /// Set `false` to use Laravel API (`apiBaseUrl`).
  static const useMockData = true;

  /// iOS simulator / desktop: 127.0.0.1
  /// Android emulator: 10.0.2.2
  /// Herd site (if linked): http://api.test/api/v1
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );
}
