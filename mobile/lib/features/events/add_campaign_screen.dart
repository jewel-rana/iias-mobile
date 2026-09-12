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
        const SnackBar(content: Text('Campaign created')),
      );
      context.go('/events');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create campaign: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

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
                    'Fundraising campaign',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Create a new campaign to collect donations from members and non-members.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Campaign title',
                      hintText: 'e.g. Winter Relief Drive',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _goal,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Goal amount',
                      prefixText: '৳ ',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n < 1) return 'Enter a valid goal';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _description,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start date'),
                    subtitle: Text(dateFmt.format(_startsAt)),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: _pickStart,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End date (optional)'),
                    subtitle: Text(
                      _endsAt == null ? 'Not set' : dateFmt.format(_endsAt!),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_endsAt != null)
                          IconButton(
                            tooltip: 'Clear',
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
              label: 'Create Campaign',
              loading: _loading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
