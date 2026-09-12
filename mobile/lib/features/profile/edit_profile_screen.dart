import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/back_fallback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';
import '../members/members_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _currentPassword = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hydrated = false;
  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _currentPassword.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _hydrate() {
    if (_hydrated) return;
    final user = ref.read(authStateProvider);
    if (user == null) return;
    _name.text = user.name;
    _phone.text = user.phone;
    _email.text = user.email ?? '';
    _hydrated = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final password = _password.text;
    setState(() => _saving = true);
    try {
      await ref.read(authStateProvider.notifier).updateProfile(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim(),
            currentPassword:
                password.isEmpty ? null : _currentPassword.text,
            password: password.isEmpty ? null : password,
            passwordConfirmation: password.isEmpty ? null : _confirm.text,
          );
      ref.invalidate(membersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileSaved)),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.couldNotSaveProfile(
              e.toString().replaceFirst(RegExp(r'^Exception: '), ''),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _hydrate();
    final l10n = context.l10n;
    final fallback = ref.watch(authStateProvider)?.isStaff == true
        ? '/more'
        : '/member-home';

    return BackFallback(
      fallback: fallback,
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: IiasAppBar(
        title: l10n.editProfile,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => popOrGo(context, fallback),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.fullName),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.nameRequired : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: l10n.phoneNumber),
                    validator: (v) =>
                        (v == null || v.trim().length < 10) ? l10n.enterValidPhone : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: l10n.email),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return l10n.requiredField;
                      if (!value.contains('@') || !value.contains('.')) {
                        return l10n.enterValidEmail;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.changePasswordOptional,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.leavePasswordBlank,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _currentPassword,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: l10n.currentPassword,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (_password.text.isEmpty) return null;
                      if (v == null || v.isEmpty) return l10n.requiredField;
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(labelText: l10n.newPassword),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      if (v.length < 6) return l10n.passwordTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscure,
                    decoration: InputDecoration(labelText: l10n.confirmPassword),
                    validator: (v) {
                      if (_password.text.isEmpty) return null;
                      if (v != _password.text) return l10n.passwordsDoNotMatch;
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: l10n.saveChanges,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    ),
    );
  }
}
