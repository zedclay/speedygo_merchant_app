import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_merchant_app/core/navigation/app_routes.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/presentation/access_screens.dart';
import 'package:speedygo_merchant_app/features/access/presentation/registration_screens.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/auth/presentation/onboarding_screen.dart';
import 'package:speedygo_merchant_app/features/auth/presentation/phone_otp_screens.dart';
import 'package:speedygo_merchant_app/features/auth/presentation/splash_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/category_editor_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_editor_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/catalog_sub_screens.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/option_groups_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_detail_screen.dart';
import 'package:speedygo_merchant_app/features/catalog/presentation/product_duplicate_screen.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/order_detail_screen.dart';
import 'package:speedygo_merchant_app/features/support/presentation/order_support_screen.dart';
import 'package:speedygo_merchant_app/features/orders/presentation/orders_screen.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/reports_screen.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/daily_summary_screen.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/top_products_screen.dart';
import 'package:speedygo_merchant_app/features/shell/home_dashboard_screen.dart';
import 'package:speedygo_merchant_app/features/shell/merchant_shell.dart';
import 'package:speedygo_merchant_app/features/shell/language_settings_screen.dart';
import 'package:speedygo_merchant_app/features/shell/profile_settings_screen.dart';
import 'package:speedygo_merchant_app/features/shell/logout_screen.dart';
import 'package:speedygo_merchant_app/features/support/presentation/support_center_screen.dart';
import 'package:speedygo_merchant_app/features/support/presentation/support_ticket_screen.dart';
import 'package:speedygo_merchant_app/features/shell/store_profile_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/notifications_screen.dart';
import 'package:speedygo_merchant_app/features/notifications/presentation/notification_settings_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/opening_hours_exceptions_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/opening_hours_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_address_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_availability_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_cover_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_category_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/store_general_screen.dart';
import 'package:speedygo_merchant_app/features/store/presentation/temporary_closure_screen.dart';
import 'package:speedygo_merchant_app/features/team/presentation/my_invitations_screen.dart';
import 'package:speedygo_merchant_app/features/team/presentation/team_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

String? _redirect(SessionState session, AccessState access, String path) {
  final inApp = path.startsWith('/app/');
  switch (session.phase) {
    case SessionPhase.boot:
      return path == AppRoutes.splash ? null : AppRoutes.splash;
    case SessionPhase.restoring:
      return path == AppRoutes.restore ? null : AppRoutes.restore;
    case SessionPhase.restoreRetryable:
      return path == AppRoutes.restore ? null : AppRoutes.restore;
    case SessionPhase.signedOut:
      return _signedOutRedirect(session, path);
    case SessionPhase.awaitingOtp:
      if (path == AppRoutes.otp || path == AppRoutes.phone) return null;
      return AppRoutes.otp;
    case SessionPhase.resolvingAccess:
      return switch (access.destination) {
        AccessDestination.loading => AppRoutes.accessLoading,
        AccessDestination.error => AppRoutes.accessError,
        AccessDestination.noMembership =>
          path == AppRoutes.accessTeamInvitations
              ? null
              : AppRoutes.registration,
        AccessDestination.registration =>
          path == AppRoutes.accessTeamInvitations
              ? null
              : AppRoutes.registration,
        AccessDestination.verificationPending => AppRoutes.verificationPending,
        AccessDestination.verificationRejected =>
          AppRoutes.verificationRejected,
        AccessDestination.verificationSuspended =>
          AppRoutes.verificationSuspended,
        AccessDestination.verificationApproved =>
          AppRoutes.verificationApproved,
        AccessDestination.needBranch => AppRoutes.needBranch,
        AccessDestination.selectBranch => AppRoutes.selectBranch,
        AccessDestination.home => AppRoutes.home,
        AccessDestination.permissionDenied => AppRoutes.permissionDenied,
      };
    case SessionPhase.ready:
      if (!inApp) return AppRoutes.home;
      return null;
  }
}

String? _signedOutRedirect(SessionState session, String path) {
  if (path == AppRoutes.otp && session.pendingPhone != null) {
    return null;
  }
  if (path == AppRoutes.phone && session.onboardingSeen) {
    return null;
  }
  if (path == AppRoutes.language && !session.languageSeen) {
    return null;
  }
  if (path == AppRoutes.onboarding &&
      session.languageSeen &&
      !session.onboardingSeen) {
    return null;
  }
  return _signedOutTarget(session);
}

