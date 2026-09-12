import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/utils/receipt_share.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_screen.dart';
import '../members/member_detail_screen.dart';
import '../members/member_payments_screen.dart';
import '../members/members_screen.dart';
import 'payment_approvals_screen.dart';
import 'receipt_screen.dart';

final paymentDetailProvider =
    FutureProvider.autoDispose.family<PaymentRecord, String>((ref, id) {
  return ref.watch(repositoryProvider).getPayment(id);
});

class PaymentDetailScreen extends ConsumerWidget {
  const PaymentDetailScreen({
    super.key,
    required this.paymentId,
    this.payment,
  });

  final String paymentId;
  final PaymentRecord? payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = payment;
    if (initial != null && initial.id == paymentId) {
      return _PaymentDetailBody(payment: initial);
    }
    final async = ref.watch(paymentDetailProvider(paymentId));
    return async.when(
      loading: () => Scaffold(
        appBar: IiasAppBar(title: context.l10n.paymentDetails),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: IiasAppBar(title: context.l10n.paymentDetails),
        body: EmptyState(message: '$e'),
      ),
      data: (record) => _PaymentDetailBody(payment: record),
    );
  }
}

class _PaymentDetailBody extends ConsumerWidget {
  const _PaymentDetailBody({required this.payment});

  final PaymentRecord payment;

  String _statusLabel(AppLocalizations l10n) {
    if (payment.isPending) return l10n.pendingApproval;
    if (payment.status == PaymentStatus.rejected) return l10n.rejected;
    return l10n.confirmed;
  }

  Future<void> _share(BuildContext context) async {
    final opened = await shareViaWhatsApp(paymentReceiptMessage(payment));
    if (!context.mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.whatsappUnavailable)),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePayment),
        content: Text(
          l10n.deletePaymentHint(payment.receiptNumber, formatTaka(payment.amount)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(repositoryProvider).deletePayment(payment.id);
      ref.invalidate(dashboardProvider);
      ref.invalidate(membersProvider);
      ref.invalidate(paymentApprovalsProvider);
      ref.invalidate(memberPaymentsProvider(payment.memberId));
      ref.invalidate(memberDetailProvider(payment.memberId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paymentDeleted(payment.receiptNumber))),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deletePaymentFailed(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat('dd MMM yyyy · hh:mm a', locale);
    final monthFmt = DateFormat('MMMM yyyy', locale);
    final canDelete =
        ref.watch(authStateProvider)?.can(AppPermission.collectionCollect) ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(title: l10n.paymentDetails),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        payment.receiptNumber,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                    switch (payment.status) {
                      PaymentStatus.pending => const StatusBadge.pending(),
                      PaymentStatus.rejected => const StatusBadge.rejected(),
                      PaymentStatus.confirmed => const StatusBadge.confirmed(),
                    },
                  ],
                ),
                const SizedBox(height: 8),
                MoneyText(payment.amount),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              children: [
                _row(l10n.member, payment.memberName),
                _row(l10n.statusLabel, _statusLabel(l10n)),
                _row(l10n.date, dateFmt.format(payment.date)),
                _row(l10n.method, l10n.paymentMethodName(payment.method)),
                if (payment.collectorName != null && payment.collectorName!.isNotEmpty)
                  _row(
                    payment.method == PaymentMethod.handCash ? l10n.receivedBy : l10n.collector,
                    payment.collectorName!,
                  ),
                if (payment.walletAccount != null && payment.walletAccount!.isNotEmpty)
                  _row(l10n.walletAccount, payment.walletAccount!),
                if (payment.transactionId != null && payment.transactionId!.isNotEmpty)
                  _row(l10n.transactionId, payment.transactionId!),
                if (payment.rejectionReason != null && payment.rejectionReason!.isNotEmpty)
                  _row(l10n.reasonOptional, payment.rejectionReason!),
              ],
            ),
          ),
          if (payment.allocations.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.covers, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  ...payment.allocations.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(monthFmt.format(a.billingMonth))),
                          Text(
                            '৳ ${a.amount}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: l10n.viewReceipt,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReceiptScreen.payment(payment: payment),
              ),
            ),
          ),
          const SizedBox(height: 10),
          AppButton(
            label: l10n.shareWhatsApp,
            outlined: true,
            onPressed: () => _share(context),
          ),
          if (canDelete) ...[
            const SizedBox(height: 10),
            AppButton(
              label: l10n.deletePayment,
              outlined: true,
              onPressed: () => _delete(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
