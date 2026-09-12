import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';

class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _referral = TextEditingController();
  bool _submitted = false;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _referral.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(repositoryProvider).submitJoinRequest(
            fullName: _name.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim(),
            referralCode: _referral.text.trim(),
          );
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotSubmit(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: IiasAppBar(title: l10n.joinOrganization),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _submitted
            ? Column(
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.mark_email_read_rounded,
                      size: 72, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    l10n.applicationSubmitted,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.applicationSubmittedHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  AppButton(label: l10n.backToLogin, onPressed: () => context.go('/login')),
                ],
              )
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text(
                      l10n.joinFormHint,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(labelText: l10n.fullName),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: l10n.phone),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return l10n.requiredField;
                        if (!value.contains('@') || !value.contains('.')) {
                          return l10n.enterValidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _referral,
                      decoration: InputDecoration(
                        labelText: l10n.referralCodeOptional,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: l10n.submitApplication,
                      loading: _loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
