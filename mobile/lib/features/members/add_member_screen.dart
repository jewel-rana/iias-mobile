import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/navigation/back_fallback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
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
        SnackBar(content: Text(context.l10n.memberAdded)),
      );
      context.go('/collect/${member.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotAddMember(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat('dd MMM yyyy', locale);
    final monthFmt = DateFormat('MMM yyyy', locale);
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
                    l10n.newMemberDetails,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.joiningDateCreatesDues,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.fullName,
                      hintText: 'Abdul Karim',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.nameRequired : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.phoneNumber,
                      hintText: '01XXXXXXXXX',
                      prefixText: '+880  ',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().length < 10) ? l10n.enterValidPhone : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.emailOptional,
                      hintText: 'name@example.com',
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      if (!value.contains('@') || !value.contains('.')) {
                        return l10n.enterValidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.joiningDate),
                    subtitle: Text(
                      '${dateFmt.format(_joinedAt)} · ${l10n.joiningDateRange(_dueMonthCount, monthFmt.format(start), monthFmt.format(now))}',
                    ),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: _pickJoinedAt,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(_syncOpeningAmount),
                    decoration: InputDecoration(
                      labelText: l10n.monthlyDonation,
                      prefixText: '৳  ',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return l10n.enterValidAmount;
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _collector,
                    decoration: InputDecoration(
                      labelText: l10n.assignedCollectorOptional,
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
                    title: Text(
                      l10n.recordPreviousMonths,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      _monthlyAmount > 0
                          ? l10n.outstandingForMonths(
                              formatTaka(_suggestedOpening),
                              _dueMonthCount,
                            )
                          : l10n.enterMonthlyAmountFirst,
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
                      decoration: InputDecoration(
                        labelText: l10n.paymentAmount,
                        prefixText: '৳  ',
                      ),
                      validator: (v) {
                        if (!_recordOpening) return null;
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 1) return l10n.enterValidAmount;
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<PaymentMethod>(
                      isExpanded: true,
                      value: _openingMethod,
                      decoration: InputDecoration(labelText: l10n.paidVia),
                      items: PaymentMethod.values
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(l10n.paymentMethodName(m)),
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
              label: _recordOpening ? l10n.saveAndRecordPayment : l10n.saveMember,
              loading: _loading,
              onPressed: _save,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: l10n.cancel,
              outlined: true,
              onPressed: () => popOrGo(context, '/members'),
            ),
          ],
        ),
      ),
    );
  }
}
