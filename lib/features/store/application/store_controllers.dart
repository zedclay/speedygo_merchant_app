import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/store/data/classification_models.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';

class OpeningHoursController extends AsyncNotifier<OpeningHoursSchedule> {
  @override
  Future<OpeningHoursSchedule> build() async {
    final access = ref.watch(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    if (membership == null || branch == null) {
      return OpeningHoursSchedule(
        branchId: '',
        timezone: 'Africa/Algiers',
        hoursConfigured: false,
        version: 0,
        days: OpeningHoursSchedule.blankWeek(),
      );
    }
    return ref
        .read(merchantApiProvider)
        .getOpeningHours(
          merchantId: membership.merchantId,
          branchId: branch.id,
        );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Only replaces state after PUT 200; a version conflict reloads server
  /// truth. Errors are rethrown so the editor keeps the draft.
  Future<OpeningHoursSchedule> save(List<OpeningDay> days) async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    final current = state.value;
    if (membership == null || branch == null || current == null) {
      throw StateError('No branch selected');
    }
    try {
      final saved = await ref
          .read(merchantApiProvider)
          .putOpeningHours(
            merchantId: membership.merchantId,
            branchId: branch.id,
            expectedVersion: current.version ?? 0,
            days: days,
          );
      state = AsyncData(saved);
      ref.invalidate(branchAvailabilityControllerProvider);
      return saved;
    } catch (e) {
      if (e is ApiException &&
          (e.code == 'OPENING_HOURS_VERSION_CONFLICT' || e.statusCode == 409)) {
        await reload();
      }
      rethrow;
    }
  }
}

class OpeningHoursExceptionsController
    extends AsyncNotifier<OpeningHoursExceptionList> {
  @override
  Future<OpeningHoursExceptionList> build() async {
    final access = ref.watch(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    if (membership == null || branch == null) {
      return const OpeningHoursExceptionList(
        branchId: '',
        timezone: 'Africa/Algiers',
        today: '',
        items: [],
      );
    }
    return ref
        .read(merchantApiProvider)
        .listOpeningHoursExceptions(
          merchantId: membership.merchantId,
          branchId: branch.id,
        );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Creates (version 0) or replaces the exception for [date]. State only
  /// changes after the server confirms; a version conflict or missing row
  /// reloads server truth and rethrows so the editor keeps its draft.
  Future<OpeningHoursException> save({
    required String date,
    required bool closed,
    required List<OpeningInterval> intervals,
    required String label,
    String? customerMessage,
  }) async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    final current = state.value;
    if (membership == null || branch == null || current == null) {
      throw StateError('No branch selected');
    }
    try {
      final saved = await ref
          .read(merchantApiProvider)
          .putOpeningHoursException(
            merchantId: membership.merchantId,
            branchId: branch.id,
            date: date,
            expectedVersion: current.byDate(date)?.version ?? 0,
            closed: closed,
            intervals: closed ? const [] : intervals,
            label: label,
            customerMessage: customerMessage,
          );
      final items = [
        for (final item in current.items)
          if (item.date != date) item,
        saved,
      ]..sort((a, b) => a.date.compareTo(b.date));
      state = AsyncData(
        OpeningHoursExceptionList(
          branchId: current.branchId,
          timezone: current.timezone,
          today: current.today,
          items: items,
        ),
      );
      ref.invalidate(branchAvailabilityControllerProvider);
      return saved;
    } catch (e) {
      if (_isStale(e)) await reload();
      rethrow;
    }
  }

  Future<void> delete(String date) async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    final current = state.value;
    final existing = current?.byDate(date);
    if (membership == null ||
        branch == null ||
        current == null ||
        existing == null) {
      throw StateError('No exception for $date');
    }
    try {
      await ref
          .read(merchantApiProvider)
          .deleteOpeningHoursException(
            merchantId: membership.merchantId,
            branchId: branch.id,
            date: date,
            expectedVersion: existing.version,
          );
      state = AsyncData(
        OpeningHoursExceptionList(
          branchId: current.branchId,
          timezone: current.timezone,
          today: current.today,
          items: [
            for (final item in current.items)
              if (item.date != date) item,
          ],
        ),
      );
      ref.invalidate(branchAvailabilityControllerProvider);
    } catch (e) {
      if (_isStale(e)) await reload();
      rethrow;
    }
  }

  static bool _isStale(Object e) =>
      e is ApiException &&
      (e.code == 'OPENING_HOURS_EXCEPTION_VERSION_CONFLICT' ||
          e.code == 'OPENING_HOURS_EXCEPTION_NOT_FOUND');
}

final openingHoursExceptionsControllerProvider =
    AsyncNotifierProvider<
      OpeningHoursExceptionsController,
      OpeningHoursExceptionList
    >(OpeningHoursExceptionsController.new);

/// Branch editors (hours, availability, cover, address) are
/// OWNER/MANAGER only on the server (`MERCHANT_BRANCH_UPDATE`).
bool branchRoleCanManage(String role) {
  final r = role.toUpperCase();
  return r == 'OWNER' || r == 'MANAGER';
}

final storeClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

final openingHoursControllerProvider =
    AsyncNotifierProvider<OpeningHoursController, OpeningHoursSchedule>(
      OpeningHoursController.new,
    );

class BranchAvailabilityController
    extends AsyncNotifier<BranchAvailabilityState> {
  @override
  Future<BranchAvailabilityState> build() async {
    final access = ref.watch(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    if (membership == null || branch == null) {
      return const BranchAvailabilityState(
        branchId: '',
        timezone: 'Africa/Algiers',
        availabilityMode: 'FOLLOW_SCHEDULE',
        effectiveMode: 'FOLLOW_SCHEDULE',
        hoursConfigured: false,
        isOpenNow: false,
        acceptingOrders: false,
        temporaryExpired: false,
        outsideWeeklyHours: false,
        reasonCode: null,
        customerMessage: null,
        closedUntil: null,
        nextOpenAt: null,
        currentClosesAt: null,
        version: null,
        updatedAt: null,
      );
    }
    return ref
        .read(merchantApiProvider)
        .getAvailability(
          merchantId: membership.merchantId,
          branchId: branch.id,
        );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Honest save — only updates state after PUT 200.
  Future<BranchAvailabilityState> save({
    required String mode,
    String? reasonCode,
    String? customerMessage,
    String? closedUntil,
  }) async {
    final access = ref.read(accessControllerProvider);
    final membership = access.membership;
    final branch = access.selectedBranch;
    final current = state.value;
    if (membership == null || branch == null || current == null) {
      throw StateError('No branch selected');
    }
    final expectedVersion = current.version ?? 0;
    try {
      final saved = await ref
          .read(merchantApiProvider)
          .putAvailability(
            merchantId: membership.merchantId,
            branchId: branch.id,
            expectedVersion: expectedVersion,
            mode: mode,
            reasonCode: reasonCode,
            customerMessage: customerMessage,
            closedUntil: closedUntil,
          );
      state = AsyncData(saved);
      return saved;
    } catch (e) {
      // Version conflict → reload server truth; never silent overwrite.
      final code = e is ApiException ? e.code : null;
      if (code == 'AVAILABILITY_VERSION_CONFLICT' ||
          (e is ApiException && e.statusCode == 409)) {
        await reload();
      }
      rethrow;
    }
  }
}

final branchAvailabilityControllerProvider =
    AsyncNotifierProvider<
      BranchAvailabilityController,
      BranchAvailabilityState
    >(BranchAvailabilityController.new);

class NotificationsController
    extends AsyncNotifier<List<MerchantNotificationItem>> {
  @override
  Future<List<MerchantNotificationItem>> build() async {
    return ref.read(merchantApiProvider).listNotifications();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> markRead(String id) async {
    await ref.read(merchantApiProvider).markNotificationRead(id);
    await reload();
    ref.invalidate(notificationsUnreadCountProvider);
  }

  Future<void> markAllRead() async {
    await ref.read(merchantApiProvider).markAllNotificationsRead();
    await reload();
    ref.invalidate(notificationsUnreadCountProvider);
  }
}

final notificationsControllerProvider =
    AsyncNotifierProvider<
      NotificationsController,
      List<MerchantNotificationItem>
    >(NotificationsController.new);

final notificationsUnreadCountProvider = FutureProvider<int>((ref) async {
  ref.watch(accessControllerProvider);
  try {
    return await ref.read(merchantApiProvider).notificationsUnreadCount();
  } catch (_) {
    return 0;
  }
});

Duration? _noAutomaticRetry(int _, Object _) => null;

/// Server list of commerce verticals a Branch can be classified under.
final commerceVerticalsProvider =
    FutureProvider.autoDispose<List<CommerceVertical>>((ref) async {
      final verticals = await ref
          .read(merchantApiProvider)
          .listCommerceVerticals();
      return [...verticals]..sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
      });
    }, retry: _noAutomaticRetry);

/// The selected Branch's current classification; `null` when unset.
final branchClassificationProvider =
    FutureProvider.autoDispose<BranchClassification?>((ref) async {
      final access = ref.watch(accessControllerProvider);
      final membership = access.membership;
      final branch = access.selectedBranch;
      if (membership == null || branch == null) return null;
      return ref
          .read(merchantApiProvider)
          .getBranchClassification(
            merchantId: membership.merchantId,
            branchId: branch.id,
          );
    }, retry: _noAutomaticRetry);
