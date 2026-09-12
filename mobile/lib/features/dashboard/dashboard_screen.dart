import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';
import '../members/members_screen.dart';
import '../notifications/notifications_screen.dart';

final dashboardProvider = FutureProvider((ref) {
  return ref.watch(repositoryProvider).getDashboard();
});

final activeEventsProvider = FutureProvider((ref) {
  return ref.watch(repositoryProvider).getEvents(activeOnly: true);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _openMembers(
    WidgetRef ref,
    BuildContext context,
    MemberPaymentStatus? filter,
  ) {
    ref.read(membersFilterProvider.notifier).state = filter;
    context.go('/members');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final statsAsync = ref.watch(dashboardProvider);
    final eventsAsync = ref.watch(activeEventsProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(
        title: l10n.dashboard,
        automaticallyImplyLeading: false,
        actions: const [
          NotificationBell(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          ref.invalidate(activeEventsProvider);
        },
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Text(
                '${l10n.assalamuAlaikum}, ${user?.name ?? l10n.user}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
              ),
              const SizedBox(height: 18),
              statsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e'),
                data: (stats) => Column(
                  children: [
                    _CollectionHeroCard(stats: stats),
                    const SizedBox(height: 12),
                    _FundsAvailableCard(
                      stats: stats,
                      onTap: () => context.push('/expenses'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
                data: (stats) => Row(
                  children: [
                    Expanded(
                      child: _StatMini(
                        label: l10n.members,
                        value: '${stats.totalMembers}',
                        icon: Icons.groups_rounded,
                        onTap: () => _openMembers(ref, context, null),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatMini(
                        label: l10n.paid,
                        value: '${stats.paid}',
                        color: AppColors.paid,
                        icon: Icons.check_circle_outline,
                        onTap: () =>
                            _openMembers(ref, context, MemberPaymentStatus.paid),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatMini(
                        label: l10n.partial,
                        value: '${stats.partial}',
                        color: AppColors.partial,
                        icon: Icons.timelapse_rounded,
                        onTap: () => _openMembers(
                          ref,
                          context,
                          MemberPaymentStatus.partial,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatMini(
                        label: l10n.unpaid,
                        value: '${stats.unpaid}',
                        color: AppColors.unpaid,
                        icon: Icons.error_outline_rounded,
                        onTap: () => _openMembers(
                          ref,
                          context,
                          MemberPaymentStatus.unpaid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                l10n.quickActions,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.person_add_alt_1_rounded,
                      label: l10n.addMember,
                      onTap: () => context.push('/add-member'),
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.payments_rounded,
                      label: l10n.collectPayment,
                      onTap: () => context.go('/collection'),
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.account_balance_wallet_outlined,
                      label: l10n.addExpense,
                      onTap: () => context.push('/add-expense'),
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.warning_amber_rounded,
                      label: l10n.viewUnpaid,
                      onTap: () => _openMembers(
                        ref,
                        context,
                        MemberPaymentStatus.unpaid,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Text(
                    l10n.activeCampaigns,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/events'),
                    child: Text(l10n.seeAll),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              eventsAsync.when(
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('$e'),
                data: (events) => Column(
                  children: events
                      .take(2)
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _EventMiniCard(event: e),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _CollectionHeroCard extends StatelessWidget {
  const _CollectionHeroCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.thisMonthCollection,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            '৳ ${_fmt(stats.collected)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.ofExpected(_fmt(stats.expected), (stats.rate * 100).round()),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          ProgressBar(
            value: stats.rate,
            height: 11,
            backgroundColor: Colors.white24,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  String _fmt(num n) => n.round().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

class _FundsAvailableCard extends StatelessWidget {
  const _FundsAvailableCard({required this.stats, required this.onTap});
  final DashboardStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SectionCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.totalFundsAvailable,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '৳ ${_fmt(stats.fundsAvailable)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.spentOf(_fmt(stats.totalExpenses), _fmt(stats.totalInflow)),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  String _fmt(num n) => n.round().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.label,
    required this.value,
    this.color,
    this.icon,
    this.onTap,
  });
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SectionCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            if (icon != null)
              Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: color ?? AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventMiniCard extends StatelessWidget {
  const _EventMiniCard({required this.event});
  final FundraisingEvent event;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${(event.progress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(value: event.progress),
          const SizedBox(height: 8),
          Text(
            '৳ ${_fmt(event.raisedAmount)} / ৳ ${_fmt(event.goalAmount)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _fmt(num n) => n.round().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}
