import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/navigation/back_fallback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';
import 'meetings_screen.dart';

class OpenMeetingScreen extends ConsumerStatefulWidget {
  const OpenMeetingScreen({super.key});

  @override
  ConsumerState<OpenMeetingScreen> createState() => _OpenMeetingScreenState();
}

class _OpenMeetingScreenState extends ConsumerState<OpenMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController(text: 'Organization Meeting');
  final _purpose = TextEditingController();
  final _location = TextEditingController();
  late DateTime _startsAt;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _startsAt = _defaultSlot();
    _loadAddress();
  }

  DateTime _defaultSlot() {
    final now = DateTime.now();
    var slot = DateTime(now.year, now.month, now.day, 19);
    if (!slot.isAfter(now)) {
      slot = slot.add(const Duration(days: 1));
    }
    return slot;
  }

  Future<void> _loadAddress() async {
    try {
      final settings = await ref.read(repositoryProvider).getOrganizationSettings();
      if (!mounted || _location.text.isNotEmpty) return;
      setState(() => _location.text = settings.address);
    } catch (_) {}
  }

  @override
  void dispose() {
    _title.dispose();
    _purpose.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final meeting = await ref.read(repositoryProvider).createMeeting(
            title: _title.text.trim(),
            purpose: _purpose.text.trim(),
            startsAt: _startsAt,
            location: _location.text.trim().isEmpty ? null : _location.text.trim(),
          );
      ref.invalidate(meetingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.meetingOpened)),
      );
      context.push('/meetings/${meeting.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenMeeting(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEEE, dd MMM yyyy · hh:mm a');
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(
        title: l10n.openMeeting,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => popOrGo(context, '/meetings'),
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
                    l10n.callAMeeting,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.openMeetingHint,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _title,
                    decoration: InputDecoration(labelText: l10n.title),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _purpose,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.purpose,
                      hintText: l10n.purposeHint,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.enterPurpose : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded),
                    title: Text(l10n.dateTime),
                    subtitle: Text(dateFmt.format(_startsAt)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: _pickDateTime,
                  ),
                  TextFormField(
                    controller: _location,
                    decoration: InputDecoration(
                      labelText: l10n.venue,
                      hintText: l10n.venueHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: l10n.openMeetingNotify,
              loading: _loading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
