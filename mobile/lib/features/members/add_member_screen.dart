import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/navigation/back_fallback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/utils/receipt_share.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../data/repositories/payment_allocator.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_screen.dart';
import 'members_screen.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _amount = TextEditingController(text: '500');
  final _collector = TextEditingController();
  final _openingAmount = TextEditingController();
  DateTime _joinedAt = DateTime.now();
  bool _recordOpening = false;
  PaymentMethod _openingMethod = PaymentMethod.cashToCollector;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _amount.dispose();
    _collector.dispose();
    _openingAmount.dispose();
    super.dispose();
  }

  int get _monthlyAmount => int.tryParse(_amount.text.trim()) ?? 0;

  int get _dueMonthCount {
    final start = DateTime(_joinedAt.year, _joinedAt.month);
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    if (start.isAfter(now)) return 1;
    return (now.year - start.year) * 12 + (now.month - start.month) + 1;
  }

  int get _suggestedOpening =>
      (_dueMonthCount * _monthlyAmount).clamp(0, 999999999);

  void _syncOpeningAmount() {
    if (!_recordOpening) return;
    _openingAmount.text = '$_suggestedOpening';
  }

  Future<void> _pickJoinedAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinedAt,
      firstDate: DateTime(2018),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _joinedAt = picked);
      _syncOpeningAmount();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(repositoryProvider);
      final member = await repo.createMember(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            monthlyAmount: int.parse(_amount.text.trim()),
            collectorName: _collector.text.trim(),
            email: _email.text.trim(),
            joinedAt: _joinedAt,
          );
      ref.invalidate(membersProvider);
      ref.invalidate(dashboardProvider);

      PaymentRecord? payment;
      if (_recordOpening) {
        final paid = int.tryParse(_openingAmount.text.trim()) ?? 0;
        if (paid > 0) {
          final dues = await repo.getMemberDues(member.id);
          final allocations = suggestAllocations(
            dues: dues,
            paymentAmount: paid,
            monthlyAmount: member.monthlyAmount,
          );
          if (allocations.isNotEmpty) {
            payment = await repo.createPayment(
              memberId: member.id,
              amount: allocations.fold<int>(0, (sum, a) => sum + a.amount),
              method: _openingMethod,
              allocations: allocations,
              collectorName: _collector.text.trim(),
            );
          }
        }
      }

      if (!mounted) return;
      if (payment != null) {
        context.go('/payment-success', extra: payment);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member added. Record payment for due months.')),
      );
      context.go('/collect/${member.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add member: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final monthFmt = DateFormat('MMM yyyy');
    final start = DateTime(_joinedAt.year, _joinedAt.month);
    final now = DateTime(DateTime.now().year, DateTime.now().month);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(
        title: context.l10n.addMember,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => popOrGo(context, '/members'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New member details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Joining date creates unpaid dues from that month through today.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Abdul Karim',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '01XXXXXXXXX',
                      prefixText: '+880  ',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().length < 10) ? 'Enter a valid phone' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email (optional)',
                      hintText: 'name@example.com',
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Joining date'),
                    subtitle: Text(
                      '${dateFmt.format(_joinedAt)} · $_dueMonthCount month${_dueMonthCount == 1 ? '' : 's'} due (${monthFmt.format(start)} – ${monthFmt.format(now)})',
                    ),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: _pickJoinedAt,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(_syncOpeningAmount),
                    decoration: const InputDecoration(
                      labelText: 'Monthly Donation',
                      prefixText: '৳  ',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _collector,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Collector (optional)',
                      hintText: 'Rahim Ahmed',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Record payment for previous months',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      _monthlyAmount > 0
                          ? 'Outstanding ${formatTaka(_suggestedOpening)} for $_dueMonthCount month${_dueMonthCount == 1 ? '' : 's'}'
                          : 'Enter monthly amount first',
                    ),
                    value: _recordOpening,
                    onChanged: (v) {
                      setState(() {
                        _recordOpening = v;
                        if (v) _openingAmount.text = '$_suggestedOpening';
                      });
                    },
                  ),
                  if (_recordOpening) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _openingAmount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Payment amount',
                        prefixText: '৳  ',
                      ),
                      validator: (v) {
                        if (!_recordOpening) return null;
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 1) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<PaymentMethod>(
                      isExpanded: true,
                      value: _openingMethod,
                      decoration: const InputDecoration(labelText: 'Paid via'),
                      items: PaymentMethod.values
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(paymentMethodLabel(m)),
                            ),
                          )
                          .toList(),
                      onChanged: (m) {
                        if (m != null) setState(() => _openingMethod = m);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _recordOpening ? 'Save & Record Payment' : 'Save Member',
              loading: _loading,
              onPressed: _save,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Cancel',
              outlined: true,
              onPressed: () => popOrGo(context, '/members'),
            ),
          ],
        ),
      ),
    );
  }
}
