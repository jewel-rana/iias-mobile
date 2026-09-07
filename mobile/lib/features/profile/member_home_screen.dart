import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';

class MemberHomeScreen extends ConsumerWidget {
  const MemberHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final memberId = user?.memberId;

    if (memberId == null) {
      return const Scaffold(body: EmptyState(message: 'Member profile not found'));
    }

    return FutureBuilder(
      future: Future.wait([
        ref.read(repositoryProvider).getMember(memberId),
        ref.read(repositoryProvider).getRecentPayments(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final member = snapshot.data![0] as Member?;
        final allPayments = snapshot.data![1] as List<PaymentRecord>;
        if (member == null) {
          return const Scaffold(body: EmptyState(message: 'Member profile not found'));
        }
        final payments = allPayments.where((p) => p.memberId == member.id).toList();

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Assalamu Alaikum',
                              style: TextStyle(color: AppColors.textSecondary)),
                          Text(
                            member.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Contribution',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Paid', style: TextStyle(fontSize: 12)),
                                MoneyText(member.totalPaid),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Outstanding', style: TextStyle(fontSize: 12)),
                                MoneyText(member.outstanding, color: AppColors.unpaid),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _mini('Paid', '${member.paidMonths}', AppColors.paid)),
                    const SizedBox(width: 8),
                    Expanded(child: _mini('Due', '${member.dueMonths}', AppColors.unpaid)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _mini('Advance', '${member.advanceMonths}', AppColors.advance),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Submit Payment',
                  onPressed: () => context.push('/collect/${member.id}'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Recent Payments',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (payments.isEmpty)
                  const EmptyState(message: 'No payments yet')
                else
                  ...payments.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SectionCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.receiptNumber,
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(p.date),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (p.rejectionReason != null)
                                    Text(
                                      p.rejectionReason!,
                                      style: const TextStyle(
                                        color: AppColors.unpaid,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            MoneyText(p.amount),
                            const SizedBox(width: 8),
                            switch (p.status) {
                              PaymentStatus.pending => const StatusBadge.pending(),
                              PaymentStatus.rejected => const StatusBadge.rejected(),
                              PaymentStatus.confirmed => const StatusBadge.confirmed(),
                            },
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'View Fundraising Events',
                  outlined: true,
                  onPressed: () => context.push('/events'),
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 0,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Payments'),
              NavigationDestination(
                icon: Icon(Icons.volunteer_activism_outlined),
                label: 'Donations',
              ),
              NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
            onDestinationSelected: (index) {
              if (index == 1) {
                context.push('/collect/$memberId');
              } else if (index == 2) {
                context.push('/events');
              }
            },
          ),
        );
      },
    );
  }

  Widget _mini(String label, String value, Color color) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 18),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
