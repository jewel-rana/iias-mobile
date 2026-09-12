import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/back_fallback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';

final orgSettingsProvider = FutureProvider((ref) {
  return ref.watch(repositoryProvider).getOrganizationSettings();
});

class OrganizationSettingsScreen extends ConsumerStatefulWidget {
  const OrganizationSettingsScreen({super.key});

  @override
  ConsumerState<OrganizationSettingsScreen> createState() =>
      _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState
    extends ConsumerState<OrganizationSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _tagline = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _amount = TextEditingController();
  final _currency = TextEditingController();
  bool _referralEnabled = true;
  bool _publicJoinEnabled = true;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _phone.dispose();
    _address.dispose();
    _amount.dispose();
    _currency.dispose();
    super.dispose();
  }

  void _hydrate(OrganizationSettings s) {
    _name.text = s.organizationName;
    _tagline.text = s.tagline;
    _phone.text = s.contactPhone;
    _address.text = s.address;
    _amount.text = '${s.defaultMonthlyAmount}';
    _currency.text = s.currencySymbol;
    _referralEnabled = s.referralEnabled;
    _publicJoinEnabled = s.publicJoinEnabled;
    _loaded = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = await ref.read(repositoryProvider).updateOrganizationSettings(
            OrganizationSettings(
              organizationName: _name.text.trim(),
              tagline: _tagline.text.trim(),
              contactPhone: _phone.text.trim(),
              address: _address.text.trim(),
              defaultMonthlyAmount: int.parse(_amount.text.trim()),
              currencySymbol: _currency.text.trim(),
              referralEnabled: _referralEnabled,
              publicJoinEnabled: _publicJoinEnabled,
            ),
          );
      ref.invalidate(orgSettingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.settingsSaved(updated.organizationName))),
      );
      popOrGo(context, '/more');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotSave(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orgSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(title: context.l10n.organizationSettings),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (settings) {
          if (!_loaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _loaded) return;
              setState(() => _hydrate(settings));
            });
            return const Center(child: CircularProgressIndicator());
          }
          final l10n = context.l10n;
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
                        l10n.organizationProfile,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.organizationProfileHint,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _name,
                        decoration: InputDecoration(
                          labelText: l10n.organizationName,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tagline,
                        decoration: InputDecoration(labelText: l10n.tagline),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n.contactPhone,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        maxLines: 2,
                        decoration: InputDecoration(labelText: l10n.address),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.collectionDefaults,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amount,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.defaultMonthlyAmount,
                          prefixText: '৳ ',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          if (n == null || n < 1) return l10n.enterValidAmount;
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _currency,
                        decoration: InputDecoration(
                          labelText: l10n.currencySymbol,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.enableReferrals),
                        subtitle: Text(l10n.enableReferralsHint),
                        value: _referralEnabled,
                        onChanged: (v) => setState(() => _referralEnabled = v),
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.publicJoin),
                        subtitle: Text(l10n.publicJoinHint),
                        value: _publicJoinEnabled,
                        onChanged: (v) =>
                            setState(() => _publicJoinEnabled = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: l10n.saveSettings,
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
