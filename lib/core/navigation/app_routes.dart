class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const language = '/language';
  static const onboarding = '/onboarding';
  static const phone = '/phone';
  static const otp = '/otp';
  static const restore = '/restore';
  static const registration = '/access/registration';
  static const noMembership = '/access/none';
  static const verificationPending = '/verification/pending';
  static const verificationRejected = '/verification/rejected';
  static const verificationSuspended = '/verification/suspended';
  static const verificationApproved = '/verification/approved';
  static const needBranch = '/access/need-branch';
  static const selectBranch = '/access/select-branch';
  static const home = '/app/home';
  static const orders = '/app/orders';
  static String orderDetail(String orderId) => '/app/orders/$orderId';
  static String orderSupport(String orderId) => '/app/orders/$orderId/support';
  static const catalog = '/app/catalog';
  static const catalogProductNew = '/app/catalog/products/new';
  static String catalogProductEdit(String productId) =>
      '/app/catalog/products/$productId';
  static const catalogCategoryNew = '/app/catalog/categories/new';
  static String catalogCategoryEdit(String categoryId) =>
      '/app/catalog/categories/$categoryId';
  static const catalogFilters = '/app/catalog/filters';
  static const catalogReorder = '/app/catalog/reorder';
  static const catalogBulkAvailability = '/app/catalog/availability';
  static String catalogCategoryDetail(String categoryId) =>
      '/app/catalog/category/$categoryId';
  static String catalogProductAvailability(String productId) =>
      '/app/catalog/products/$productId/availability';
  static String catalogProductDelete(String productId) =>
      '/app/catalog/products/$productId/delete';
  static String catalogProductVariants(String productId) =>
      '/app/catalog/products/$productId/variants';
  static String catalogProductExtras(String productId) =>
      '/app/catalog/products/$productId/extras';
  static String catalogProductDetails(String productId) =>
      '/app/catalog/products/$productId/details';
  static String catalogProductDuplicate(String productId) =>
      '/app/catalog/products/$productId/duplicate';
  static const reports = '/app/reports';
  static const reportsTopProducts = '/app/reports/top-products';
  static const reportsDailySummary = '/app/reports/daily-summary';
  static const profile = '/app/profile';
  static const settings = '/app/profile/settings';
  static const logout = '/app/profile/settings/logout';
  static const team = '/app/profile/team';
  static const teamInvitations = '/app/profile/team-invitations';
  /// Pending invites for authenticated accounts that have no MerchantMember yet.
  static const accessTeamInvitations = '/access/team-invitations';
  static const support = '/app/profile/support';
  static String supportTicket(String ticketId) =>
      '/app/profile/support/$ticketId';
  static const openingHours = '/app/profile/hours';
  static const openingHoursExceptions = '/app/profile/hours/exceptions';
  static const storeAvailability = '/app/profile/availability';
  static const temporaryClosure = '/app/profile/availability/temporary';
  static const storeCover = '/app/profile/cover';
  static const storeAddress = '/app/profile/address';
  static const storeGeneral = '/app/profile/general';
  static const storeCategory = '/app/profile/category';
  static const notifications = '/app/notifications';
  static const notificationSettings = '/app/notifications/settings';
  static const permissionDenied = '/access/denied';
  static const accessLoading = '/access/loading';
  static const accessError = '/access/error';
}
