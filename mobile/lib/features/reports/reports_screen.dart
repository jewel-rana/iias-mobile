import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';

DateTime _monthStart(DateTime value) => DateTime(value.year, value.month);

final reportMonthProvider = StateProvider<DateTime>((ref) {
  return _monthStart(DateTime.now());
});

final reportProvider = FutureProvider((ref) {
  final month = ref.watch(reportMonthProvider);
  return ref.watch(repositoryProvider).getReport(month: month);
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  String _monthQuery(DateTime month) =>
      '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

  Future<void> _pickMonth(BuildContext context, WidgetRef ref, DateTime current) async {
    final now = _monthStart(DateTime.now());
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isAfter(now) ? now : current,
      firstDate: DateTime(now.year - 5, 1),
      lastDate: lastDay,
      initialDatePickerMode: DatePickerMode.year,
      helpText: context.l10n.selectMonth,
    );
    if (picked == null) return;
    ref.read(reportMonthProvider.notifier).state = _monthStart(picked);
  }

  Widget _monthPicker(BuildContext context, WidgetRef ref) {
    final month = ref.watch(reportMonthProvider);
    final l10n = context.l10n;
    final now = _monthStart(DateTime.now());
    final canNext = month.isBefore(now);
    final monthLabel = DateFormat('MMMM yyyy', Localizations.localeOf(context).toString()).format(month);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SectionCard(
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.selectMonth,
              onPressed: () => ref.read(reportMonthProvider.notifier).state =
                  DateTime(month.year, month.month - 1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: InkWell(
                onTap: () => _pickMonth(context, ref, month),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            monthLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                      ],
                    ),
                    Text(
                      l10n.selectMonth,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.selectMonth,
              onPressed: canNext
                  ? () => ref.read(reportMonthProvider.notifier).state =
                      DateTime(month.year, month.month + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(reportMonthProvider);
    final reportAsync = ref.watch(reportProvider);
    final l10n = context.l10n;
    final monthQuery = _monthQuery(month);

    return Scaffold(
      appBar: IiasAppBar(title: l10n.reports),
      body: Column(
        children: [
          _monthPicker(context, ref),
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(message: '$e'),
              data: (report) {
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(reportProvider),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SectionCard(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 160,
                              width: 160,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: 160,
                                    width: 160,
                                    child: CircularProgressIndicator(
                                      value: report.rate,
                                      strokeWidth: 14,
                                      backgroundColor: AppColors.primaryLight,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${(report.rate * 100).toStringAsFixed(1)}%',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      Text(l10n.collectionRate,
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _amountRow(l10n.expected, report.expected),
                            _amountRow(l10n.collected, report.collected, color: AppColors.paid),
                            _amountRow(l10n.outstanding, report.outstanding, color: AppColors.unpaid),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _navTile(
                        context,
                        l10n.paidMembers,
                        '${report.paidMembers}',
                        AppColors.paid,
                        '/monthly-members?filter=paid&month=$monthQuery',
                      ),
                      _navTile(
                        context,
                        l10n.partialMembers,
                        '${report.partialMembers}',
                        AppColors.partial,
                        '/monthly-members?filter=partial&month=$monthQuery',
                      ),
                      _navTile(
                        context,
                        l10n.unpaidMembers,
                        '${report.unpaidMembers}',
                        AppColors.unpaid,
                        '/monthly-members?filter=unpaid&month=$monthQuery',
                      ),
                      _navTile(
                        context,
                        l10n.advancePaid,
                        '${report.advancePaidMembers}',
                        AppColors.advance,
                        '/monthly-members?filter=paid&month=$monthQuery',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, int amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          MoneyText(amount, color: color),
        ],
      ),
    );
  }

  Widget _navTile(
    BuildContext context,
    String title,
    String value,
    Color color,
    String route,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SectionCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => context.push(route),
        ),
      ),
    );
  }
}
