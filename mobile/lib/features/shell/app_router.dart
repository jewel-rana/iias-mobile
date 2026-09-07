import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/app_repository.dart';
import '../auth/splash_screen.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../members/members_screen.dart';
import '../members/member_detail_screen.dart';
import '../members/add_member_screen.dart';
import '../payments/collect_payment_screen.dart';
import '../payments/collection_screen.dart';
import '../payments/payment_approvals_screen.dart';
import '../payments/payment_success_screen.dart';
import '../events/events_screen.dart';
import '../events/new_donation_screen.dart';
import '../events/donation_success_screen.dart';
import '../events/add_campaign_screen.dart';
import '../expenses/expenses_screen.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_heads_screen.dart';
import '../reports/reports_screen.dart';
import '../reports/monthly_members_screen.dart';
import '../more/more_screen.dart';
import '../more/join_requests_screen.dart';
import '../more/organization_settings_screen.dart';
import '../more/committee_screen.dart';
import '../join/join_screen.dart';
import '../profile/member_home_screen.dart';
import '../shell/main_shell.dart';
import '../../data/models/models.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
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
      GoRoute(path: '/join', builder: (_, __) => const JoinScreen()),
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
      GoRoute(
        path: '/add-member',
        builder: (context, state) => const AddMemberScreen(),
      ),
      GoRoute(
        path: '/add-campaign',
        builder: (context, state) => const AddCampaignScreen(),
      ),
      GoRoute(
        path: '/collect/:memberId',
        builder: (context, state) =>
            CollectPaymentScreen(memberId: state.pathParameters['memberId']!),
      ),
      GoRoute(
        path: '/payment-success',
        builder: (_, state) => PaymentSuccessScreen(payment: state.extra as PaymentRecord),
      ),
      GoRoute(
        path: '/new-donation',
        builder: (_, state) => NewDonationScreen(
          eventId: state.uri.queryParameters['eventId'],
        ),
      ),
      GoRoute(
        path: '/donation-success',
        builder: (_, state) =>
            DonationSuccessScreen(donation: state.extra as EventDonation),
      ),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(path: '/expenses', builder: (_, __) => const ExpensesScreen()),
      GoRoute(
        path: '/add-expense',
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
      GoRoute(
        path: '/expense-heads',
        builder: (_, __) => const ExpenseHeadsScreen(),
      ),
      GoRoute(
        path: '/join-requests',
        builder: (_, __) => const JoinRequestsScreen(),
      ),
      GoRoute(
        path: '/payment-approvals',
        builder: (_, __) => const PaymentApprovalsScreen(),
      ),
      GoRoute(
        path: '/organization-settings',
        builder: (_, __) => const OrganizationSettingsScreen(),
      ),      GoRoute(
        path: '/committee',
        builder: (_, __) => const CommitteeScreen(),
      ),
      GoRoute(
        path: '/monthly-members',
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
