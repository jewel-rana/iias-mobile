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
    final l10n = context.l10n;
    final dateFmt = DateFormat('dd MMM yyyy · hh:mm a', Localizations.localeOf(context).toString());

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
                  label: l10n.all,
                  selected: filter == null,
                  onTap: () => ref.read(joinFilterProvider.notifier).state = null,
                ),
                _Pill(
                  label: l10n.pending,
                  selected: filter == JoinRequestStatus.submitted,
                  onTap: () => ref.read(joinFilterProvider.notifier).state =
                      JoinRequestStatus.submitted,
                ),
                _Pill(
                  label: l10n.approved,
                  selected: filter == JoinRequestStatus.approved,
                  onTap: () => ref.read(joinFilterProvider.notifier).state =
                      JoinRequestStatus.approved,
                ),
                _Pill(
                  label: l10n.rejected,
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
                  return EmptyState(message: l10n.noJoinRequests);
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
                                l10n.referralCodeLabel(req.referralCode!),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                            if (req.preferredMonthlyAmount != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                l10n.preferredMonthly('${req.preferredMonthlyAmount}'),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                            if (req.rejectionReason != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                l10n.reasonLabel(req.rejectionReason!),
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
                                      child: Text(l10n.reject),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _approve(context, ref, req),
                                      child: Text(l10n.approve),
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
        title: Text(context.l10n.approveMember),
        content: Text(
          context.l10n.approveMemberHint(req.fullName, req.phone),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.approve),
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
          SnackBar(content: Text(context.l10n.receiptApproved(req.fullName))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.approveFailed(e))),
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
        title: Text(context.l10n.rejectRequestTitle),
        content: TextField(
          controller: reasonCtrl,
          decoration: InputDecoration(
            labelText: context.l10n.reasonOptional,
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.reject),
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
          SnackBar(content: Text(context.l10n.requestRejected)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.rejectFailed(e))),
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
    final l10n = context.l10n;
    final (label, color) = switch (status) {
      JoinRequestStatus.submitted => (l10n.pending, AppColors.partial),
      JoinRequestStatus.approved => (l10n.approved, AppColors.paid),
      JoinRequestStatus.rejected => (l10n.rejected, AppColors.unpaid),
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
