import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/language_toggle.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    final l10n = context.l10n;

    return Scaffold(
      appBar: IiasAppBar(title: l10n.more, automaticallyImplyLeading: false),
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
                user?.name ?? l10n.user,
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
                  title: Text(l10n.reports),
                  subtitle: Text(l10n.reportsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/reports'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(l10n.expenses),
                  subtitle: Text(l10n.expensesSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/expenses'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.category_outlined),
                  title: Text(l10n.expenseHeads),
                  subtitle: Text(l10n.expenseHeadsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/expense-heads'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.groups_2_outlined),
                  title: Text(l10n.committee),
                  subtitle: Text(l10n.committeeSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/committee'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.campaign_outlined),
                  title: Text(l10n.meetings),
                  subtitle: Text(l10n.meetingsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/meetings'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.how_to_reg),
                  title: Text(l10n.joinRequests),
                  subtitle: Text(l10n.joinRequestsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/join-requests'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fact_check_outlined),
                  title: Text(l10n.paymentApprovals),
                  subtitle: Text(l10n.paymentApprovalsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/payment-approvals'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(l10n.organizationSettings),
                  subtitle: Text(l10n.organizationSettingsSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/organization-settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: const LanguageToggle(),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: l10n.logout,
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
