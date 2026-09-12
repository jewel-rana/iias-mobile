import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l10n = context.l10n;

    final toggle = SegmentedButton<String>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      ),
      segments: [
        ButtonSegment(value: 'en', label: Text(l10n.english)),
        ButtonSegment(
          value: 'bn',
          label: Text(l10n.bangla, style: AppFonts.bangla(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
      selected: {locale.languageCode},
      onSelectionChanged: (selected) {
        ref.read(localeProvider.notifier).setLocale(Locale(selected.first));
      },
    );

    if (compact) return toggle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.translate_rounded),
          title: Text(l10n.language),
          subtitle: Text(
            locale.languageCode == 'bn' ? l10n.bangla : l10n.english,
            style: locale.languageCode == 'bn' ? AppFonts.bangla(fontSize: 13) : null,
          ),
        ),
        toggle,
      ],
    );
  }
}

class LanguageBar extends ConsumerWidget {
  const LanguageBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.translate_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          const LanguageToggle(compact: true),
        ],
      ),
    );
  }
}
