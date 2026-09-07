import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';

class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);

    return FutureBuilder(
      future: Future.wait([
        repo.getMember(memberId),
        repo.getMemberDues(memberId),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final member = (snapshot.data![0] as Member?);
        final dues = snapshot.data![1] as List<MonthlyDue>;
        if (member == null) {
          return const Scaffold(body: EmptyState(message: 'Member not found'));
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Member Details')),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                label: 'Collect Payment',
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
                        member.name.characters.first,
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
                          Text(member.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                          Text(member.memberCode,
                              style: const TextStyle(color: AppColors.textSecondary)),
                          Text(member.phone,
                              style: const TextStyle(color: AppColors.textSecondary)),
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
                          const Text('Total Paid', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                          const Text('Outstanding', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                          const Text('Advance', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                    const Text('Current Dues (2026)', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DueStat(label: 'Paid', value: '${member.paidMonths}', color: AppColors.paid),
                        _DueStat(label: 'Due', value: '${member.dueMonths}', color: AppColors.unpaid),
                        _DueStat(label: 'Advance', value: '${member.advanceMonths}', color: AppColors.advance),
                      ],
                    ),
                    const Divider(height: 28),
                    ...dues.map((d) {
                      final label = DateFormat('MMM yyyy').format(d.billingMonth);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(label)),
                            Text('৳ ${d.amountPaid}/${d.amountDue}'),
                            const SizedBox(width: 8),
                            if (d.status == DueStatus.paid) const StatusBadge.paid(),
                            if (d.status == DueStatus.partial) const StatusBadge.partial(),
                            if (d.status == DueStatus.unpaid) const StatusBadge.unpaid(),
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
                      title: const Text('Payment History'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.volunteer_activism),
                      title: const Text('Donations'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.share),
                      title: Text('Referral: ${member.referralCode}'),
                      trailing: const Icon(Icons.copy),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Referral ${member.referralCode} ready to share')),
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
  const _DueStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}
