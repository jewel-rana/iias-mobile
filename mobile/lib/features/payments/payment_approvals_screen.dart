import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_screen.dart';

final paymentApprovalFilterProvider =
    StateProvider<PaymentStatus?>((ref) => PaymentStatus.pending);

final paymentApprovalsProvider = FutureProvider((ref) {
  final status = ref.watch(paymentApprovalFilterProvider);
  return ref.watch(repositoryProvider).getPayments(status: status);
});

class PaymentApprovalsScreen extends ConsumerWidget {
  const PaymentApprovalsScreen({super.key});

  String _methodLabel(PaymentMethod m, AppLocalizations l10n) =>
      l10n.paymentMethodName(m);

  Widget _badge(PaymentStatus status) => switch (status) {
        PaymentStatus.pending => const StatusBadge.pending(),
        PaymentStatus.confirmed => const StatusBadge.confirmed(),
        PaymentStatus.rejected => const StatusBadge.rejected(),
      };

  Future<void> _approve(WidgetRef ref, BuildContext context, PaymentRecord p) async {
    try {
      await ref.read(repositoryProvider).approvePayment(p.id);
      ref.invalidate(paymentApprovalsProvider);
      ref.invalidate(dashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.receiptApproved(p.receiptNumber))),
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

  Future<void> _reject(WidgetRef ref, BuildContext context, PaymentRecord p) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.rejectPayment),
        content: TextField(
          controller: reasonCtrl,
          decoration: InputDecoration(
            labelText: context.l10n.reasonOptional,
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.reject),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(repositoryProvider).rejectPayment(
            p.id,
            reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
          );
      ref.invalidate(paymentApprovalsProvider);
      ref.invalidate(dashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.receiptRejected(p.receiptNumber))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.rejectFailed(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(paymentApprovalFilterProvider);
    final async = ref.watch(paymentApprovalsProvider);
    final l10n = context.l10n;
    final dateFmt = DateFormat('dd MMM yyyy · hh:mm a', Localizations.localeOf(context).toString());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(title: context.l10n.paymentApprovals),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _Pill(
                  label: l10n.pending,
                  selected: filter == PaymentStatus.pending,
                  onTap: () => ref.read(paymentApprovalFilterProvider.notifier).state =
                      PaymentStatus.pending,
                ),
                _Pill(
                  label: l10n.confirmed,
                  selected: filter == PaymentStatus.confirmed,
                  onTap: () => ref.read(paymentApprovalFilterProvider.notifier).state =
                      PaymentStatus.confirmed,
                ),
                _Pill(
                  label: l10n.rejected,
                  selected: filter == PaymentStatus.rejected,
                  onTap: () => ref.read(paymentApprovalFilterProvider.notifier).state =
                      PaymentStatus.rejected,
                ),
                _Pill(
                  label: l10n.all,
                  selected: filter == null,
                  onTap: () =>
                      ref.read(paymentApprovalFilterProvider.notifier).state = null,
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (payments) {
                if (payments.isEmpty) {
                  return EmptyState(message: l10n.noPaymentsFilter);
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(paymentApprovalsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = payments[index];
                      return SectionCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.memberName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                _badge(p.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${p.receiptNumber} · ${_methodLabel(p.method, l10n)}',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFmt.format(p.date),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            MoneyText(p.amount),
                            if (p.walletAccount != null && p.walletAccount!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(l10n.walletLine(p.walletAccount!), style: const TextStyle(fontSize: 12)),
                            ],
                            if (p.transactionId != null && p.transactionId!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(l10n.txnLine(p.transactionId!), style: const TextStyle(fontSize: 12)),
                            ],
                            if (p.collectorName != null) ...[
                              const SizedBox(height: 2),
                              Text(l10n.collectorLine(p.collectorName!), style: const TextStyle(fontSize: 12)),
                            ],
                            if (p.rejectionReason != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                l10n.reasonLabel(p.rejectionReason!),
                                style: const TextStyle(color: AppColors.unpaid, fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 8),
                            ...p.allocations.map(
                              (a) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '${DateFormat('MMM yyyy').format(a.billingMonth)} · ৳ ${a.amount}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                            if (p.isPending) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton(
                                      label: l10n.reject,
                                      outlined: true,
                                      onPressed: () => _reject(ref, context, p),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: AppButton(
                                      label: l10n.accept,
                                      onPressed: () => _approve(ref, context, p),
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
