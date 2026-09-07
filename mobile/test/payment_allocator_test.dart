import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_connect/data/models/models.dart';
import 'package:ummah_connect/data/repositories/payment_allocator.dart';

void main() {
  test('allocates dues first then advance', () {
    final dues = [
      MonthlyDue(
        id: '1',
        memberId: 'm1',
        billingMonth: DateTime(2026, 8, 1),
        amountDue: 500,
        amountPaid: 200,
        status: DueStatus.partial,
      ),
      MonthlyDue(
        id: '2',
        memberId: 'm1',
        billingMonth: DateTime(2026, 9, 1),
        amountDue: 500,
        amountPaid: 0,
        status: DueStatus.unpaid,
      ),
    ];

    final result = suggestAllocations(
      dues: dues,
      paymentAmount: 1300,
      monthlyAmount: 500,
    );

    expect(result.length, 3);
    expect(result[0].amount, 300);
    expect(result[1].amount, 500);
    expect(result[2].amount, 500);
    expect(result.fold<int>(0, (s, a) => s + a.amount), 1300);
  });
}
