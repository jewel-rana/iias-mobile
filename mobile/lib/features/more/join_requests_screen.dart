import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_screen.dart';
import '../members/members_screen.dart';

final joinFilterProvider = StateProvider<JoinRequestStatus?>((ref) => null);

final joinRequestsProvider = FutureProvider((ref) {
  final status = ref.watch(joinFilterProvider);
  return ref.watch(repositoryProvider).getJoinRequests(status: status);
});

class JoinRequestsScreen extends ConsumerWidget {
  const JoinRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(joinFilterProvider);
    final async = ref.watch(joinRequestsProvider);
    final dateFmt = DateFormat('dd MMM yyyy · hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(title: context.l10n.joinRequests),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _Pill(
                  label: 'All',
                  selected: filter == null,
                  onTap: () => ref.read(joinFilterProvider.notifier).state = null,
                ),
                _Pill(
                  label: 'Pending',
                  selected: filter == JoinRequestStatus.submitted,
                  onTap: () => ref.read(joinFilterProvider.notifier).state =
                      JoinRequestStatus.submitted,
                ),
                _Pill(
                  label: 'Approved',
                  selected: filter == JoinRequestStatus.approved,
                  onTap: () => ref.read(joinFilterProvider.notifier).state =
                      JoinRequestStatus.approved,
                ),
                _Pill(
                  label: 'Rejected',
                  selected: filter == JoinRequestStatus.rejected,
                  onTap: () => ref.read(joinFilterProvider.notifier).state =
                      JoinRequestStatus.rejected,
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (requests) {
                if (requests.isEmpty) {
                  return const EmptyState(message: 'No join requests');
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(joinRequestsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return SectionCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    req.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                _StatusChip(status: req.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              req.phone,
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            if (req.email != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                req.email!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              dateFmt.format(req.submittedAt),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            if (req.referralCode != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Referral: ${req.referralCode}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                            if (req.preferredMonthlyAmount != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Preferred monthly: ৳ ${req.preferredMonthlyAmount}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                            if (req.rejectionReason != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Reason: ${req.rejectionReason}',
                                style: const TextStyle(
                                  color: AppColors.unpaid,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            if (req.status == JoinRequestStatus.submitted) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _reject(context, ref, req),
                                      child: const Text('Reject'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _approve(context, ref, req),
                                      child: const Text('Approve'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    JoinRequest req,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve member?'),
        content: Text(
          'Create a member account for ${req.fullName} (${req.phone})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(repositoryProvider).approveJoinRequest(req.id);
      ref.invalidate(joinRequestsProvider);
      ref.invalidate(membersProvider);
      ref.invalidate(dashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${req.fullName} approved')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approve failed: $e')),
        );
      }
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    JoinRequest req,
  ) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject request'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(repositoryProvider).rejectJoinRequest(
            req.id,
            reason: reasonCtrl.text.trim(),
          );
      ref.invalidate(joinRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request rejected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reject failed: $e')),
        );
      }
    } finally {
      reasonCtrl.dispose();
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final JoinRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      JoinRequestStatus.submitted => ('Pending', AppColors.partial),
      JoinRequestStatus.approved => ('Approved', AppColors.paid),
      JoinRequestStatus.rejected => ('Rejected', AppColors.unpaid),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
