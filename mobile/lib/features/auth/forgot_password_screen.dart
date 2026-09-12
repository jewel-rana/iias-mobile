import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/back_fallback.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/auth_background.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialPhone = ''});

  final String initialPhone;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _phone;
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  bool _obscure = true;
  String? _debugCode;
  String? _emailHint;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  OutlineInputBorder get _fieldBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD5DED8)),
      );

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: _fieldBorder,
      enabledBorder: _fieldBorder,
      focusedBorder: _fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  String _cleanError(Object e) => e.toString().replaceFirst(RegExp(r'^Exception: '), '');

  Future<void> _sendCode() async {
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.requiredField)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final challenge = await ref.read(repositoryProvider).requestPasswordReset(phone);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _debugCode = challenge.debugCode;
        _emailHint = challenge.emailHint;
      });
      if (challenge.debugCode != null) {
        _code.text = challenge.debugCode!;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            challenge.emailHint != null
                ? context.l10n.codeSentTo(challenge.emailHint!)
                : context.l10n.codeSent,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanError(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    final l10n = context.l10n;
    final phone = _phone.text.trim();
    final code = _code.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterResetCode)),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordTooShort)),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordsDoNotMatch)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(repositoryProvider).resetPassword(
            phone: phone,
            code: code,
            password: password,
            passwordConfirmation: confirm,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordResetSuccess)),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanError(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: AuthBackground(
          showCenterGlow: true,
          showBottomSkyline: true,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => popOrGo(context, '/login'),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Text(
                          l10n.forgotPasswordTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _codeSent
                              ? (_emailHint != null
                                  ? l10n.codeSentTo(_emailHint!)
                                  : l10n.codeSentHint)
                              : l10n.forgotPasswordHint,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        if (_debugCode != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              l10n.debugResetCode(_debugCode!),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                    letterSpacing: 0.4,
                                  ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        TextField(
                          controller: _phone,
                          enabled: !_codeSent,
                          keyboardType: TextInputType.phone,
                          decoration: _decoration(
                            hint: '+880 01XXXXXXXXX',
                            icon: Icons.phone_android_rounded,
                          ),
                        ),
                        if (_codeSent) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: _code,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _decoration(
                              hint: l10n.resetCode,
                              icon: Icons.pin_outlined,
                            ).copyWith(counterText: ''),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _password,
                            obscureText: _obscure,
                            decoration: _decoration(
                              hint: l10n.newPassword,
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _confirm,
                            obscureText: _obscure,
                            decoration: _decoration(
                              hint: l10n.confirmPassword,
                              icon: Icons.lock_outline_rounded,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        AppButton(
                          label: _codeSent ? l10n.resetPasswordAction : l10n.sendResetCode,
                          loading: _loading,
                          onPressed: _codeSent ? _reset : _sendCode,
                        ),
                        if (_codeSent) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: _loading ? null : _sendCode,
                              child: Text(
                                l10n.resendCode,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
