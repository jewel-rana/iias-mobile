import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/navigation/back_fallback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';
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
  int _periodMonth = DateTime.now().month;
  int _periodYear = DateTime.now().year;
  List<SalaryPeriod> _salaryPeriods = [];
  PaymentMethod? _method = PaymentMethod.cashToCollector;
  bool _loading = false;
  bool _titleTouched = false;

  bool get _isSalary =>
      _head?.kind == ExpenseHeadKind.salary ||
      widget.initialKind == ExpenseHeadKind.salary;

  DateTime get _salaryPeriod => DateTime(_periodYear, _periodMonth, 1);

  SalaryPeriod? get _selectedSalaryPeriod {
    for (final p in _salaryPeriods) {
      if (p.month.year == _periodYear && p.month.month == _periodMonth) {
        return p;
      }
    }
    return null;
  }

  bool get _selectedSalaryPaid => _selectedSalaryPeriod?.isPaid == true;

  int get _dueCount => _salaryPeriods.where((p) => !p.isPaid).length;

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
      _recurrence = head.kind == ExpenseHeadKind.salary
          ? ExpenseRecurrence.monthly
          : head.defaultRecurrence;
      if (!_titleTouched || _title.text.trim().isEmpty) {
        if (head.kind == ExpenseHeadKind.salary) {
          _title.text =
              '${head.name} — ${DateFormat('MMMM yyyy').format(_salaryPeriod)}';
        } else if (head.kind == ExpenseHeadKind.festivalBonus) {
          _title.text = head.name;
        } else {
          _title.text = head.name;
        }
      }
    });
    _loadSalaryDues(head);
  }

  Future<void> _loadSalaryDues(ExpenseHead head) async {
    if (head.kind != ExpenseHeadKind.salary) {
      setState(() => _salaryPeriods = []);
      return;
    }
    try {
      final rows = await ref.read(repositoryProvider).getSalaryDues(
            expenseHeadId: head.id,
          );
      if (!mounted) return;
      final periods = rows.isEmpty ? <SalaryPeriod>[] : rows.first.periods;
      SalaryPeriod? firstDue;
      for (final p in periods) {
        if (!p.isPaid) {
          firstDue = p;
          break;
        }
      }
      setState(() {
        _salaryPeriods = periods;
        if (firstDue != null) {
          _periodMonth = firstDue.month.month;
          _periodYear = firstDue.month.year;
          if (!_titleTouched) {
            _title.text =
                '${head.name} — ${DateFormat('MMMM yyyy').format(firstDue.month)}';
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _salaryPeriods = []);
    }
  }

  void _setSalaryPeriod(int month, int year) {
    setState(() {
      _periodMonth = month;
      _periodYear = year;
      if (_head != null && (!_titleTouched || _title.text.trim().isEmpty)) {
        _title.text =
            '${_head!.name} — ${DateFormat('MMMM yyyy').format(DateTime(year, month))}';
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
      if (_head != null && !_titleTouched && !_isSalary) _applyHead(_head!);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_head == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectExpenseHead)),
      );
      return;
    }
    if (_isSalary && _selectedSalaryPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.salaryAlreadyPaid(
              DateFormat('MMMM yyyy', Localizations.localeOf(context).toString())
                  .format(_salaryPeriod),
            ),
          ),
        ),
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
            periodMonth: _isSalary ? _salaryPeriod : null,
          );
      ref.invalidate(expensesProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(salaryDuesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.expenseRecorded)),
      );
      context.go('/expenses');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotSave(e))),
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
    final headsAsync = ref.watch(expenseHeadsProvider(widget.initialKind));
    final title = switch (widget.initialKind) {
      ExpenseHeadKind.salary => l10n.paySalary,
      ExpenseHeadKind.festivalBonus => l10n.festivalBonus,
      _ => l10n.addExpense,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(
        title: title,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => popOrGo(context, '/expenses'),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/expense-heads'),
            child: Text(l10n.heads),
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
                    Text(
                      l10n.noExpenseHeadsHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: l10n.manageHeads,
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
                        l10n.expenseDetails,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.expenseDetailsHint,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<ExpenseHead>(
                        isExpanded: true,
                        value: heads.cast<ExpenseHead?>().firstWhere(
                              (h) => h?.id == _head?.id,
                              orElse: () => heads.first,
                            ),
                        decoration: InputDecoration(
                          labelText: l10n.expenseHead,
                        ),
                        selectedItemBuilder: (context) => heads
                            .map(
                              (h) => Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${h.name} (${l10n.expenseKindLabel(h.kind)})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        items: heads
                            .map(
                              (h) => DropdownMenuItem(
                                value: h,
                                child: Text('${h.name} (${l10n.expenseKindLabel(h.kind)})'),
                              ),
                            )
                            .toList(),
                        onChanged: (h) {
                          if (h != null) _applyHead(h);
                        },
                      ),
                      if (_isSalary) ...[
                        const SizedBox(height: 14),
                        Text(
                          l10n.salaryMonth,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<int>(
                                isExpanded: true,
                                value: _periodMonth,
                                decoration: InputDecoration(
                                  labelText: l10n.month,
                                ),
                                items: List.generate(12, (i) {
                                  final month = i + 1;
                                  return DropdownMenuItem(
                                    value: month,
                                    child: Text(
                                      DateFormat('MMMM', locale)
                                          .format(DateTime(2026, month)),
                                    ),
                                  );
                                }),
                                onChanged: (m) {
                                  if (m != null) _setSalaryPeriod(m, _periodYear);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<int>(
                                isExpanded: true,
                                value: _periodYear,
                                decoration: InputDecoration(
                                  labelText: l10n.year,
                                ),
                                items: [
                                  for (var y = DateTime.now().year - 4;
                                      y <= DateTime.now().year;
                                      y++)
                                    DropdownMenuItem(
                                      value: y,
                                      child: Text('$y'),
                                    ),
                                ],
                                onChanged: (y) {
                                  if (y != null) _setSalaryPeriod(_periodMonth, y);
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_dueCount > 0) ...[
                          const SizedBox(height: 10),
                          Text(
                            l10n.unpaidSalaryMonths(_dueCount),
                            style: const TextStyle(
                              color: AppColors.unpaid,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (_salaryPeriods.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _salaryPeriods.map((p) {
                              final selected = p.month.year == _periodYear &&
                                  p.month.month == _periodMonth;
                              return ChoiceChip(
                                selected: selected,
                                label: Text(
                                  '${DateFormat('MMM yyyy', locale).format(p.month)} · ${p.isPaid ? l10n.paid : l10n.due}',
                                ),
                                selectedColor: p.isPaid
                                    ? AppColors.paid.withValues(alpha: 0.18)
                                    : AppColors.unpaid.withValues(alpha: 0.18),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: p.isPaid
                                      ? AppColors.paid
                                      : AppColors.unpaid,
                                ),
                                onSelected: (_) =>
                                    _setSalaryPeriod(p.month.month, p.month.year),
                              );
                            }).toList(),
                          ),
                        ],
                        if (_selectedSalaryPaid) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.thisMonthAlreadyPaid,
                            style: const TextStyle(color: AppColors.unpaid, fontSize: 13),
                          ),
                        ],
                      ],
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _title,
                        onChanged: (_) => _titleTouched = true,
                        decoration: InputDecoration(
                          labelText: l10n.title,
                          hintText: l10n.expenseTitleHint,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _amount,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.amountTaka,
                          prefixText: '৳ ',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n < 1) return l10n.enterValidAmount;
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.type,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _TypeTile(
                              label: l10n.monthly,
                              subtitle: l10n.recurring,
                              selected: _recurrence == ExpenseRecurrence.monthly,
                              onTap: () => setState(
                                () => _recurrence = ExpenseRecurrence.monthly,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TypeTile(
                              label: l10n.occasional,
                              subtitle: l10n.oneTime,
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
                        title: Text(_isSalary ? l10n.paidOn : l10n.expenseDate),
                        subtitle: Text(dateFmt.format(_date)),
                        trailing: const Icon(Icons.calendar_today_rounded),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<PaymentMethod?>(
                        value: _method,
                        decoration: InputDecoration(labelText: l10n.paidVia),
                        items: [
                          DropdownMenuItem(
                            value: PaymentMethod.cashToCollector,
                            child: Text(l10n.cash),
                          ),
                          DropdownMenuItem(
                            value: PaymentMethod.mobileWallet,
                            child: Text(l10n.mobileWallet),
                          ),
                          DropdownMenuItem(
                            value: PaymentMethod.handCash,
                            child: Text(l10n.handCash),
                          ),
                        ],
                        onChanged: (v) => setState(() => _method = v),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _notes,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.notesOptional,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: _isSalary ? l10n.paySalary : l10n.saveExpense,
                  loading: _loading,
                  onPressed: _selectedSalaryPaid ? null : _save,
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
