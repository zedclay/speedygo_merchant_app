/// Merchant Support contract (`/merchant/:merchantId/support`). Tickets carry
/// an optional server `subject` and `topicCode`; older tickets have neither.
library;

enum SupportTicketStatus {
  open,
  inProgress,
  waitingCustomer,
  resolved,
  closed,
  unknown;

  static SupportTicketStatus parse(String? raw) => switch (raw) {
    'OPEN' => open,
    'IN_PROGRESS' => inProgress,
    'WAITING_CUSTOMER' => waitingCustomer,
    'RESOLVED' => resolved,
    'CLOSED' => closed,
    _ => unknown,
  };

  /// RESOLVED and CLOSED tickets no longer accept replies.
  bool get isFinished => this == resolved || this == closed;
}

class SupportTicketSummary {
  const SupportTicketSummary({
    required this.id,
    required this.publicReference,
    required this.status,
    required this.orderId,
    required this.createdAt,
    required this.updatedAt,
    this.subject,
    this.topicCode,
  });

  factory SupportTicketSummary.fromJson(Map<String, dynamic> json) =>
      SupportTicketSummary(
        id: json['id']?.toString() ?? '',
        publicReference: json['publicReference']?.toString() ?? '',
        status: SupportTicketStatus.parse(json['status']?.toString()),
        orderId: json['orderId']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
        subject: _trimmedOrNull(json['subject']),
        topicCode: _trimmedOrNull(json['topicCode']),
      );

  final String id;
  final String publicReference;
  final SupportTicketStatus status;
  final String? orderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? subject;
  final String? topicCode;

  /// Server subject when present, otherwise the public reference.
  String get displayTitle => subject ?? publicReference;
}

String? _trimmedOrNull(Object? raw) {
  final value = raw?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

/// One entry of `GET …/support/topics`.
class SupportTopic {
  const SupportTopic({required this.code, required this.labelFr});

  factory SupportTopic.fromJson(Map<String, dynamic> json) => SupportTopic(
    code: json['code']?.toString() ?? '',
    labelFr: json['labelFr']?.toString() ?? '',
  );

  final String code;
  final String labelFr;
}

/// One entry of `GET …/support/faq`.
class SupportFaqArticle {
  const SupportFaqArticle({
    required this.slug,
    required this.titleFr,
    required this.bodyFr,
    required this.version,
  });

  factory SupportFaqArticle.fromJson(Map<String, dynamic> json) =>
      SupportFaqArticle(
        slug: json['slug']?.toString() ?? '',
        titleFr: json['titleFr']?.toString() ?? '',
        bodyFr: json['bodyFr']?.toString() ?? '',
        version: json['version']?.toString() ?? '',
      );

  final String slug;
  final String titleFr;
  final String bodyFr;
  final String version;
}

class SupportTicketPage {
  const SupportTicketPage({required this.items, required this.total});

  factory SupportTicketPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return SupportTicketPage(
      items: raw is List
          ? [
              for (final e in raw)
                if (e is Map<String, dynamic>) SupportTicketSummary.fromJson(e),
            ]
          : const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  final List<SupportTicketSummary> items;
  final int total;
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.authorAccountId,
    required this.body,
    required this.createdAt,
    required this.displayName,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
    id: json['id']?.toString() ?? '',
    authorAccountId: json['authorAccountId']?.toString() ?? '',
    body: json['body']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    displayName: json['displayName']?.toString(),
  );

  final String id;
  final String authorAccountId;
  final String body;
  final DateTime? createdAt;
  final String? displayName;
}

class SupportTicketDetail {
  const SupportTicketDetail({
    required this.summary,
    required this.createdByAccountId,
    required this.orderPublicReference,
    required this.messages,
  });

  factory SupportTicketDetail.fromJson(Map<String, dynamic> json) {
    final order = json['order'];
    final raw = json['messages'];
    return SupportTicketDetail(
      summary: SupportTicketSummary.fromJson(json),
      createdByAccountId: json['createdByAccountId']?.toString() ?? '',
      orderPublicReference: order is Map
          ? order['publicReference']?.toString()
          : null,
      messages: raw is List
          ? [
              for (final e in raw)
                if (e is Map<String, dynamic>) SupportMessage.fromJson(e),
            ]
          : const [],
    );
  }

  final SupportTicketSummary summary;
  final String createdByAccountId;
  final String? orderPublicReference;
  final List<SupportMessage> messages;
}
