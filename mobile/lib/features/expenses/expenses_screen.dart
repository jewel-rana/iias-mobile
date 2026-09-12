import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_screen.dart';

final expensesKindFilterProvider = StateProvider<ExpenseHeadKind?>((ref) => null);
final expensesRecurrenceFilterProvider =
    StateProvider<ExpenseRecurrence?>((ref) => null);

final expensesProvider = FutureProvider((ref) {
  return ref.watch(repositoryProvider).getExpenses(
        recurrence: ref.watch(expensesRecurrenceFilterProvider),
        kind: ref.watch(expensesKindFilterProvider),
      );
});

final salaryDuesProvider = FutureProvider((ref) {
  return ref.watch(repositoryProvider).getSalaryDues();
});

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(expensesKindFilterProvider);
    final recurrence = ref.watch(expensesRecurrenceFilterProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final statsAsync = ref.watch(dashboardProvider);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(
        title: context.l10n.expenses,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Manage heads',
            onPressed: () => context.push('/expense-heads'),
            icon: const Icon(Icons.category_outlined),
          ),
          IconButton(
            tooltip: 'Add expense',
            onPressed: () => context.push('/add-expense'),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-expense'),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: statsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) => SectionCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _FundStat(
                        label: 'Funds Available',
                        value: stats.fundsAvailable,
                        color: AppColors.primary,
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppColors.border),
                    Expanded(
                      child: _FundStat(
                        label: 'Total Spent',
                        value: stats.totalExpenses,
                        color: AppColors.unpaid,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _Pill(
                  label: 'All',
                  selected: kind == null,
                  onTap: () =>
                      ref.read(expensesKindFilterProvider.notifier).state = null,
                ),
                _Pill(
                  label: 'Salary',
                  selected: kind == ExpenseHeadKind.salary,
                  onTap: () => ref.read(expensesKindFilterProvider.notifier).state =
                      ExpenseHeadKind.salary,
                ),
                _Pill(
                  label: 'Festival Bonus',
                  selected: kind == ExpenseHeadKind.festivalBonus,
                  onTap: () => ref.read(expensesKindFilterProvider.notifier).state =
                      ExpenseHeadKind.festivalBonus,
                ),
                _Pill(
                  label: 'Operational',
                  selected: kind == ExpenseHeadKind.operational,
                  onTap: () => ref.read(expensesKindFilterProvider.notifier).state =
                      ExpenseHeadKind.operational,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _Pill(
                  label: 'Any type',
                  selected: recurrence == null,
                  onTap: () => ref
                      .read(expensesRecurrenceFilterProvider.notifier)
                      .state = null,
                ),
                _Pill(
                  label: 'Monthly',
                  selected: recurrence == ExpenseRecurrence.monthly,
                  onTap: () => ref
                      .read(expensesRecurrenceFilterProvider.notifier)
                      .state = ExpenseRecurrence.monthly,
                ),
                _Pill(
                  label: 'Occasional',
                  selected: recurrence == ExpenseRecurrence.occasional,
                  onTap: () => ref
                      .read(expensesRecurrenceFilterProvider.notifier)
                      .state = ExpenseRecurrence.occasional,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/add-expense?kind=salary',
                    ),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Pay Salary'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/add-expense?kind=festival_bonus',
                    ),
                    icon: const Icon(Icons.celebration_outlined, size: 18),
                    label: const Text('Festival Bonus'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ref.watch(salaryDuesProvider).maybeWhen(
                data: (dues) {
                  final dueHeads = dues.where((d) => d.dueCount > 0).toList();
                  if (dueHeads.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Material(
                      color: AppColors.unpaid.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context.push('/add-expense?kind=salary'),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.unpaid,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  dueHeads
                                      .map((d) =>
                                          '${d.headName}: ${d.dueCount} month${d.dueCount == 1 ? '' : 's'} due')
                                      .join(' · '),
                                  style: const TextStyle(
                                    color: AppColors.unpaid,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.unpaid,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
          Expanded(
            child: expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const EmptyState(message: 'No expenses recorded yet');
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(expensesProvider);
                    ref.invalidate(dashboardProvider);
                    ref.invalidate(salaryDuesProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final e = expenses[index];
                      return SectionCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _iconFor(e.headKind),
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${e.headName} · ${e.headKind.label} · ${e.recurrence.label}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    e.periodMonth != null
                                        ? 'Salary month ${DateFormat('MMMM yyyy').format(e.periodMonth!)} · Paid ${dateFmt.format(e.expenseDate)}'
                                        : dateFmt.format(e.expenseDate),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (e.notes != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      e.notes!,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            MoneyText(
                              e.amount,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.unpaid,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ExpenseHeadKind kind) => switch (kind) {
        ExpenseHeadKind.salary => Icons.payments_rounded,
        ExpenseHeadKind.festivalBonus => Icons.celebration_rounded,
        ExpenseHeadKind.operational => Icons.build_circle_outlined,
        ExpenseHeadKind.charity => Icons.volunteer_activism_outlined,
        ExpenseHeadKind.other => Icons.receipt_long_outlined,
      };
}

class _FundStat extends StatelessWidget {
  const _FundStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        MoneyText(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
