import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/utils/receipt_share.dart';
import '../../core/widgets/auth_background.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../l10n/app_localizations.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen.payment({super.key, required PaymentRecord payment})
      : _payment = payment,
        _donation = null;

  const ReceiptScreen.donation({super.key, required EventDonation donation})
      : _donation = donation,
        _payment = null;

  final PaymentRecord? _payment;
  final EventDonation? _donation;

  String get _message => _payment != null
      ? paymentReceiptMessage(_payment!)
      : donationReceiptMessage(_donation!);

  Future<void> _share(BuildContext context) async {
    final opened = await shareViaWhatsApp(_message);
    if (!context.mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp is not available. Receipt copied.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = _payment;
    final donation = _donation;
    final date = DateFormat('dd MMM yyyy').format(
      payment?.date ?? donation!.date,
    );
    final receiptNo = payment?.receiptNumber ?? donation!.receiptNumber;
    final amount = payment?.amount ?? donation!.amount;
    final title = payment != null ? 'PAYMENT RECEIPT' : 'DONATION RECEIPT';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(title: context.l10n.receipt),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                SectionCard(
                  child: Column(
                    children: [
                      const BrandMark(height: 72, radius: 12),
                      const SizedBox(height: 12),
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        AppConstants.tagline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _row('Receipt', receiptNo),
                      _row('Date', date),
                      if (payment != null)
                        _row(
                          'Status',
                          payment.isPending
                              ? 'Pending approval'
                              : payment.status == PaymentStatus.rejected
                                  ? 'Rejected'
                                  : 'Confirmed',
                        ),
                      const Divider(height: 28),
                      if (payment != null) ...[
                        _row('Member', payment.memberName),
                        _row('Amount', formatTaka(amount)),
                        _row('Method', paymentMethodLabel(payment.method)),
                        if (payment.collectorName != null &&
                            payment.collectorName!.isNotEmpty)
                          _row(
                            payment.method == PaymentMethod.handCash
                                ? 'Received by'
                                : 'Collector',
                            payment.collectorName!,
                          ),
                        if (payment.walletAccount?.isNotEmpty ?? false)
                          _row('Wallet', payment.walletAccount!),
                        if (payment.transactionId?.isNotEmpty ?? false)
                          _row('Txn ID', payment.transactionId!),
                        const Divider(height: 28),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Covers',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...payment.allocations.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    DateFormat('MMMM yyyy').format(a.billingMonth),
                                  ),
                                ),
                                Text(formatTaka(a.amount)),
                              ],
                            ),
                          ),
                        ),
                      ] else if (donation != null) ...[
                        _row('Campaign', donation.eventTitle),
                        _row('Donor', donation.donorName),
                        _row(
                          'Type',
                          donation.donorType == DonorType.member
                              ? 'Member'
                              : 'Non-member',
                        ),
                        if (donation.referredByName != null)
                          _row('Referred by', donation.referredByName!),
                        _row('Amount', formatTaka(amount)),
                        _row('Method', paymentMethodLabel(donation.method)),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Thank you',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: AppButton(
                label: 'Share WhatsApp',
                outlined: true,
                onPressed: () => _share(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(k, style: const TextStyle(color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(
                v,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}
