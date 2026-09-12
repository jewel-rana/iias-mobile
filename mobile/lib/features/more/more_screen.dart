import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/app_repository.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    return Scaffold(
      appBar: const IiasAppBar(title: 'More', automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
              title: Text(
                user?.name ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${user?.role.name.toUpperCase()} · ${user?.phone ?? ''}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bar_chart_rounded),
                  title: const Text('Reports'),
                  subtitle: const Text('Monthly collection summary'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/reports'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Expenses'),
                  subtitle: const Text('Salary, festival bonus & spending'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/expenses'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Expense Heads'),
                  subtitle: const Text('Manage salary, bonus & other types'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/expense-heads'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.groups_2_outlined),
                  title: const Text('Organizing Committee'),
                  subtitle: const Text('Chairman, Secretary & other roles'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/committee'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.how_to_reg),
                  title: const Text('Join Requests'),
                  subtitle: const Text('Approve or reject applicants'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/join-requests'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fact_check_outlined),
                  title: const Text('Payment Approvals'),
                  subtitle: const Text('Accept member-submitted payments'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/payment-approvals'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Organization Settings'),
                  subtitle: const Text('Name, dues default & referrals'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/organization-settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Logout',
            outlined: true,
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
