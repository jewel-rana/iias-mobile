import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../../data/models/models.dart';
import 'money.dart';

String paymentMethodLabel(PaymentMethod method) {
  return switch (method) {
    PaymentMethod.mobileWallet => 'Mobile Wallet',
    PaymentMethod.cashToCollector => 'Cash to collector',
    PaymentMethod.handCash => 'Hand Cash',
  };
}

String paymentReceiptMessage(PaymentRecord payment) {
  final date = DateFormat('dd MMM yyyy').format(payment.date);
  final months = payment.allocations
      .map((a) => DateFormat('MMMM yyyy').format(a.billingMonth))
      .join('\n');
  final status = payment.isPending
      ? 'Pending approval'
      : payment.status == PaymentStatus.rejected
          ? 'Rejected'
          : 'Confirmed';

  final extra = <String>[
    if (payment.method == PaymentMethod.mobileWallet &&
        (payment.walletAccount?.isNotEmpty ?? false))
      'Wallet: ${payment.walletAccount}',
    if (payment.method == PaymentMethod.mobileWallet &&
        (payment.transactionId?.isNotEmpty ?? false))
      'Txn ID: ${payment.transactionId}',
    if (payment.collectorName != null && payment.collectorName!.isNotEmpty)
      payment.method == PaymentMethod.handCash
          ? 'Received by: ${payment.collectorName}'
          : 'Collector: ${payment.collectorName}',
  ];

  return '''
*${AppConstants.appName}*
${AppConstants.tagline}

*PAYMENT RECEIPT*
Receipt: ${payment.receiptNumber}
Date: $date
Status: $status

Member: ${payment.memberName}
Amount: ${formatTaka(payment.amount)}

Covers:
$months

Method: ${paymentMethodLabel(payment.method)}
${extra.join('\n')}

Thank you for your contribution.
'''.trim();
}

String donationReceiptMessage(EventDonation donation) {
  final date = DateFormat('dd MMM yyyy').format(donation.date);
  return '''
*${AppConstants.appName}*
${AppConstants.tagline}

*DONATION RECEIPT*
Receipt: ${donation.receiptNumber}
Date: $date

Campaign: ${donation.eventTitle}
Donor: ${donation.donorName}
Type: ${donation.donorType == DonorType.member ? 'Member' : 'Non-member'}
${donation.referredByName != null ? 'Referred by: ${donation.referredByName}\n' : ''}Amount: ${formatTaka(donation.amount)}
Method: ${paymentMethodLabel(donation.method)}

Thank you for your contribution.
'''.trim();
}

/// Opens WhatsApp with [message]. Copies the text if WhatsApp cannot be opened.
Future<bool> shareViaWhatsApp(String message) async {
  final encoded = Uri.encodeComponent(message);
  final candidates = [
    Uri.parse('whatsapp://send?text=$encoded'),
    Uri.parse('https://wa.me/?text=$encoded'),
  ];

  for (final uri in candidates) {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return true;
    } catch (_) {}
  }

  await Clipboard.setData(ClipboardData(text: message));
  return false;
}
