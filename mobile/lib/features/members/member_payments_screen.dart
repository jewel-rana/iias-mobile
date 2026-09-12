import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';

final memberPaymentsProvider =
    FutureProvider.autoDispose.family<List<PaymentRecord>, String>((ref, memberId) {
  return ref.watch(repositoryProvider).getPayments(memberId: memberId);
});

class MemberPaymentsScreen extends ConsumerWidget {
  const MemberPaymentsScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(memberPaymentsProvider(memberId));
    final l10n = context.l10n;
    final dateFmt = DateFormat('dd MMM yyyy · hh:mm a', Localizations.localeOf(context).toString());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(title: l10n.paymentHistory),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: '$e'),
        data: (payments) {
          if (payments.isEmpty) {
            return EmptyState(message: l10n.noPaymentsYet);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(memberPaymentsProvider(memberId)),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: payments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final p = payments[index];
                return SectionCard(
                  padding: const EdgeInsets.all(14),
                  child: InkWell(
                    onTap: () => context.push(
                      '/payment-details/${p.id}',
                      extra: p,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.receiptNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            switch (p.status) {
                              PaymentStatus.pending => const StatusBadge.pending(),
                              PaymentStatus.rejected => const StatusBadge.rejected(),
                              PaymentStatus.confirmed => const StatusBadge.confirmed(),
                            },
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.paymentMethodName(p.method),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFmt.format(p.date),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        MoneyText(p.amount),
                        if (p.allocations.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...p.allocations.map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '${DateFormat('MMM yyyy').format(a.billingMonth)} · ৳ ${a.amount}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
