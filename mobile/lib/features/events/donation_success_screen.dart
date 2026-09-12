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
    return Scaffold(
      appBar: IiasAppBar(title: context.l10n.donationReceived),
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
                      'Donation Received',
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
                          _row('Receipt', donation.receiptNumber),
                          _row('Donor', donation.donorName),
                          _row(
                            'Type',
                            donation.donorType == DonorType.member
                                ? 'Member'
                                : 'Non-member',
                          ),
                          if (donation.referredByName != null)
                            _row('Referred by', donation.referredByName!),
                          _row(
                            'Date',
                            DateFormat('dd MMM yyyy').format(donation.date),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Share WhatsApp',
                      outlined: true,
                      onPressed: () async {
                        final opened = await shareViaWhatsApp(
                          donationReceiptMessage(donation),
                        );
                        if (!context.mounted) return;
                        if (!opened) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'WhatsApp is not available. Receipt copied.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'View Receipt',
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
                      label: 'Back to Funds',
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
