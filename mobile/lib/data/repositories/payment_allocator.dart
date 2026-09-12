import '../models/models.dart';

/// Suggests month allocations: dues/partial first, then advance months.
List<PaymentAllocation> suggestAllocations({
  required List<MonthlyDue> dues,
  required int paymentAmount,
  required int monthlyAmount,
}) {
  if (paymentAmount <= 0) return [];

  final sorted = [...dues]..sort((a, b) => a.billingMonth.compareTo(b.billingMonth));
  final dueFirst = sorted.where((d) => !d.isFullyPaid).toList();
  final result = <PaymentAllocation>[];
  var remaining = paymentAmount;

  for (final due in dueFirst) {
    if (remaining <= 0) break;
    final take = due.remaining < remaining ? due.remaining : remaining;
    if (take > 0) {
      result.add(PaymentAllocation(billingMonth: due.billingMonth, amount: take));
      remaining -= take;
    }
  }

  if (remaining > 0 && monthlyAmount > 0) {
    final lastMonth = sorted.isNotEmpty ? sorted.last.billingMonth : DateTime.now();
    var cursor = DateTime(lastMonth.year, lastMonth.month + 1, 1);

    while (remaining > 0) {
      final existing = sorted.cast<MonthlyDue?>().firstWhere(
            (d) =>
                d != null &&
                d.billingMonth.year == cursor.year &&
                d.billingMonth.month == cursor.month,
            orElse: () => null,
          );

      if (existing != null && existing.isFullyPaid) {
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
        continue;
      }

      final need = existing?.remaining ?? monthlyAmount;
      final take = need < remaining ? need : remaining;
      result.add(PaymentAllocation(billingMonth: cursor, amount: take));
      remaining -= take;
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
      if (result.length > 48) break;
    }
  }

  return result;
}
