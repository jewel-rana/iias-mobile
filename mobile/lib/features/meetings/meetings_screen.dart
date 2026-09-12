import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';

final meetingsFilterProvider = StateProvider<MeetingStatus?>((ref) => null);

final meetingsProvider = FutureProvider.autoDispose<List<Meeting>>((ref) {
  return ref.watch(repositoryProvider).getMeetings(
        status: ref.watch(meetingsFilterProvider),
      );
});

class MeetingsScreen extends ConsumerWidget {
  const MeetingsScreen({super.key});

  bool _isStaff(AppUser? user) =>
      user?.can(AppPermission.meetingsManage) == true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final filter = ref.watch(meetingsFilterProvider);
    final async = ref.watch(meetingsProvider);
    final staff = _isStaff(user);
    final dateFmt = DateFormat('EEE, dd MMM yyyy · hh:mm a');
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(title: l10n.meetings),
      floatingActionButton: staff
          ? FloatingActionButton.extended(
              heroTag: 'fab-meetings',
              onPressed: () => context.push('/open-meeting'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.campaign_outlined),
              label: Text(l10n.openMeeting),
            )
          : null,
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _Pill(
                  label: l10n.all,
                  selected: filter == null,
                  onTap: () => ref.read(meetingsFilterProvider.notifier).state = null,
                ),
                _Pill(
                  label: l10n.scheduled,
                  selected: filter == MeetingStatus.scheduled,
                  onTap: () => ref.read(meetingsFilterProvider.notifier).state =
                      MeetingStatus.scheduled,
                ),
                _Pill(
                  label: l10n.completed,
                  selected: filter == MeetingStatus.completed,
                  onTap: () => ref.read(meetingsFilterProvider.notifier).state =
                      MeetingStatus.completed,
                ),
                _Pill(
                  label: l10n.cancelled,
                  selected: filter == MeetingStatus.cancelled,
                  onTap: () => ref.read(meetingsFilterProvider.notifier).state =
                      MeetingStatus.cancelled,
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(message: '${l10n.unableToLoadMeetings}\n$e'),
              data: (meetings) {
                if (meetings.isEmpty) {
                  return EmptyState(message: l10n.noMeetings);
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(meetingsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: meetings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final meeting = meetings[index];
                      return SectionCard(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Icon(
                              Icons.groups_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            meeting.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(meeting.purpose, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(
                                dateFmt.format(meeting.startsAt.toLocal()),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          trailing: MeetingStatusChip(status: meeting.status),
                          onTap: () => context.push('/meetings/${meeting.id}'),
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
}

class MeetingStatusChip extends StatelessWidget {
  const MeetingStatusChip({super.key, required this.status});

  final MeetingStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, color) = switch (status) {
      MeetingStatus.scheduled => (l10n.scheduled, AppColors.partial),
      MeetingStatus.completed => (l10n.completed, AppColors.paid),
      MeetingStatus.cancelled => (l10n.cancelled, AppColors.unpaid),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});

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
