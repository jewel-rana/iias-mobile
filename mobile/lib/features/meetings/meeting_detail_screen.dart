import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/navigation/back_fallback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';
import '../members/members_screen.dart';
import 'meetings_screen.dart';

final meetingDetailProvider =
    FutureProvider.autoDispose.family<Meeting, String>((ref, id) {
  return ref.watch(repositoryProvider).getMeeting(id);
});

class MeetingDetailScreen extends ConsumerStatefulWidget {
  const MeetingDetailScreen({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends ConsumerState<MeetingDetailScreen> {
  final _summary = TextEditingController();
  final Set<String> _present = {};
  bool _saving = false;
  bool _hydrated = false;

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  bool _isStaff(AppUser? user) =>
      user?.role == UserRole.admin || user?.role == UserRole.collector;

  Future<void> _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.copiedLabel(label))),
    );
  }

  Future<void> _share(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _close(MeetingStatus status) async {
    if (status == MeetingStatus.completed && _summary.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.addSummaryBeforeComplete)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).updateMeeting(
            id: widget.meetingId,
            status: status,
            summary: _summary.text.trim(),
            presentMemberIds: _present.toList(),
          );
      ref.invalidate(meetingDetailProvider(widget.meetingId));
      ref.invalidate(meetingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == MeetingStatus.completed
                ? context.l10n.meetingMarkedComplete
                : context.l10n.meetingCancelled,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotUpdateMeeting(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final async = ref.watch(meetingDetailProvider(widget.meetingId));
    final membersAsync = ref.watch(membersProvider);
    final staff = _isStaff(user);
    final dateFmt = DateFormat('EEEE, dd MMM yyyy · hh:mm a');
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(
        title: l10n.meeting,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => popOrGo(context, '/meetings'),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: '${l10n.unableToLoadMeeting}\n$e'),
        data: (meeting) {
          if (!_hydrated) {
            _hydrated = true;
            _summary.text = meeting.summary ?? '';
            _present
              ..clear()
              ..addAll(meeting.presentMemberIds);
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            meeting.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        MeetingStatusChip(status: meeting.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(meeting.purpose),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(dateFmt.format(meeting.startsAt.toLocal()))),
                      ],
                    ),
                    if ((meeting.location ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(meeting.location!)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _AnnouncementCard(
                title: l10n.englishAnnouncement,
                body: meeting.announcementEn,
                onCopy: () => _copy(meeting.announcementEn, l10n.englishAnnouncement),
                onShare: () => _share(meeting.announcementEn),
              ),
              const SizedBox(height: 10),
              _AnnouncementCard(
                title: l10n.banglaAnnouncement,
                body: meeting.announcementBn,
                bangla: true,
                onCopy: () => _copy(meeting.announcementBn, l10n.banglaAnnouncement),
                onShare: () => _share(meeting.announcementBn),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: l10n.copyBoth,
                outlined: true,
                onPressed: () => _copy(
                  '${meeting.announcementEn}\n\n--------------------\n\n${meeting.announcementBn}',
                  l10n.announcement,
                ),
              ),
              if (!meeting.isScheduled) ...[
                const SizedBox(height: 18),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.status == MeetingStatus.completed
                            ? l10n.meetingSummary
                            : l10n.cancellationNote,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (meeting.summary ?? '').isEmpty ? '—' : meeting.summary!,
                      ),
                      if (meeting.presentMembers.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          l10n.membersPresent,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        ...meeting.presentMembers.map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• ${m.name}${m.memberCode != null ? ' · ${m.memberCode}' : ''}'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (staff && meeting.isScheduled) ...[
                const SizedBox(height: 18),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.afterTheMeeting,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.afterMeetingHint,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _summary,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: l10n.summary,
                          hintText: l10n.summaryHint,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.membersPresent,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      membersAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Text('$e'),
                        data: (members) {
                          if (members.isEmpty) {
                            return Text(l10n.noMembersToMark);
                          }
                          return Column(
                            children: members
                                .map(
                                  (m) => CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    value: _present.contains(m.id),
                                    title: Text(m.name),
                                    subtitle: Text(m.memberCode),
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _present.add(m.id);
                                        } else {
                                          _present.remove(m.id);
                                        }
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: l10n.markComplete,
                  loading: _saving,
                  onPressed: () => _close(MeetingStatus.completed),
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: l10n.cancelMeeting,
                  outlined: true,
                  loading: _saving,
                  onPressed: () => _close(MeetingStatus.cancelled),
                ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.title,
    required this.body,
    required this.onCopy,
    required this.onShare,
    this.bangla = false,
  });

  final String title;
  final String body;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final bool bangla;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: bangla
                ? AppFonts.bangla(fontSize: 16, fontWeight: FontWeight.w800)
                : const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          SelectableText(
            body,
            style: bangla
                ? AppFonts.bangla(fontSize: 15)
                : const TextStyle(height: 1.45),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(context.l10n.copy),
              ),
              TextButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text(context.l10n.share),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
