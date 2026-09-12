import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/back_fallback.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../auth/login_screen.dart';
import '../auth/splash_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../events/add_campaign_screen.dart';
import '../events/donation_success_screen.dart';
import '../events/events_screen.dart';
import '../events/new_donation_screen.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_heads_screen.dart';
import '../expenses/expenses_screen.dart';
import '../join/join_screen.dart';
import '../members/add_member_screen.dart';
import '../members/member_detail_screen.dart';
import '../members/members_screen.dart';
import '../more/committee_screen.dart';
import '../more/join_requests_screen.dart';
import '../more/more_screen.dart';
import '../more/organization_settings_screen.dart';
import '../payments/collect_payment_screen.dart';
import '../payments/collection_screen.dart';
import '../payments/payment_approvals_screen.dart';
import '../payments/payment_success_screen.dart';
import '../profile/member_home_screen.dart';
import '../reports/monthly_members_screen.dart';
import '../reports/reports_screen.dart';
import '../shell/main_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRoute _overlay({
  required String path,
  required String fallback,
  required Widget Function(BuildContext, GoRouterState) builder,
}) {
  return GoRoute(
    path: path,
    parentNavigatorKey: _rootKey,
    builder: (context, state) => BackFallback(
      fallback: fallback,
      child: builder(context, state),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/join';
      if (auth == null && !loggingIn) return '/login';
      if (auth != null &&
          (state.matchedLocation == '/login' || state.matchedLocation == '/splash')) {
        return auth.role == UserRole.member ? '/member-home' : '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      _overlay(
        path: '/join',
        fallback: '/login',
        builder: (_, __) => const JoinScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/members',
              builder: (_, __) => const MembersScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      MemberDetailScreen(memberId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/collection',
              builder: (context, state) => const CollectionScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/events',
              builder: (_, __) => const EventsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/more', builder: (_, __) => const MoreScreen()),
          ]),
        ],
      ),
      _overlay(
        path: '/add-member',
        fallback: '/members',
        builder: (_, __) => const AddMemberScreen(),
      ),
      _overlay(
        path: '/add-campaign',
        fallback: '/events',
        builder: (_, __) => const AddCampaignScreen(),
      ),
      _overlay(
        path: '/collect/:memberId',
        fallback: '/collection',
        builder: (_, state) =>
            CollectPaymentScreen(memberId: state.pathParameters['memberId']!),
      ),
      _overlay(
        path: '/payment-success',
        fallback: '/dashboard',
        builder: (_, state) =>
            PaymentSuccessScreen(payment: state.extra as PaymentRecord),
      ),
      _overlay(
        path: '/new-donation',
        fallback: '/events',
        builder: (_, state) => NewDonationScreen(
          eventId: state.uri.queryParameters['eventId'],
        ),
      ),
      _overlay(
        path: '/donation-success',
        fallback: '/events',
        builder: (_, state) =>
            DonationSuccessScreen(donation: state.extra as EventDonation),
      ),
      _overlay(
        path: '/reports',
        fallback: '/more',
        builder: (_, __) => const ReportsScreen(),
      ),
      _overlay(
        path: '/expenses',
        fallback: '/more',
        builder: (_, __) => const ExpensesScreen(),
      ),
      _overlay(
        path: '/add-expense',
        fallback: '/expenses',
        builder: (_, state) {
          final kindParam = state.uri.queryParameters['kind'];
          final kind = switch (kindParam) {
            'salary' => ExpenseHeadKind.salary,
            'festival_bonus' => ExpenseHeadKind.festivalBonus,
            'operational' => ExpenseHeadKind.operational,
            'charity' => ExpenseHeadKind.charity,
            'other' => ExpenseHeadKind.other,
            _ => null,
          };
          return AddExpenseScreen(initialKind: kind);
        },
      ),
      _overlay(
        path: '/expense-heads',
        fallback: '/more',
        builder: (_, __) => const ExpenseHeadsScreen(),
      ),
      _overlay(
        path: '/join-requests',
        fallback: '/more',
        builder: (_, __) => const JoinRequestsScreen(),
      ),
      _overlay(
        path: '/payment-approvals',
        fallback: '/more',
        builder: (_, __) => const PaymentApprovalsScreen(),
      ),
      _overlay(
        path: '/organization-settings',
        fallback: '/more',
        builder: (_, __) => const OrganizationSettingsScreen(),
      ),
      _overlay(
        path: '/committee',
        fallback: '/more',
        builder: (_, __) => const CommitteeScreen(),
      ),
      _overlay(
        path: '/monthly-members',
        fallback: '/reports',
        builder: (_, state) => MonthlyMembersScreen(
          filter: state.uri.queryParameters['filter'] ?? 'paid',
        ),
      ),
      GoRoute(path: '/member-home', builder: (_, __) => const MemberHomeScreen()),
    ],
  );
});

/// Lightweight refresh bridge for GoRouter + Riverpod.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(this.ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}
