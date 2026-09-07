import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../dashboard/dashboard_screen.dart';
import 'expenses_screen.dart';

final expenseHeadsProvider =
    FutureProvider.family<List<ExpenseHead>, ExpenseHeadKind?>((ref, kind) {
  return ref.watch(repositoryProvider).getExpenseHeads(
        activeOnly: true,
        kind: kind,
      );
});

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.initialKind});

  final ExpenseHeadKind? initialKind;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  ExpenseHead? _head;
  ExpenseRecurrence _recurrence = ExpenseRecurrence.monthly;
  DateTime _date = DateTime.now();
  PaymentMethod? _method = PaymentMethod.cashToCollector;
  bool _loading = false;
  bool _titleTouched = false;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _applyHead(ExpenseHead head) {
    setState(() {
      _head = head;
      _recurrence = head.defaultRecurrence;
      if (!_titleTouched || _title.text.trim().isEmpty) {
        final month = DateFormat('MMMM yyyy').format(_date);
        if (head.kind == ExpenseHeadKind.salary) {
          _title.text = '${head.name} — $month';
        } else if (head.kind == ExpenseHeadKind.festivalBonus) {
          _title.text = head.name;
        } else {
          _title.text = head.name;
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
      if (_head != null && !_titleTouched) _applyHead(_head!);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_head == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an expense head')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(repositoryProvider).createExpense(
            title: _title.text.trim(),
            expenseHeadId: _head!.id,
            recurrence: _recurrence,
            amount: int.parse(_amount.text.trim()),
            expenseDate: _date,
            paymentMethod: _method,
            notes: _notes.text.trim(),
          );
      ref.invalidate(expensesProvider);
      ref.invalidate(dashboardProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense recorded')),
      );
      context.go('/expenses');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final headsAsync = ref.watch(expenseHeadsProvider(widget.initialKind));
    final title = switch (widget.initialKind) {
      ExpenseHeadKind.salary => 'Pay Salary',
      ExpenseHeadKind.festivalBonus => 'Festival Bonus',
      _ => 'Add Expense',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/expenses');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/expense-heads'),
            child: const Text('Heads'),
          ),
        ],
      ),
      body: headsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (heads) {
          if (heads.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No expense heads yet. Create Salary or Festival Bonus heads first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Manage Heads',
                      onPressed: () => context.push('/expense-heads'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (_head == null || !heads.any((h) => h.id == _head!.id)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _applyHead(heads.first);
            });
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pick a head (Salary, Festival Bonus, etc.), then enter amount.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<ExpenseHead>(
                        value: heads.cast<ExpenseHead?>().firstWhere(
                              (h) => h?.id == _head?.id,
                              orElse: () => heads.first,
                            ),
                        decoration: const InputDecoration(
                          labelText: 'Expense head',
                        ),
                        items: heads
                            .map(
                              (h) => DropdownMenuItem(
                                value: h,
                                child: Text('${h.name} (${h.kind.label})'),
                              ),
                            )
                            .toList(),
                        onChanged: (h) {
                          if (h != null) _applyHead(h);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _title,
                        onChanged: (_) => _titleTouched = true,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: "e.g. Imam's Salary — September",
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _amount,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount (৳)',
                          prefixText: '৳ ',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n < 1) return 'Enter a valid amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Type',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _TypeTile(
                              label: 'Monthly',
                              subtitle: 'Recurring',
                              selected: _recurrence == ExpenseRecurrence.monthly,
                              onTap: () => setState(
                                () => _recurrence = ExpenseRecurrence.monthly,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TypeTile(
                              label: 'Occasional',
                              subtitle: 'One-time',
                              selected:
                                  _recurrence == ExpenseRecurrence.occasional,
                              onTap: () => setState(
                                () =>
                                    _recurrence = ExpenseRecurrence.occasional,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Expense date'),
                        subtitle: Text(dateFmt.format(_date)),
                        trailing: const Icon(Icons.calendar_today_rounded),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<PaymentMethod?>(
                        value: _method,
                        decoration: const InputDecoration(labelText: 'Paid via'),
                        items: const [
                          DropdownMenuItem(
                            value: PaymentMethod.cashToCollector,
                            child: Text('Cash'),
                          ),
                          DropdownMenuItem(
                            value: PaymentMethod.mobileWallet,
                            child: Text('Mobile Wallet'),
                          ),
                          DropdownMenuItem(
                            value: PaymentMethod.handCash,
                            child: Text('Hand Cash'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _method = v),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _notes,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Save Expense',
                  loading: _loading,
                  onPressed: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
