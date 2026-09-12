import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/app_repository.dart';

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
        SnackBar(content: Text('Could not submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IiasAppBar(title: 'Join Organization'),
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
                    'Application submitted',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'An admin will review your join request in the app. You will be notified after approval.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  AppButton(label: 'Back to Login', onPressed: () => context.go('/login')),
                ],
              )
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'Submit a membership application. Admin approval happens in the mobile app — no web panel.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _referral,
                      decoration: const InputDecoration(
                        labelText: 'Referral code (optional)',
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Submit Application',
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
