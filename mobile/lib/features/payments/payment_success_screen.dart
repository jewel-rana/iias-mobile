import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key, required this.payment});

  final PaymentRecord payment;

  String _methodLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.mobileWallet:
        return 'Mobile Wallet';
      case PaymentMethod.cashToCollector:
        return 'Cash to collector';
      case PaymentMethod.handCash:
        return 'Hand Cash';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
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
                'Payment Recorded',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              MoneyText(payment.amount, style: Theme.of(context).textTheme.headlineMedium),
              Text(
                '${payment.allocations.length} months · ${payment.memberName}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              SectionCard(
                child: Column(
                  children: [
                    _row('Receipt', payment.receiptNumber),
                    _row('Date', DateFormat('dd MMM yyyy').format(payment.date)),
                    _row('Method', _methodLabel(payment.method)),
                    if (payment.collectorName != null) _row('Collector', payment.collectorName!),
                    const Divider(height: 24),
                    ...payment.allocations.map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(DateFormat('MMMM yyyy').format(a.billingMonth))),
                            Text('৳ ${a.amount}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(label: 'Share WhatsApp', outlined: true, onPressed: () {}),
              const SizedBox(height: 10),
              AppButton(label: 'View Receipt', onPressed: () {}),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
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
