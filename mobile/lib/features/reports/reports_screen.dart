import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/app_repository.dart';

final reportProvider = FutureProvider((ref) {
  return ref.watch(repositoryProvider).getReport();
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: '$e'),
        data: (report) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(reportProvider),
            child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(report.monthLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                              const Text('Collection Rate',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _amountRow('Expected', report.expected),
                    _amountRow('Collected', report.collected, color: AppColors.paid),
                    _amountRow('Outstanding', report.outstanding, color: AppColors.unpaid),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _navTile(
                context,
                'Paid Members',
                '${report.paidMembers}',
                AppColors.paid,
                '/monthly-members?filter=paid',
              ),
              _navTile(
                context,
                'Partial Members',
                '${report.partialMembers}',
                AppColors.partial,
                '/monthly-members?filter=partial',
              ),
              _navTile(
                context,
                'Unpaid Members',
                '${report.unpaidMembers}',
                AppColors.unpaid,
                '/monthly-members?filter=unpaid',
              ),
              _navTile(
                context,
                'Advance Paid',
                '${report.advancePaidMembers}',
                AppColors.advance,
                '/monthly-members?filter=paid',
              ),
            ],
          ),
          );
        },
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
