import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/receipt_share.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../payments/receipt_screen.dart';

class DonationSuccessScreen extends StatelessWidget {
  const DonationSuccessScreen({super.key, required this.donation});

  final EventDonation donation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: IiasAppBar(title: l10n.donationReceived),
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
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.primary,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.donationReceived,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    MoneyText(
                      donation.amount,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      donation.eventTitle,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    SectionCard(
                      child: Column(
                        children: [
                          _row(l10n.receipt, donation.receiptNumber),
                          _row(l10n.donor, donation.donorName),
                          _row(
                            l10n.type,
                            donation.donorType == DonorType.member
                                ? l10n.member
                                : l10n.nonMember,
                          ),
                          if (donation.referredByName != null)
                            _row(l10n.referredBy, donation.referredByName!),
                          _row(
                            l10n.date,
                            DateFormat('dd MMM yyyy', locale).format(donation.date),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: l10n.shareWhatsApp,
                      outlined: true,
                      onPressed: () async {
                        final opened = await shareViaWhatsApp(
                          donationReceiptMessage(donation),
                        );
                        if (!context.mounted) return;
                        if (!opened) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.whatsappUnavailable),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: l10n.viewReceipt,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ReceiptScreen.donation(donation: donation),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: l10n.backToFunds,
                      onPressed: () => context.go('/events'),
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