String _signedOutTarget(SessionState session) {
  if (session.pendingPhone != null) {
    return AppRoutes.otp;
  }
  if (!session.languageSeen) {
    return AppRoutes.language;
  }
  if (!session.onboardingSeen) {
    return AppRoutes.onboarding;
  }
  return AppRoutes.phone;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _GoRouterRefresh(ref);
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final access = ref.read(accessControllerProvider);
      return _redirect(session, access, state.uri.path);
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.language,
        builder: (_, _) => const LanguageScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: AppRoutes.phone, builder: (_, _) => const PhoneScreen()),
      GoRoute(path: AppRoutes.otp, builder: (_, _) => const OtpScreen()),
      GoRoute(
        path: AppRoutes.restore,
        builder: (_, _) => const RestoreScreen(),
      ),
      GoRoute(
        path: AppRoutes.noMembership,
        builder: (_, _) => const RegistrationHostScreen(),
      ),
      GoRoute(
        path: AppRoutes.registration,
        builder: (_, _) => const RegistrationHostScreen(),
      ),
      GoRoute(
        path: AppRoutes.accessTeamInvitations,
        builder: (_, _) => const MyInvitationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.verificationPending,
        builder: (_, _) => const VerificationScreen(
          kind: AccessDestination.verificationPending,
        ),
      ),
      GoRoute(
        path: AppRoutes.verificationRejected,
        builder: (_, _) => const VerificationScreen(
          kind: AccessDestination.verificationRejected,
        ),
      ),
      GoRoute(
        path: AppRoutes.verificationSuspended,
        builder: (_, _) => const VerificationScreen(
          kind: AccessDestination.verificationSuspended,
        ),
      ),
      GoRoute(
        path: AppRoutes.verificationApproved,
        builder: (_, _) => const VerificationApprovedScreen(),
      ),
      GoRoute(
        path: AppRoutes.needBranch,
        builder: (_, _) => const NeedBranchScreen(),
      ),
      GoRoute(
        path: AppRoutes.selectBranch,
        builder: (_, _) => const SelectBranchScreen(),
      ),
      GoRoute(
        path: AppRoutes.permissionDenied,
        builder: (_, _) => const PermissionDeniedScreen(),
      ),
      GoRoute(
        path: AppRoutes.accessLoading,
        builder: (_, _) => const AccessLoadingScreen(),
      ),
      GoRoute(
        path: AppRoutes.accessError,
        builder: (_, _) => const AccessErrorScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MerchantShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: AppRoutes.orders,
            builder: (_, _) => const OrdersScreen(),
          ),
          GoRoute(
            path: AppRoutes.catalog,
            builder: (_, _) => const CatalogScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (_, _) => const ReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, _) => const StoreProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.languageSettings,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const LanguageSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.logout,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const LogoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.support,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SupportCenterScreen(),
      ),
      GoRoute(
        path: AppRoutes.team,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TeamScreen(),
      ),
      GoRoute(
        path: AppRoutes.teamInvitations,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const MyInvitationsScreen(),
      ),
      GoRoute(
        path: '/app/profile/support/:ticketId',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            SupportTicketScreen(ticketId: state.pathParameters['ticketId']!),
      ),
      GoRoute(
        path: AppRoutes.reportsTopProducts,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const TopProductsScreen(),
      ),
      GoRoute(
        path: AppRoutes.reportsDailySummary,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const DailySummaryScreen(),
      ),
      GoRoute(
        path: AppRoutes.openingHours,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const OpeningHoursScreen(),
      ),
      GoRoute(
        path: AppRoutes.openingHoursExceptions,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const OpeningHoursExceptionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.storeAvailability,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const StoreAvailabilityScreen(),
      ),
      GoRoute(
        path: AppRoutes.temporaryClosure,
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final extra = state.extra;
          int? preset;
          if (extra is Map && extra['presetMinutes'] is int) {
            preset = extra['presetMinutes'] as int;
          }
          return TemporaryClosureScreen(presetMinutes: preset);
        },
      ),
      GoRoute(
        path: AppRoutes.storeCover,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const StoreCoverScreen(),
      ),
      GoRoute(
        path: AppRoutes.storeAddress,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const StoreAddressScreen(),
      ),
      GoRoute(
        path: AppRoutes.storeGeneral,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const StoreGeneralScreen(),
      ),
      GoRoute(
        path: AppRoutes.storeCategory,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const StoreCategoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.catalogProductNew,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ProductEditorScreen(),
      ),
      GoRoute(
        path: AppRoutes.catalogFilters,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ProductFiltersScreen(),
      ),
      GoRoute(
        path: AppRoutes.catalogReorder,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ReorderCategoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.catalogBulkAvailability,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const BulkAvailabilityScreen(),
      ),
      GoRoute(
        path: '/app/catalog/category/:categoryId',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => CategoryDetailScreen(
          categoryId: state.pathParameters['categoryId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/catalog/products/:productId/availability',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => ProductAvailabilityScreen(
          productId: state.pathParameters['productId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/catalog/products/:productId/delete',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => ProductDeleteScreen(
          productId: state.pathParameters['productId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/catalog/products/:productId/variants',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => OptionGroupsScreen(
          productId: state.pathParameters['productId'] ?? '',
          required: true,
        ),
      ),
      GoRoute(
        path: '/app/catalog/products/:productId/extras',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => OptionGroupsScreen(
          productId: state.pathParameters['productId'] ?? '',
          required: false,
        ),
      ),
      GoRoute(
        path: '/app/catalog/products/:productId/details',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['productId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/catalog/products/:productId/duplicate',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => ProductDuplicateScreen(
          productId: state.pathParameters['productId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/app/catalog/products/:productId',
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final id = state.pathParameters['productId'] ?? '';
          return ProductEditorScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/app/catalog/categories/:categoryId',
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final id = state.pathParameters['categoryId'] ?? '';
          if (id.isEmpty || id == 'new') {
            return const CategoryEditorScreen();
          }
          return CategoryEditorScreen(categoryId: id);
        },
      ),
      GoRoute(
        path: '/app/orders/:orderId',
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderDetailScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/app/orders/:orderId/support',
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderSupportScreen(orderId: orderId);
        },
      ),
    ],
  );
});

class _GoRouterRefresh extends ChangeNotifier {
  _GoRouterRefresh(this._ref) {
    _ref.listen(sessionControllerProvider, (_, _) => notifyListeners());
    _ref.listen(accessControllerProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}
