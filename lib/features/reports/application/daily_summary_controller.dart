import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';
import 'package:speedygo_merchant_app/features/reports/presentation/report_widgets.dart';

Duration? _noAutomaticRetry(int _, Object _) => null;

/// Selected civil date (`YYYY-MM-DD`) for the daily summary screen.
class DailySummaryDateController extends Notifier<String> {
  @override
  String build() => reportCivilDate(DateTime.now());

  void select(String civilDate) => state = civilDate;
}

final dailySummaryDateProvider =
    NotifierProvider<DailySummaryDateController, String>(
      DailySummaryDateController.new,
    );

class DailySummaryController extends AsyncNotifier<MerchantDailySummary?> {
  @override
  Future<MerchantDailySummary?> build() async {
    final scope = ref.watch(merchantDataScopeProvider);
    final branchId = ref.watch(
      accessControllerProvider.select((a) => a.selectedBranch?.id),
    );
    final date = ref.watch(dailySummaryDateProvider);
    if (scope == null) return null;
    return ref.read(merchantApiProvider).dailySummary(
          merchantId: scope.merchantId,
          date: date,
          branchId: branchId,
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

final dailySummaryControllerProvider =
    AsyncNotifierProvider<DailySummaryController, MerchantDailySummary?>(
      DailySummaryController.new,
      retry: _noAutomaticRetry,
    );
