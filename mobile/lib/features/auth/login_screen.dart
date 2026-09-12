import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/auth_background.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/language_toggle.dart';
import '../../data/repositories/app_repository.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController(text: '01712345678');
  final _password = TextEditingController(text: 'admin');
  bool _remember = true;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final ok = await ref.read(authStateProvider.notifier).login(
            _phone.text.trim(),
            _password.text,
          );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.loginUnable)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD5DED8)),
    );

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
          child: Column(
            children: [
              const _LoginTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.welcomeBack,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.loginSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '+880 01XXXXXXXXX',
                          prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primary),
                          filled: true,
                          fillColor: Colors.white,
                          border: fieldBorder,
                          enabledBorder: fieldBorder,
                          focusedBorder: fieldBorder.copyWith(
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: l10n.password,
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: fieldBorder,
                          enabledBorder: fieldBorder,
                          focusedBorder: fieldBorder.copyWith(
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _remember,
                              onChanged: (v) => setState(() => _remember = v ?? false),
                              activeColor: AppColors.primaryDark,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.rememberMe,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              l10n.forgotPassword,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppButton(label: l10n.login, loading: _loading, onPressed: _submit),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.dontHaveAccount,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/join'),
                            child: Text(
                              l10n.joinNow,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const LanguageBar(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginTopBar extends StatelessWidget {
  const _LoginTopBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Center(
          child: Image.asset(
            BrandMark.assetPath,
            height: 120,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
