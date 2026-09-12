import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../dashboard/dashboard_screen.dart';
import '../members/members_screen.dart';
import '../more/join_requests_screen.dart';

enum NotificationKind { paymentApproval, joinRequest, unpaidMembers }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.at,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime? at;
}

final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final stats = await ref.watch(dashboardProvider.future);
  final payments = await repo.getPayments(status: PaymentStatus.pending);
  final joins = await repo.getJoinRequests(status: JoinRequestStatus.submitted);

  final items = <AppNotification>[
    ...payments.map(
      (p) => AppNotification(
        id: 'pay-${p.id}',
        kind: NotificationKind.paymentApproval,
        title: 'Payment pending approval',
        subtitle: '${p.memberName} · ৳ ${_formatAmount(p.amount)}',
        icon: Icons.fact_check_outlined,
        color: AppColors.partial,
        at: p.date,
      ),
    ),
    ...joins.map(
      (j) => AppNotification(
        id: 'join-${j.id}',
        kind: NotificationKind.joinRequest,
        title: 'New join request',
        subtitle: '${j.fullName} · ${j.phone}',
        icon: Icons.how_to_reg_outlined,
        color: AppColors.primary,
        at: j.submittedAt,
      ),
    ),
  ];

  items.sort((a, b) {
    final aTime = a.at ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.at ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });

  if (stats.unpaid > 0) {
    final month = DateFormat('MMMM yyyy').format(DateTime.now());
    items.add(
      AppNotification(
        id: 'unpaid-$month',
        kind: NotificationKind.unpaidMembers,
        title: '${stats.unpaid} members unpaid',
        subtitle: '$month dues are still outstanding.',
        icon: Icons.error_outline_rounded,
        color: AppColors.unpaid,
      ),
    );
  }

  return items;
});

String _formatAmount(int amount) {
  return amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final count = async.valueOrNull?.length ?? 0;

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: AppColors.danger,
        label: Text(count > 99 ? '99+' : '$count'),
        child: Icon(
          count > 0
              ? Icons.notifications_rounded
              : Icons.notifications_none_rounded,
        ),
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _open(BuildContext context, WidgetRef ref, AppNotification item) {
    switch (item.kind) {
      case NotificationKind.paymentApproval:
        context.push('/payment-approvals');
      case NotificationKind.joinRequest:
        ref.read(joinFilterProvider.notifier).state = JoinRequestStatus.submitted;
        context.push('/join-requests');
      case NotificationKind.unpaidMembers:
        ref.read(membersFilterProvider.notifier).state =
            MemberPaymentStatus.unpaid;
        context.go('/members');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final timeFmt = DateFormat('dd MMM · hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const IiasAppBar(title: 'Notifications'),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: 'Unable to load notifications.\n$e'),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(message: 'No notifications right now');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return SectionCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: CircleAvatar(
                      backgroundColor: item.color.withValues(alpha: 0.12),
                      child: Icon(item.icon, color: item.color),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(item.subtitle),
                        if (item.at != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            timeFmt.format(item.at!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, ref, item),
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
