import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/navigation/back_fallback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_screen.dart';
import 'events_screen.dart';

class AddCampaignScreen extends ConsumerStatefulWidget {
  const AddCampaignScreen({super.key});

  @override
  ConsumerState<AddCampaignScreen> createState() => _AddCampaignScreenState();
}

class _AddCampaignScreenState extends ConsumerState<AddCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _goal = TextEditingController(text: '50000');
  final _description = TextEditingController();
  DateTime _startsAt = DateTime.now();
  DateTime? _endsAt;
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _goal.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _startsAt = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endsAt ?? _startsAt.add(const Duration(days: 60)),
      firstDate: _startsAt,
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (picked != null) setState(() => _endsAt = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(repositoryProvider).createFundraisingEvent(
            title: _title.text.trim(),
            goalAmount: int.parse(_goal.text.trim()),
            description: _description.text.trim(),
            startsAt: _startsAt,
            endsAt: _endsAt,
          );
      ref.invalidate(eventsProvider);
      ref.invalidate(activeEventsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.campaignCreated)),
      );
      context.go('/events');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotCreateCampaign(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFmt = DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(
        title: context.l10n.addCampaign,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => popOrGo(context, '/events'),
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
                    l10n.fundraisingCampaign,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.fundraisingCampaignHint,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _title,
                    decoration: InputDecoration(
                      labelText: l10n.campaignTitle,
                      hintText: l10n.campaignTitleHint,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _goal,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.goalAmount,
                      prefixText: '৳ ',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n < 1) return l10n.enterValidGoal;
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _description,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.descriptionOptional,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.startDate),
                    subtitle: Text(dateFmt.format(_startsAt)),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: _pickStart,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.endDateOptional),
                    subtitle: Text(
                      _endsAt == null ? l10n.notSet : dateFmt.format(_endsAt!),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_endsAt != null)
                          IconButton(
                            tooltip: l10n.clear,
                            onPressed: () => setState(() => _endsAt = null),
                            icon: const Icon(Icons.clear),
                          ),
                        const Icon(Icons.event_rounded),
                      ],
                    ),
                    onTap: _pickEnd,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: l10n.createCampaign,
              loading: _loading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
