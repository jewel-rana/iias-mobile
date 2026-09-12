import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Keeps Android/iOS back on a screen instead of exiting the app.
///
/// If the route stack can pop, it pops. Otherwise it goes to [fallback].
class BackFallback extends StatelessWidget {
  const BackFallback({
    super.key,
    required this.fallback,
    required this.child,
  });

  final String fallback;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallback);
        }
      },
      child: child,
    );
  }
}

void popOrGo(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
