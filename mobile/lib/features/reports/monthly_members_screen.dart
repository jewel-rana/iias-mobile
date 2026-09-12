import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';

class MonthlyMembersScreen extends ConsumerWidget {
  const MonthlyMembersScreen({super.key, required this.filter, this.month});

  final String filter;
  final String? month;

  MemberPaymentStatus? get _status {
    switch (filter) {
      case 'paid':
        return MemberPaymentStatus.paid;
      case 'partial':
        return MemberPaymentStatus.partial;
      case 'unpaid':
        return MemberPaymentStatus.unpaid;
      default:
        return null;
    }
  }

  DateTime? get _billingMonth {
    final value = month;
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse('$value-01');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingMonth = _billingMonth;
    return FutureBuilder(
      future: Future.wait<Object?>([
        ref.read(repositoryProvider).getMembers(
              status: _status,
              billingMonth: billingMonth,
            ),
        if (filter != 'unpaid')
          ref.read(repositoryProvider).getPayments(
                billingMonth: billingMonth,
              )
        else
          Future<List<PaymentRecord>>.value(const []),
      ]),
      builder: (context, snapshot) {
        final l10n = context.l10n;
        final locale = Localizations.localeOf(context).toString();
        final monthFmt = DateFormat('MMM yyyy', locale);
        final title = switch (filter) {
          'paid' => l10n.paidMembers,
          'partial' => l10n.partialMembers,
          'unpaid' => l10n.unpaidMembers,
          _ => l10n.members,
        };
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: IiasAppBar(title: title),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : _body(
                  context,
                  l10n,
                  monthFmt,
                  (snapshot.data![0] as List<Member>),
                  (snapshot.data![1] as List<PaymentRecord>),
                ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    DateFormat monthFmt,
    List<Member> members,
    List<PaymentRecord> payments,
  ) {
    if (members.isEmpty) {
      return EmptyState(message: l10n.noMembersThisFilter);
    }
    final byMember = <String, List<PaymentRecord>>{};
    for (final payment in payments.where((p) => p.status != PaymentStatus.rejected)) {
      byMember.putIfAbsent(payment.memberId, () => []).add(payment);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final member = members[i];
        final memberPayments = byMember[member.id] ?? const <PaymentRecord>[];
        return SectionCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          member.memberCode,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (filter == 'paid' || member.status == MemberPaymentStatus.paid)
                    const StatusBadge.paid()
                  else if (filter == 'partial' || member.status == MemberPaymentStatus.partial)
                    const StatusBadge.partial()
                  else
                    const StatusBadge.unpaid(),
                ],
              ),
              if (memberPayments.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '৳ ${member.monthlyAmount}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ] else
                ...memberPayments.map((payment) {
                  final months = payment.allocations
                      .map((a) => monthFmt.format(a.billingMonth))
                      .join(', ');
                  return InkWell(
                    onTap: () => context.push(
                      '/payment-details/${payment.id}',
                      extra: payment,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  months.isEmpty ? DateFormat('MMM yyyy').format(payment.date) : months,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  [
                                    l10n.paymentMethodName(payment.method),
                                    payment.receiptNumber,
                                  ].join(' · '),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          MoneyText(payment.amount),
                          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
