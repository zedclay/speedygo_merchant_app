import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/support/data/support_models.dart';

Duration? _noAutomaticRetry(int _, Object _) => null;

/// Page size of the Merchant support list (backend default and cap: 50/100).
const supportListLimit = 50;

/// Latest tickets of the active Merchant; `null` without a membership.
final supportTicketsProvider = FutureProvider.autoDispose<SupportTicketPage?>((
  ref,
) async {
  final scope = ref.watch(merchantDataScopeProvider);
  if (scope == null) return null;
  return ref
      .read(merchantApiProvider)
      .listSupportTickets(
        merchantId: scope.merchantId,
        limit: supportListLimit,
      );
}, retry: _noAutomaticRetry);

final supportTicketProvider = FutureProvider.autoDispose
    .family<SupportTicketDetail, String>((ref, ticketId) async {
      final scope = ref.watch(merchantDataScopeProvider);
      if (scope == null) throw StateError('no merchant membership');
      return ref
          .read(merchantApiProvider)
          .getSupportTicket(merchantId: scope.merchantId, ticketId: ticketId);
    }, retry: _noAutomaticRetry);

/// Server-managed ticket topics (code + French label).
final supportTopicsProvider = FutureProvider.autoDispose<List<SupportTopic>>((
  ref,
) async {
  final scope = ref.watch(merchantDataScopeProvider);
  if (scope == null) return const [];
  return ref
      .read(merchantApiProvider)
      .listSupportTopics(merchantId: scope.merchantId);
}, retry: _noAutomaticRetry);

/// Published FAQ articles; empty when the server has none.
final supportFaqProvider = FutureProvider.autoDispose<List<SupportFaqArticle>>((
  ref,
) async {
  final scope = ref.watch(merchantDataScopeProvider);
  if (scope == null) return const [];
  return ref
      .read(merchantApiProvider)
      .listSupportFaq(merchantId: scope.merchantId);
}, retry: _noAutomaticRetry);
