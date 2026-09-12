import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';
import '../payments/receipt_screen.dart';

final memberDonationsProvider =
    FutureProvider.autoDispose.family<List<EventDonation>, String>((ref, memberId) {
  return ref.watch(repositoryProvider).getEventDonations(memberId: memberId);
});

class MemberDonationsScreen extends ConsumerWidget {
  const MemberDonationsScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(memberDonationsProvider(memberId));
    final l10n = context.l10n;
    final dateFmt = DateFormat('dd MMM yyyy · hh:mm a', Localizations.localeOf(context).toString());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(title: l10n.donations),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-member-donate',
        onPressed: () => context.push('/new-donation?memberId=$memberId'),
        icon: const Icon(Icons.volunteer_activism),
        label: Text(l10n.donate),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: '$e'),
        data: (donations) {
          if (donations.isEmpty) {
            return EmptyState(message: l10n.noDonationsYet);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(memberDonationsProvider(memberId)),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: donations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final d = donations[index];
                return SectionCard(
                  padding: const EdgeInsets.all(14),
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReceiptScreen.donation(donation: d),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                d.receiptNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const StatusBadge.confirmed(),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          d.eventTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.paymentMethodName(d.method),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFmt.format(d.date),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        MoneyText(d.amount),
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
