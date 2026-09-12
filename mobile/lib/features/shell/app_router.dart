import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/locale_controller.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/navigation/back_fallback.dart';
import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../auth/forgot_password_screen.dart';
import '../auth/language_screen.dart';
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
import '../meetings/meeting_detail_screen.dart';
import '../meetings/meetings_screen.dart';
import '../meetings/open_meeting_screen.dart';
import '../members/add_member_screen.dart';
import '../members/member_detail_screen.dart';
import '../members/member_donations_screen.dart';
import '../members/member_payments_screen.dart';
import '../members/members_screen.dart';
import '../more/committee_screen.dart';
import '../more/join_requests_screen.dart';
import '../more/more_screen.dart';
import '../more/organization_settings_screen.dart';
import '../more/roles_screen.dart';
import '../notifications/notifications_screen.dart';
import '../payments/collect_payment_screen.dart';
import '../payments/collection_screen.dart';
import '../payments/payment_approvals_screen.dart';
import '../payments/payment_detail_screen.dart';
import '../payments/payment_success_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/member_home_screen.dart';
import '../reports/monthly_members_screen.dart';
import '../reports/reports_screen.dart';
import '../shell/main_shell.dart';

GoRoute _overlay({
  required String path,
  required String fallback,
  required Widget Function(BuildContext, GoRouterState) builder,
}) {
  return GoRoute(
    path: path,
    parentNavigatorKey: appNavigatorKey,
    builder: (context, state) => BackFallback(
      fallback: fallback,
      child: builder(context, state),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final localeChosen = ref.read(localeChosenProvider);
      final choosingLanguage = location == '/choose-language';

      if (!localeChosen) {
        return choosingLanguage ? null : '/choose-language';
      }
      if (choosingLanguage) return '/splash';

      final auth = ref.read(authStateProvider);
      const public = {'/login', '/splash', '/join', '/forgot-password'};
      if (auth == null && !public.contains(location)) return '/login';
      if (auth != null && (location == '/login' || location == '/splash')) {
        return auth.isStaff ? '/dashboard' : '/member-home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/choose-language', builder: (_, __) => const LanguageScreen()),
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      _overlay(
        path: '/forgot-password',
        fallback: '/login',
        builder: (_, state) => ForgotPasswordScreen(
          initialPhone: state.uri.queryParameters['phone'] ?? '',
        ),
      ),
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
                  routes: [
                    GoRoute(
                      path: 'payments',
                      builder: (_, state) => MemberPaymentsScreen(
                        memberId: state.pathParameters['id']!,
                      ),
                    ),
                    GoRoute(
                      path: 'donations',
                      builder: (_, state) => MemberDonationsScreen(
                        memberId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
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
        path: '/payment-details/:id',
        fallback: '/reports',
        builder: (_, state) => PaymentDetailScreen(
          paymentId: state.pathParameters['id']!,
          payment: state.extra is PaymentRecord ? state.extra as PaymentRecord : null,
        ),
      ),
      _overlay(
        path: '/new-donation',
        fallback: '/events',
        builder: (_, state) => NewDonationScreen(
          eventId: state.uri.queryParameters['eventId'],
          memberId: state.uri.queryParameters['memberId'],
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
        path: '/notifications',
        fallback: '/dashboard',
        builder: (_, __) => const NotificationsScreen(),
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
        path: '/roles',
        fallback: '/more',
        builder: (_, __) => const RolesScreen(),
      ),
      _overlay(
        path: '/committee',
        fallback: '/more',
        builder: (_, __) => const CommitteeScreen(),
      ),
      _overlay(
        path: '/meetings',
        fallback: '/more',
        builder: (_, __) => const MeetingsScreen(),
      ),
      _overlay(
        path: '/open-meeting',
        fallback: '/meetings',
        builder: (_, __) => const OpenMeetingScreen(),
      ),
      _overlay(
        path: '/meetings/:id',
        fallback: '/meetings',
        builder: (_, state) =>
            MeetingDetailScreen(meetingId: state.pathParameters['id']!),
      ),
      _overlay(
        path: '/monthly-members',
        fallback: '/reports',
        builder: (_, state) => MonthlyMembersScreen(
          filter: state.uri.queryParameters['filter'] ?? 'paid',
          month: state.uri.queryParameters['month'],
        ),
      ),
      GoRoute(path: '/member-home', builder: (_, __) => const MemberHomeScreen()),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: appNavigatorKey,
        builder: (_, __) => const EditProfileScreen(),
      ),
    ],
  );
});

/// Lightweight refresh bridge for GoRouter + Riverpod.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(this.ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(localeChosenProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}
