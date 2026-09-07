import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/app_repository.dart';
import 'features/shell/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: UmmahConnectApp()));
}

class UmmahConnectApp extends ConsumerWidget {
  const UmmahConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authReady = ref.watch(authReadyProvider);

    return authReady.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(child: Text('Startup error: $e')),
        ),
      ),
      data: (_) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          title: 'IIAS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: router,
        );
      },
    );
  }
}
