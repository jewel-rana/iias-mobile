import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';

final memberDetailProvider =
    FutureProvider.autoDispose.family<({Member? member, List<MonthlyDue> dues}), String>(
  (ref, memberId) async {
    final repo = ref.watch(repositoryProvider);
    final member = await repo.getMember(memberId);
    final dues = await repo.getMemberDues(memberId);
    return (member: member, dues: dues);
  },
);

class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(memberDetailProvider(memberId));
    final l10n = context.l10n;

    return async.when(
      loading: () => Scaffold(
        appBar: IiasAppBar(title: l10n.memberDetails),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: IiasAppBar(title: l10n.memberDetails),
        body: EmptyState(message: l10n.unableToLoadMember(e)),
      ),
      data: (data) {
        final member = data.member;
        final dues = data.dues;
        if (member == null) {
          return Scaffold(
            appBar: IiasAppBar(title: l10n.memberDetails),
            body: EmptyState(message: l10n.memberNotFound),
          );
        }

        final initial = member.name.trim().isEmpty
            ? '?'
            : member.name.trim().characters.first.toUpperCase();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: IiasAppBar(title: l10n.memberDetails),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                label: l10n.collectPayment,
                onPressed: () => context.push('/collect/${member.id}'),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            member.memberCode,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          Text(
                            member.phone,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          if (member.email != null && member.email!.isNotEmpty)
                            Text(
                              member.email!,
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          if (member.joinedAt != null)
                            Text(
                              l10n.joinedOn(DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString()).format(member.joinedAt!)),
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SectionCard(
                      child: Column(
                        children: [
                          Text(
                            l10n.totalPaid,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          MoneyText(member.totalPaid),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SectionCard(
                      child: Column(
                        children: [
                          Text(
                            l10n.outstanding,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          MoneyText(member.outstanding, color: AppColors.unpaid),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SectionCard(
                      child: Column(
                        children: [
                          Text(
                            l10n.advance,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          MoneyText(member.advance, color: AppColors.advance),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.currentDues,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DueStat(
                          label: l10n.paid,
                          value: '${member.paidMonths}',
                          color: AppColors.paid,
                        ),
                        _DueStat(
                          label: l10n.due,
                          value: '${member.dueMonths}',
                          color: AppColors.unpaid,
                        ),
                        _DueStat(
                          label: l10n.advance,
                          value: '${member.advanceMonths}',
                          color: AppColors.advance,
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    ...dues.map((d) {
                      final label = DateFormat('MMM yyyy', Localizations.localeOf(context).toString()).format(d.billingMonth);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(label)),
                            Text('? ${d.amountPaid}/${d.amountDue}'),
                            const SizedBox(width: 8),
                            if (d.status == DueStatus.paid) const StatusBadge.paid(),
                            if (d.status == DueStatus.partial)
                              const StatusBadge.partial(),
                            if (d.status == DueStatus.unpaid)
                              const StatusBadge.unpaid(),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long),
                      title: Text(l10n.paymentHistory),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.volunteer_activism),
                      title: Text(l10n.donations),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.share),
                      title: Text(l10n.referralCodeLabel(member.referralCode)),
                      trailing: const Icon(Icons.copy),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.referralReady(member.referralCode),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

class _DueStat extends StatelessWidget {
  const _DueStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}
