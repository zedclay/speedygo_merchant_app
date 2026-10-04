import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';

class ReportsState {
  const ReportsState({
    required this.ratings,
    required this.settlements,
    required this.settlementsForbidden,
  });

  final MerchantRatingSummary ratings;
  final List<MerchantSettlementSummary> settlements;
  final bool settlementsForbidden;
}

class ReportsController extends AsyncNotifier<ReportsState> {
  int _generation = 0;

  @override
  Future<ReportsState> build() async {
    ref.watch(accessControllerProvider);
    ref.watch(sessionControllerProvider.select((s) => s.accountId));
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<ReportsState> _load() async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final accountId = ref.read(sessionControllerProvider).accountId;
    if (membership == null) {
      return const ReportsState(
        ratings: MerchantRatingSummary(merchantId: '', count: 0, average: null),
        settlements: [],
        settlementsForbidden: false,
      );
    }

    final gen = ++_generation;
    final merchantId = membership.merchantId;
    final expectedAccount = accountId;
    final api = ref.read(merchantApiProvider);

    final ratings = await api.ratingsSummary(merchantId: merchantId);

    var settlements = const <MerchantSettlementSummary>[];
    var settlementsForbidden = false;
    try {
      settlements = await api.listSettlements(merchantId: merchantId);
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.code == 'MERCHANT_ROLE_FORBIDDEN') {
        settlementsForbidden = true;
      } else {
        rethrow;
      }
    }

    final latest = ref.read(accessControllerProvider);
    final latestSession = ref.read(sessionControllerProvider);
    if (gen != _generation) {
      return ReportsState(
        ratings: ratings,
        settlements: const [],
        settlementsForbidden: false,
      );
    }
    if (latest.membership?.merchantId != merchantId) {
      return const ReportsState(
        ratings: MerchantRatingSummary(merchantId: '', count: 0, average: null),
        settlements: [],
        settlementsForbidden: false,
      );
    }
    if (expectedAccount != null &&
        latestSession.accountId != null &&
        latestSession.accountId != expectedAccount) {
      return const ReportsState(
        ratings: MerchantRatingSummary(merchantId: '', count: 0, average: null),
        settlements: [],
        settlementsForbidden: false,
      );
    }

    return ReportsState(
      ratings: ratings,
      settlements: settlements,
      settlementsForbidden: settlementsForbidden,
    );
  }
}

final reportsControllerProvider =
    AsyncNotifierProvider<ReportsController, ReportsState>(
      ReportsController.new,
    );
