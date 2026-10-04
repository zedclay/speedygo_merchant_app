import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';

/// Top products shown on the overview; the full list lives on its own screen.
const reportsOverviewTopProductsLimit = 3;
const reportsTopProductsScreenLimit = 20;

/// Report failures are surfaced with an explicit retry action instead of
/// silent background retries (a 400 period error would never recover).
Duration? _noAutomaticRetry(int _, Object _) => null;

/// Period shared by the overview and the top products screen.
class ReportPeriodController extends Notifier<ReportPeriodSelection> {
  @override
  ReportPeriodSelection build() {
    ref.watch(accessControllerProvider.select((a) => a.membership?.merchantId));
    return ReportPeriodSelection.today;
  }

  void select(ReportPeriodSelection selection) => state = selection;
}

final reportPeriodProvider =
    NotifierProvider<ReportPeriodController, ReportPeriodSelection>(
      ReportPeriodController.new,
    );

class SalesReportState {
  const SalesReportState({required this.summary, required this.topProducts});

  final MerchantSalesSummary summary;
  final MerchantTopProducts topProducts;
}

/// Sales summary + top products preview for the selected Branch and period.
/// Returns `null` when there is no active Merchant membership.
class SalesReportController extends AsyncNotifier<SalesReportState?> {
  @override
  Future<SalesReportState?> build() async {
    final scope = ref.watch(merchantDataScopeProvider);
    final branchId = ref.watch(
      accessControllerProvider.select((a) => a.selectedBranch?.id),
    );
    final period = ref.watch(reportPeriodProvider);
    if (scope == null) return null;
    final merchantId = scope.merchantId;

    final api = ref.read(merchantApiProvider);
    final summaryFuture = api.salesSummary(
      merchantId: merchantId,
      period: period,
      branchId: branchId,
    );
    final topFuture = api.topProducts(
      merchantId: merchantId,
      period: period,
      branchId: branchId,
      limit: reportsOverviewTopProductsLimit,
    );
    return SalesReportState(
      summary: await summaryFuture,
      topProducts: await topFuture,
    );
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // The error is exposed through `state` and rendered with a retry action.
    }
  }
}

final salesReportControllerProvider =
    AsyncNotifierProvider<SalesReportController, SalesReportState?>(
      SalesReportController.new,
      retry: _noAutomaticRetry,
    );

/// Today's summary for the selected Branch (Home KPI strip), independent of
/// the period chosen on the Reports tab.
final todaySalesSummaryProvider = FutureProvider<MerchantSalesSummary?>((
  ref,
) async {
  final scope = ref.watch(merchantDataScopeProvider);
  final branchId = ref.watch(
    accessControllerProvider.select((a) => a.selectedBranch?.id),
  );
  if (scope == null) return null;
  return ref
      .read(merchantApiProvider)
      .salesSummary(
        merchantId: scope.merchantId,
        period: ReportPeriodSelection.today,
        branchId: branchId,
      );
}, retry: _noAutomaticRetry);

class TopProductsSortController extends Notifier<TopProductSort> {
  @override
  TopProductSort build() => TopProductSort.orders;

  void select(TopProductSort sort) => state = sort;
}

final topProductsSortProvider =
    NotifierProvider<TopProductsSortController, TopProductSort>(
      TopProductsSortController.new,
    );

class TopProductsController extends AsyncNotifier<MerchantTopProducts?> {
  @override
  Future<MerchantTopProducts?> build() async {
    final scope = ref.watch(merchantDataScopeProvider);
    final branchId = ref.watch(
      accessControllerProvider.select((a) => a.selectedBranch?.id),
    );
    final period = ref.watch(reportPeriodProvider);
    final sort = ref.watch(topProductsSortProvider);
    if (scope == null) return null;
    return ref
        .read(merchantApiProvider)
        .topProducts(
          merchantId: scope.merchantId,
          period: period,
          branchId: branchId,
          sort: sort,
          limit: reportsTopProductsScreenLimit,
        );
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // Rendered through `state` with a retry action.
    }
  }
}

final topProductsControllerProvider =
    AsyncNotifierProvider<TopProductsController, MerchantTopProducts?>(
      TopProductsController.new,
      retry: _noAutomaticRetry,
    );
