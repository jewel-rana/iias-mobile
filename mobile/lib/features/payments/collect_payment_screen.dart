import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';

class CollectPaymentScreen extends ConsumerStatefulWidget {
  const CollectPaymentScreen({super.key, required this.memberId});

  final String memberId;

  @override
  ConsumerState<CollectPaymentScreen> createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends ConsumerState<CollectPaymentScreen> {
  Member? _member;
  List<MonthlyDue> _dues = [];
  final _amountCtrl = TextEditingController(text: '3000');
  PaymentMethod _method = PaymentMethod.cashToCollector;
  List<PaymentAllocation> _allocations = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
    _amountCtrl.addListener(_recalculate);
  }

  Future<void> _load() async {
    final repo = ref.read(repositoryProvider);
    final member = await repo.getMember(widget.memberId);
    final dues = await repo.getMemberDues(widget.memberId);
    setState(() {
      _member = member;
      _dues = dues;
    });
    _recalculate();
  }

  void _recalculate() {
    final member = _member;
    if (member == null) return;
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    setState(() {
      _allocations = allocatePayment(
        dues: _dues,
        amount: amount,
        monthlyAmount: member.monthlyAmount,
      );
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final member = _member;
    if (member == null) return;
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0 || _allocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount to allocate')),
      );
      return;
    }
    final total = _allocations.fold<int>(0, (s, a) => s + a.amount);
    if (total != amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Allocated ৳ $total must equal payment ৳ $amount')),
      );
      return;
    }

    setState(() => _loading = true);
    final payment = await ref.read(repositoryProvider).createPayment(
          memberId: member.id,
          amount: amount,
          method: _method,
          allocations: _allocations,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/payment-success', extra: payment);
  }

  @override
  Widget build(BuildContext context) {
    final member = _member;
    if (member == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final outstanding = _dues.where((d) => !d.isFullyPaid).toList();
    final allocated = _allocations.fold<int>(0, (s, a) => s + a.amount);
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Collect Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                Text('${member.memberCode} · ৳ ${member.monthlyAmount}/month',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Outstanding months', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (outstanding.isEmpty)
                  const Text('No dues — payment will be treated as advance',
                      style: TextStyle(color: AppColors.textSecondary))
                else
                  ...outstanding.map((d) => Text(
                        '${DateFormat('MMM yyyy').format(d.billingMonth)} · remaining ৳ ${d.remaining}',
                      )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Payment Amount', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(prefixText: '৳  '),
          ),
          const SizedBox(height: 16),
          const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600)),
          RadioListTile<PaymentMethod>(
            value: PaymentMethod.mobileWallet,
            groupValue: _method,
            title: const Text('Mobile Wallet'),
            onChanged: (v) => setState(() => _method = v!),
          ),
          RadioListTile<PaymentMethod>(
            value: PaymentMethod.cashToCollector,
            groupValue: _method,
            title: const Text('Cash to collector'),
            onChanged: (v) => setState(() => _method = v!),
          ),
          RadioListTile<PaymentMethod>(
            value: PaymentMethod.handCash,
            groupValue: _method,
            title: const Text('Hand Cash'),
            onChanged: (v) => setState(() => _method = v!),
          ),
          const SizedBox(height: 8),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Allocate Payment', style: TextStyle(fontWeight: FontWeight.w800)),
                const Text('Dues first, then advance months',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 12),
                ..._allocations.map((a) {
                  final isAdvance = a.billingMonth.isAfter(DateTime(2026, 9, 30));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_box, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(DateFormat('MMMM yyyy').format(a.billingMonth))),
                        if (isAdvance) const StatusBadge.advance(),
                        const SizedBox(width: 8),
                        Text('৳ ${a.amount}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Row(
                  children: [
                    const Text('Allocated'),
                    const Spacer(),
                    Text('৳ $allocated', style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: allocated == amount ? AppColors.primary : AppColors.danger,
                    )),
                  ],
                ),
                Row(
                  children: [
                    const Text('Remaining'),
                    const Spacer(),
                    Text('৳ ${amount - allocated}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppButton(label: 'Confirm Payment', loading: _loading, onPressed: _confirm),
        ],
      ),
    );
  }
}
