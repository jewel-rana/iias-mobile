import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';

final eventsTabProvider = StateProvider<int>((ref) => 0);

final eventsProvider = FutureProvider((ref) {
  return ref.watch(repositoryProvider).getEvents();
});

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(eventsTabProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: IiasAppBar(
        title: l10n.funds,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: l10n.recordDonation,
            onPressed: () => context.push('/new-donation'),
            icon: const Icon(Icons.volunteer_activism_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-campaign'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.addCampaign),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text(l10n.active)),
                    selected: tab == 0,
                    onSelected: (_) => ref.read(eventsTabProvider.notifier).state = 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Center(child: Text(l10n.past)),
                    selected: tab == 1,
                    onSelected: (_) => ref.read(eventsTabProvider.notifier).state = 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(message: '$e'),
              data: (events) {
                final filtered = events.where((e) {
                  if (tab == 0) return e.status == EventStatus.active;
                  return e.status != EventStatus.active;
                }).toList();
                if (filtered.isEmpty) {
                  return EmptyState(message: l10n.noFundraisingEvents);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final e = filtered[i];
                    return SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 8),
                          ProgressBar(value: e.progress),
                          const SizedBox(height: 8),
                          Text(
                            '৳ ${e.raisedAmount} of ৳ ${e.goalAmount} · ${e.donorCount} donors',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          if (e.status == EventStatus.active)
                            AppButton(
                              label: 'Donate',
                              onPressed: () => context.push('/new-donation?eventId=${e.id}'),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
