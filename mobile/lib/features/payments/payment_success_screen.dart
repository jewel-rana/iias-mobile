import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/receipt_share.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../l10n/app_localizations.dart';
import 'receipt_screen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key, required this.payment});

  final PaymentRecord payment;

  Future<void> _shareWhatsApp(BuildContext context) async {
    final opened = await shareViaWhatsApp(paymentReceiptMessage(payment));
    if (!context.mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.whatsappUnavailable)),
      );
    }
  }

  void _viewReceipt(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptScreen.payment(payment: payment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: IiasAppBar(
        title: payment.isPending ? context.l10n.paymentSubmitted : context.l10n.paymentRecorded,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Column(
                  children: [
                    Container(
                      height: 88,
                      width: 88,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      payment.isPending ? l10n.paymentSubmitted : l10n.paymentRecorded,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (payment.isPending) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.waitingAdminApproval,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 8),
                    MoneyText(payment.amount, style: Theme.of(context).textTheme.headlineMedium),
                    Text(
                      l10n.monthsForMember(payment.allocations.length, payment.memberName),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    SectionCard(
                      child: Column(
                        children: [
                          _row(l10n.receipt, payment.receiptNumber),
                          _row(
                            l10n.statusLabel,
                            payment.isPending
                                ? l10n.pendingApproval
                                : payment.status == PaymentStatus.rejected
                                    ? l10n.rejected
                                    : l10n.confirmed,
                          ),
                          _row(l10n.date, DateFormat('dd MMM yyyy', locale).format(payment.date)),
                          _row(l10n.method, l10n.paymentMethodName(payment.method)),
                          if (payment.method == PaymentMethod.mobileWallet) ...[
                            if (payment.organizationWalletDisplay != null)
                              _row(l10n.organizationWalletTo, payment.organizationWalletDisplay!),
                            if (payment.walletAccount != null &&
                                payment.walletAccount!.isNotEmpty)
                              _row(l10n.customerWalletFrom, payment.walletAccount!),
                            if (payment.transactionId != null &&
                                payment.transactionId!.isNotEmpty)
                              _row(l10n.transactionId, payment.transactionId!),
                          ],
                          if (payment.method == PaymentMethod.cashToCollector &&
                              payment.collectorName != null)
                            _row(l10n.collector, payment.collectorName!),
                          if (payment.method == PaymentMethod.handCash &&
                              payment.collectorName != null)
                            _row(l10n.receivedBy, payment.collectorName!),
                          const Divider(height: 24),
                          ...payment.allocations.map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(DateFormat('MMMM yyyy', locale).format(a.billingMonth)),
                                  ),
                                  Text('৳ ${a.amount}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: l10n.shareWhatsApp,
                      outlined: true,
                      onPressed: () => _shareWhatsApp(context),
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: l10n.viewReceipt,
                      onPressed: () => _viewReceipt(context),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        if (payment.isPending) {
                          context.go('/member-home');
                        } else {
                          context.go('/dashboard');
                        }
                      },
                      child: Text(payment.isPending ? l10n.backToHome : l10n.backToDashboard),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(k, style: const TextStyle(color: AppColors.textSecondary)),
            const Spacer(),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
