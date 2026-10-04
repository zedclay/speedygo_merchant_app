class AppConstants {
  const AppConstants._();

  static const String appName = 'SpeedyGo Merchant';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000/api/v1',
  );
  static const int otpResendCooldownSeconds = 60;
  static const int otpLength = 6;
}

class ApiEndpoints {
  const ApiEndpoints._();

  static const otpRequestPath = '/auth/otp/request';
  static const otpVerifyPath = '/auth/otp/verify';
  static const refreshPath = '/auth/refresh';
  static const logoutPath = '/auth/logout';
  static const mePath = '/auth/me';
  static const merchantMePath = '/merchant/me';
  static String merchantProfile = '/merchant/profile';
  static String merchantProfileUpdate(String merchantId) =>
      '/merchant/$merchantId/profile';
  static String merchantBranches(String merchantId) =>
      '/merchant/$merchantId/branches';
  static String merchantBranch(String merchantId, String branchId) =>
      '/merchant/$merchantId/branches/$branchId';
  static const merchantCommerceVerticals = '/merchant/commerce-verticals';
  static String merchantBranchClassification(
    String merchantId,
    String branchId,
  ) => '/merchant/$merchantId/branches/$branchId/classification';
  static const geoWilayas = '/geo/wilayas';
  static String geoCommunes(String wilayaCode) =>
      '/geo/wilayas/$wilayaCode/communes';
  static String merchantOrders(String merchantId) =>
      '/merchant/$merchantId/orders';
  static String merchantOrder(String merchantId, String orderId) =>
      '/merchant/$merchantId/orders/$orderId';
  static String merchantOrderAccept(String merchantId, String orderId) =>
      '/merchant/$merchantId/orders/$orderId/accept';
  static String merchantOrderPreparationEstimate(
    String merchantId,
    String orderId,
  ) => '/merchant/$merchantId/orders/$orderId/preparation-estimate';
  static String merchantOrderReject(String merchantId, String orderId) =>
      '/merchant/$merchantId/orders/$orderId/reject';
  static String merchantOrderStartPreparation(
    String merchantId,
    String orderId,
  ) => '/merchant/$merchantId/orders/$orderId/start-preparation';
  static String merchantOrderMarkReady(String merchantId, String orderId) =>
      '/merchant/$merchantId/orders/$orderId/mark-ready';
  static String merchantOrderDelivery(String merchantId, String orderId) =>
      '/merchant/$merchantId/orders/$orderId/delivery';
  static String merchantOrderPickupHandoff(String merchantId, String orderId) =>
      '/merchant/$merchantId/orders/$orderId/delivery/pickup-handoff';
  static String merchantOrderPickupHandoffRegenerate(
    String merchantId,
    String orderId,
  ) =>
      '/merchant/$merchantId/orders/$orderId/delivery/pickup-handoff/regenerate';
  static const merchantLegalCurrent = '/merchant/legal/current';
  static String merchantVerification(String merchantId) =>
      '/merchant/$merchantId/verification';
  static String merchantVerificationSubmit(String merchantId) =>
      '/merchant/$merchantId/verification/submit';
  static String merchantEvidenceContent(String merchantId, String type) =>
      '/merchant/$merchantId/verification/documents/$type/content';
  static String merchantEvidenceBind(String merchantId, String type) =>
      '/merchant/$merchantId/verification/documents/$type';
  static String merchantCatalog(String merchantId) =>
      '/merchant/$merchantId/catalog';
  static String merchantCategories(String merchantId) =>
      '/merchant/$merchantId/categories';
  static String merchantProducts(String merchantId) =>
      '/merchant/$merchantId/products';
  static String merchantProduct(String merchantId, String productId) =>
      '/merchant/$merchantId/products/$productId';
  static String merchantCategory(String merchantId, String categoryId) =>
      '/merchant/$merchantId/categories/$categoryId';
  static String merchantOptionGroups(String merchantId, String productId) =>
      '/merchant/$merchantId/products/$productId/option-groups';
  static String merchantOptionGroup(
    String merchantId,
    String productId,
    String groupId,
  ) => '/merchant/$merchantId/products/$productId/option-groups/$groupId';
  static String merchantOptions(
    String merchantId,
    String productId,
    String groupId,
  ) =>
      '/merchant/$merchantId/products/$productId/option-groups/$groupId/options';
  static String merchantOption(
    String merchantId,
    String productId,
    String groupId,
    String optionId,
  ) =>
      '/merchant/$merchantId/products/$productId/option-groups/$groupId/options/$optionId';
  static String merchantProductImageContent(
    String merchantId,
    String branchId,
    String productId,
  ) =>
      '/merchant/$merchantId/branches/$branchId/products/$productId/image/content';
  static String merchantProductImage(
    String merchantId,
    String branchId,
    String productId,
  ) => '/merchant/$merchantId/branches/$branchId/products/$productId/image';
  static String merchantBranchCoverContent(
    String merchantId,
    String branchId,
  ) => '/merchant/$merchantId/branches/$branchId/cover/content';
  static String merchantBranchCover(String merchantId, String branchId) =>
      '/merchant/$merchantId/branches/$branchId/cover';
  static String merchantBranchLogoContent(String merchantId, String branchId) =>
      '/merchant/$merchantId/branches/$branchId/logo/content';
  static String merchantBranchLogo(String merchantId, String branchId) =>
      '/merchant/$merchantId/branches/$branchId/logo';
  static String merchantProductDuplicate(String merchantId, String productId) =>
      '/merchant/$merchantId/products/$productId/duplicate';
  static String merchantRatingsSummary(String merchantId) =>
      '/merchant/$merchantId/ratings/summary';
  static String merchantSettlements(String merchantId) =>
      '/merchant/$merchantId/settlements';
  static String merchantReportsSales(String merchantId) =>
      '/merchant/$merchantId/reports/sales';
  static String merchantReportsTopProducts(String merchantId) =>
      '/merchant/$merchantId/reports/top-products';
  static String merchantReportsDailySummary(String merchantId) =>
      '/merchant/$merchantId/reports/daily-summary';
  static String merchantOpeningHours(String merchantId, String branchId) =>
      '/merchant/$merchantId/branches/$branchId/opening-hours';
  static String merchantOpeningHoursExceptions(
    String merchantId,
    String branchId,
  ) => '/merchant/$merchantId/branches/$branchId/opening-hours/exceptions';
  static String merchantOpeningHoursException(
    String merchantId,
    String branchId,
    String date,
  ) =>
      '/merchant/$merchantId/branches/$branchId/opening-hours/exceptions/$date';
  static String merchantAvailability(String merchantId, String branchId) =>
      '/merchant/$merchantId/branches/$branchId/availability';
  static const notificationsPath = '/notifications';
  static const notificationsUnreadCountPath = '/notifications/unread-count';
  static const notificationsReadAllPath = '/notifications/read-all';
  static String notificationRead(String notificationId) =>
      '/notifications/$notificationId/read';
  static const deviceTokensPath = '/notifications/device-tokens';
  static String merchantSupport(String merchantId) =>
      '/merchant/$merchantId/support';
  static String merchantSupportTopics(String merchantId) =>
      '/merchant/$merchantId/support/topics';
  static String merchantSupportFaq(String merchantId) =>
      '/merchant/$merchantId/support/faq';
  static String merchantSupportTicket(String merchantId, String ticketId) =>
      '/merchant/$merchantId/support/$ticketId';
  static String merchantSupportMessages(String merchantId, String ticketId) =>
      '/merchant/$merchantId/support/$ticketId/messages';
  static String merchantTeam(String merchantId) => '/merchant/$merchantId/team';
  static String merchantTeamInvitations(String merchantId) =>
      '/merchant/$merchantId/team/invitations';
  static String merchantTeamInvitationCancel(
    String merchantId,
    String invitationId,
  ) => '/merchant/$merchantId/team/invitations/$invitationId/cancel';
  static String merchantTeamInvitationRegenerate(
    String merchantId,
    String invitationId,
  ) => '/merchant/$merchantId/team/invitations/$invitationId/regenerate-code';
  static String merchantTeamMember(String merchantId, String memberId) =>
      '/merchant/$merchantId/team/members/$memberId';
  static const merchantMyTeamInvitations = '/merchant/me/team-invitations';
  static String merchantMyTeamInvitationAccept(String invitationId) =>
      '/merchant/me/team-invitations/$invitationId/accept';
}
