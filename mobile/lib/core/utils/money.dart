import '../constants/app_constants.dart';

String formatTaka(num amount, {bool compact = false}) {
  final value = amount.round();
  final formatted = value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  if (compact) return '${AppConstants.currency}$formatted';
  return '${AppConstants.currency} $formatted';
}
