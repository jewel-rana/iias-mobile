import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/auth_background.dart';
import '../../core/widgets/common_widgets.dart';
import '../../l10n/app_localizations.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  late Locale _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = AppLocalizations.defaultLocale;
  }

  Future<void> _select(Locale locale) async {
    setState(() => _selected = locale);
    ref.read(localeProvider.notifier).preview(locale);
  }

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(localeProvider.notifier).setLocale(_selected);
      ref.read(localeChosenProvider.notifier).state = true;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: AuthBackground(
        showArch: true,
        showCornerPatterns: true,
        showBottomSkyline: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              children: [
                const SizedBox(height: 8),
                const BrandMark(height: 140),
                const Spacer(),
                Text(
                  'Choose your language',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ভাষা বেছে নিন',
                  textAlign: TextAlign.center,
                  style: AppFonts.bangla(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.chooseLanguageHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                _LanguageCard(
                  selected: _selected.languageCode == 'en',
                  title: l10n.english,
                  subtitle: l10n.defaultLanguage,
                  onTap: () => _select(const Locale('en')),
                ),
                const SizedBox(height: 12),
                _LanguageCard(
                  selected: _selected.languageCode == 'bn',
                  title: l10n.bangla,
                  subtitle: 'Bangla',
                  banglaTitle: true,
                  onTap: () => _select(const Locale('bn')),
                ),
                const Spacer(),
                AppButton(
                  label: l10n.continueLabel,
                  loading: _saving,
                  onPressed: _continue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.banglaTitle = false,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool banglaTitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: banglaTitle
                          ? AppFonts.bangla(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            )
                          : const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                    ),
                    Text(
                      subtitle,
                      style: banglaTitle
                          ? AppFonts.bangla(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            )
                          : const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
