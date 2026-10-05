// GENERATED facade — source of truth: lib/l10n/app_*.arb (+ complex helpers below).
import 'package:flutter/widgets.dart';
import 'package:speedygo_merchant_app/l10n/app_localizations.dart';

/// Localized Merchant UI strings. Call [bind] from the app shell on rebuild.
class AppStrings {
  const AppStrings._();

  static AppLocalizations? _l10n;
  static String _code = 'fr';

  static void bind(AppLocalizations l10n, String languageCode) {
    _l10n = l10n;
    _code = languageCode == 'ar' ? 'ar' : 'fr';
  }

  static AppLocalizations get l10n =>
      _l10n ?? lookupAppLocalizations(const Locale('fr'));

  static bool get isArabic => _code == 'ar';

  static const sellingUnitCustomMaxLength = 40;

  static String get accessRestrictedBody => l10n.accessRestrictedBody;
  static String get accessRestrictedTitle => l10n.accessRestrictedTitle;
  static String get addBranch => l10n.addBranch;
  static String get adminLocationChoose => l10n.adminLocationChoose;
  static String get adminLocationEmpty => l10n.adminLocationEmpty;
  static String get adminLocationLoadError => l10n.adminLocationLoadError;
  static String get adminLocationPairRequired => l10n.adminLocationPairRequired;
  static String get adminLocationRetry => l10n.adminLocationRetry;
  static String get adminLocationSearchHint => l10n.adminLocationSearchHint;
  static String get adminLocationWilayaRequired => l10n.adminLocationWilayaRequired;
  static String get alertDismiss => l10n.alertDismiss;
  static String get alertItems => l10n.alertItems;
  static String get alertNewOrder => l10n.alertNewOrder;
  static String get alertOrderLabel => l10n.alertOrderLabel;
  static String get alertOrderTotal => l10n.alertOrderTotal;
  static String get alertPayment => l10n.alertPayment;
  static String get alertReceivedAt => l10n.alertReceivedAt;
  static String get alertRefuse => l10n.alertRefuse;
  static String get alertSeeList => l10n.alertSeeList;
  static String get alertViewDetails => l10n.alertViewDetails;
  static String get appName => l10n.appName;
  static String get approvedAlertsBody => l10n.approvedAlertsBody;
  static String get approvedAlertsTitle => l10n.approvedAlertsTitle;
  static String get approvedBadge => l10n.approvedBadge;
  static String get approvedBody => l10n.approvedBody;
  static String get approvedCatalogBody => l10n.approvedCatalogBody;
  static String get approvedCatalogTitle => l10n.approvedCatalogTitle;
  static String get approvedContinue => l10n.approvedContinue;
  static String get approvedHoursBody => l10n.approvedHoursBody;
  static String get approvedHoursTitle => l10n.approvedHoursTitle;
  static String get approvedNeedBranchHint => l10n.approvedNeedBranchHint;
  static String get approvedNotOpenNote => l10n.approvedNotOpenNote;
  static String get approvedReferenceFull => l10n.approvedReferenceFull;
  static String get approvedReferenceLabel => l10n.approvedReferenceLabel;
  static String get approvedStepsTitle => l10n.approvedStepsTitle;
  static String get approvedSubtitle => l10n.approvedSubtitle;
  static String get approvedTitle => l10n.approvedTitle;
  static String get attentionRequired => l10n.attentionRequired;
  static String get availabilityActiveOrdersUnknown => l10n.availabilityActiveOrdersUnknown;
  static String get availabilityBannerClosedBody => l10n.availabilityBannerClosedBody;
  static String get availabilityBannerClosedTitle => l10n.availabilityBannerClosedTitle;
  static String get availabilityBannerOpenBody => l10n.availabilityBannerOpenBody;
  static String get availabilityBannerOpenTitle => l10n.availabilityBannerOpenTitle;
  static String get availabilityBannerScheduleClosedBody => l10n.availabilityBannerScheduleClosedBody;
  static String get availabilityBannerScheduleClosedTitle => l10n.availabilityBannerScheduleClosedTitle;
  static String get availabilityCloseWarningTitle => l10n.availabilityCloseWarningTitle;
  static String get availabilityClosed => l10n.availabilityClosed;
  static String get availabilityClosedToday => l10n.availabilityClosedToday;
  static String get availabilityClosureSaved => l10n.availabilityClosureSaved;
  static String get availabilityConfirmReopen => l10n.availabilityConfirmReopen;
  static String get availabilityConflict => l10n.availabilityConflict;
  static String get availabilityEstablishment => l10n.availabilityEstablishment;
  static String get availabilityFollowSchedule => l10n.availabilityFollowSchedule;
  static String get availabilityForceClosed => l10n.availabilityForceClosed;
  static String get availabilityLoadError => l10n.availabilityLoadError;
  static String get availabilityModifyHours => l10n.availabilityModifyHours;
  static String get availabilityOpen => l10n.availabilityOpen;
  static String get availabilityPause30 => l10n.availabilityPause30;
  static String get availabilityPause60 => l10n.availabilityPause60;
  static String get availabilityQuickPause => l10n.availabilityQuickPause;
  static String get availabilityQuickPauseHint => l10n.availabilityQuickPauseHint;
  static String get availabilityReasonLunch => l10n.availabilityReasonLunch;
  static String get availabilityReasonPeak => l10n.availabilityReasonPeak;
  static String get availabilityReasonStock => l10n.availabilityReasonStock;
  static String get availabilityReasonTechnical => l10n.availabilityReasonTechnical;
  static String get availabilityReopenOutsideHoursBody => l10n.availabilityReopenOutsideHoursBody;
  static String get availabilityReopenTitle => l10n.availabilityReopenTitle;
  static String get availabilitySave => l10n.availabilitySave;
  static String get availabilitySaveError => l10n.availabilitySaveError;
  static String get availabilitySaved => l10n.availabilitySaved;
  static String get availabilitySaving => l10n.availabilitySaving;
  static String get availabilityStaffReadOnly => l10n.availabilityStaffReadOnly;
  static String get availabilityTitle => l10n.availabilityTitle;
  static String get availabilityToday => l10n.availabilityToday;
  static String get back => l10n.back;
  static String get branchAddressLabel => l10n.branchAddressLabel;
  static String get branchLatLabel => l10n.branchLatLabel;
  static String get branchLngLabel => l10n.branchLngLabel;
  static String get branchNameLabel => l10n.branchNameLabel;
  static String get branchPhoneLabel => l10n.branchPhoneLabel;
  static String get brandName => l10n.brandName;
  static String get cancel => l10n.cancel;
  static String get catalogAddCategory => l10n.catalogAddCategory;
  static String get catalogAddChoice => l10n.catalogAddChoice;
  static String get catalogAddExtrasGroup => l10n.catalogAddExtrasGroup;
  static String get catalogAddOption => l10n.catalogAddOption;
  static String get catalogAddProduct => l10n.catalogAddProduct;
  static String get catalogAddVariantGroup => l10n.catalogAddVariantGroup;
  static String get catalogAllCategories => l10n.catalogAllCategories;
  static String get catalogAvailabilityError => l10n.catalogAvailabilityError;
  static String get catalogAvailabilityNote => l10n.catalogAvailabilityNote;
  static String get catalogAvailabilitySave => l10n.catalogAvailabilitySave;
  static String get catalogAvailabilitySaved => l10n.catalogAvailabilitySaved;
  static String get catalogAvailabilityState => l10n.catalogAvailabilityState;
  static String get catalogAvailabilityTitle => l10n.catalogAvailabilityTitle;
  static String get catalogAvailableOption => l10n.catalogAvailableOption;
  static String get catalogAvailableOptionSub => l10n.catalogAvailableOptionSub;
  static String get catalogBulkApply => l10n.catalogBulkApply;
  static String get catalogBulkClear => l10n.catalogBulkClear;
  static String catalogBulkDone(String n) => l10n.catalogBulkDone(n);
  static String catalogBulkFailed(String n) => l10n.catalogBulkFailed(n);
  static String get catalogBulkNewStatus => l10n.catalogBulkNewStatus;
  static String get catalogBulkNote => l10n.catalogBulkNote;
  static String get catalogBulkSelectAll => l10n.catalogBulkSelectAll;
  static String get catalogBulkSelection => l10n.catalogBulkSelection;
  static String get catalogBulkTitle => l10n.catalogBulkTitle;
  static String get catalogBulkTooltip => l10n.catalogBulkTooltip;
  static String get catalogCategoryActive => l10n.catalogCategoryActive;
  static String get catalogCategoryActiveSub => l10n.catalogCategoryActiveSub;
  static String get catalogCategoryCancel => l10n.catalogCategoryCancel;
  static String get catalogCategoryDetailTitle => l10n.catalogCategoryDetailTitle;
  static String get catalogCategoryDetails => l10n.catalogCategoryDetails;
  static String get catalogCategoryEmpty => l10n.catalogCategoryEmpty;
  static String get catalogCategoryInUse => l10n.catalogCategoryInUse;
  static String get catalogCategoryName => l10n.catalogCategoryName;
  static String get catalogCategoryProducts => l10n.catalogCategoryProducts;
  static String get catalogCategoryRequired => l10n.catalogCategoryRequired;
  static String get catalogCategorySearchHint => l10n.catalogCategorySearchHint;
  static String get catalogCategorySettings => l10n.catalogCategorySettings;
  static String get catalogCropFormat => l10n.catalogCropFormat;
  static String get catalogCropRemove => l10n.catalogCropRemove;
  static String get catalogCropRotate => l10n.catalogCropRotate;
  static String get catalogCropTip1 => l10n.catalogCropTip1;
  static String get catalogCropTip2 => l10n.catalogCropTip2;
  static String catalogCropTip3(String name) => l10n.catalogCropTip3(name);
  static String get catalogCropTipsTitle => l10n.catalogCropTipsTitle;
  static String get catalogCropTitle => l10n.catalogCropTitle;
  static String get catalogCropUse => l10n.catalogCropUse;
  static String get catalogCropZoom => l10n.catalogCropZoom;
  static String get catalogCurrencySuffix => l10n.catalogCurrencySuffix;
  static String get catalogCustomerPreview => l10n.catalogCustomerPreview;
  static String get catalogDeleteCategory => l10n.catalogDeleteCategory;
  static String get catalogDeleteCategoryConfirm => l10n.catalogDeleteCategoryConfirm;
  static String get catalogDeleteConfirm => l10n.catalogDeleteConfirm;
  static String get catalogDeleteHardConfirm => l10n.catalogDeleteHardConfirm;
  static String get catalogDeleteHardOption => l10n.catalogDeleteHardOption;
  static String get catalogDeleteHardOptionSub => l10n.catalogDeleteHardOptionSub;
  static String get catalogDeleteHideOption => l10n.catalogDeleteHideOption;
  static String get catalogDeleteHideOptionSub => l10n.catalogDeleteHideOptionSub;
  static String get catalogDeleteProduct => l10n.catalogDeleteProduct;
  static String get catalogDeleteRecommended => l10n.catalogDeleteRecommended;
  static String get catalogDeleteTitle => l10n.catalogDeleteTitle;
  static String get catalogDeleteWarningBody => l10n.catalogDeleteWarningBody;
  static String get catalogDeleteWarningTitle => l10n.catalogDeleteWarningTitle;
  static String get catalogDeleted => l10n.catalogDeleted;
  static String get catalogDetailAppearance => l10n.catalogDetailAppearance;
  static String get catalogDetailAvailable => l10n.catalogDetailAvailable;
  static String get catalogDetailInfo => l10n.catalogDetailInfo;
  static String get catalogDetailName => l10n.catalogDetailName;
  static String get catalogDetailNoDescription => l10n.catalogDetailNoDescription;
  static String get catalogDetailNoOptions => l10n.catalogDetailNoOptions;
  static String get catalogDetailPrice => l10n.catalogDetailPrice;
  static String get catalogDetailPricing => l10n.catalogDetailPricing;
  static String catalogDisplayOrder(String n) => l10n.catalogDisplayOrder(n);
  static String get catalogEditCategory => l10n.catalogEditCategory;
  static String get catalogEditGroup => l10n.catalogEditGroup;
  static String get catalogEditProduct => l10n.catalogEditProduct;
  static String get catalogEmptyCategories => l10n.catalogEmptyCategories;
  static String get catalogEmptyProducts => l10n.catalogEmptyProducts;
  static String get catalogExtrasSubtitle => l10n.catalogExtrasSubtitle;
  static String get catalogExtrasTitle => l10n.catalogExtrasTitle;
  static String get catalogFieldCategoryDesc => l10n.catalogFieldCategoryDesc;
  static String get catalogFieldCategoryNameAr => l10n.catalogFieldCategoryNameAr;
  static String get catalogFieldDescAr => l10n.catalogFieldDescAr;
  static String get catalogFieldExtras => l10n.catalogFieldExtras;
  static String get catalogFieldNameAr => l10n.catalogFieldNameAr;
  static String get catalogFieldPrepTime => l10n.catalogFieldPrepTime;
  static String get catalogFieldRequired => l10n.catalogFieldRequired;
  static String get catalogFieldSaleUnit => l10n.catalogFieldSaleUnit;
  static String get catalogFieldVariants => l10n.catalogFieldVariants;
  static String get catalogFilterTooltip => l10n.catalogFilterTooltip;
  static String get catalogFiltersApply => l10n.catalogFiltersApply;
  static String get catalogFiltersCategories => l10n.catalogFiltersCategories;
  static String get catalogFiltersMissingImage => l10n.catalogFiltersMissingImage;
  static String get catalogFiltersOutOfStock => l10n.catalogFiltersOutOfStock;
  static String get catalogFiltersPreview => l10n.catalogFiltersPreview;
  static String get catalogFiltersQuality => l10n.catalogFiltersQuality;
  static String get catalogFiltersReset => l10n.catalogFiltersReset;
  static String get catalogFiltersStatus => l10n.catalogFiltersStatus;
  static String get catalogFiltersTitle => l10n.catalogFiltersTitle;
  static String get catalogGroupDelete => l10n.catalogGroupDelete;
  static String get catalogGroupDeleteConfirm => l10n.catalogGroupDeleteConfirm;
  static String get catalogGroupInvalid => l10n.catalogGroupInvalid;
  static String get catalogGroupName => l10n.catalogGroupName;
  static String get catalogGroupNameHint => l10n.catalogGroupNameHint;
  static String get catalogGroupRequiredSub => l10n.catalogGroupRequiredSub;
  static String get catalogGroupRequiredSwitch => l10n.catalogGroupRequiredSwitch;
  static String get catalogGroupSave => l10n.catalogGroupSave;
  static String get catalogGroupsLoadError => l10n.catalogGroupsLoadError;
  static String get catalogHidden => l10n.catalogHidden;
  static String get catalogImageAdd => l10n.catalogImageAdd;
  static String get catalogImageBindPartial => l10n.catalogImageBindPartial;
  static String get catalogImageChange => l10n.catalogImageChange;
  static String get catalogImageChangePhoto => l10n.catalogImageChangePhoto;
  static String get catalogImageFormatError => l10n.catalogImageFormatError;
  static String get catalogImageFromCamera => l10n.catalogImageFromCamera;
  static String get catalogImageFromGallery => l10n.catalogImageFromGallery;
  static String get catalogImageHint => l10n.catalogImageHint;
  static String get catalogImagePick => l10n.catalogImagePick;
  static String get catalogImagePluginRestart => l10n.catalogImagePluginRestart;
  static String get catalogImagePrimary => l10n.catalogImagePrimary;
  static String get catalogImageRemoteUnavailable => l10n.catalogImageRemoteUnavailable;
  static String get catalogImageRemove => l10n.catalogImageRemove;
  static String get catalogImageTooLarge => l10n.catalogImageTooLarge;
  static String get catalogImageTooSmall => l10n.catalogImageTooSmall;
  static String get catalogImageUploadError => l10n.catalogImageUploadError;
  static String get catalogInStock => l10n.catalogInStock;
  static String get catalogInStockNow => l10n.catalogInStockNow;
  static String get catalogLastUpdated => l10n.catalogLastUpdated;
  static String get catalogLoadError => l10n.catalogLoadError;
  static String get catalogMarkedOutOfStock => l10n.catalogMarkedOutOfStock;
  static String get catalogMaxSelectionsLabel => l10n.catalogMaxSelectionsLabel;
  static String get catalogMenuAvailability => l10n.catalogMenuAvailability;
  static String get catalogMenuDelete => l10n.catalogMenuDelete;
  static String get catalogMenuDuplicate => l10n.catalogMenuDuplicate;
  static String get catalogMenuViewCategory => l10n.catalogMenuViewCategory;
  static String get catalogNeedCategory => l10n.catalogNeedCategory;
  static String get catalogNewGroup => l10n.catalogNewGroup;
  static String get catalogNoCategoryResults => l10n.catalogNoCategoryResults;
  static String get catalogNoResults => l10n.catalogNoResults;
  static String get catalogOfflineBanner => l10n.catalogOfflineBanner;
  static String get catalogOnlineBanner => l10n.catalogOnlineBanner;
  static String get catalogOptionAvailable => l10n.catalogOptionAvailable;
  static String get catalogOptionDelete => l10n.catalogOptionDelete;
  static String get catalogOptionName => l10n.catalogOptionName;
  static String get catalogOptionPrice => l10n.catalogOptionPrice;
  static String catalogOptionalSummary(String max) => l10n.catalogOptionalSummary(max);
  static String get catalogOptionsEmpty => l10n.catalogOptionsEmpty;
  static String get catalogOutOfStock => l10n.catalogOutOfStock;
  static String get catalogOutOfStockNow => l10n.catalogOutOfStockNow;
  static String get catalogOutOfStockOptionSub => l10n.catalogOutOfStockOptionSub;
  static String get catalogPreview => l10n.catalogPreview;
  static String get catalogPreviewTitle => l10n.catalogPreviewTitle;
  static String get catalogPreviewUnavailable => l10n.catalogPreviewUnavailable;
  static String get catalogPriceInvalid => l10n.catalogPriceInvalid;
  static String get catalogPriceWarning => l10n.catalogPriceWarning;
  static String get catalogProductAvailable => l10n.catalogProductAvailable;
  static String get catalogProductAvailableSub => l10n.catalogProductAvailableSub;
  static String get catalogProductCategory => l10n.catalogProductCategory;
  static String get catalogProductDescription => l10n.catalogProductDescription;
  static String get catalogProductDetail => l10n.catalogProductDetail;
  static String get catalogProductDetailTitle => l10n.catalogProductDetailTitle;
  static String get catalogProductInUse => l10n.catalogProductInUse;
  static String get catalogProductName => l10n.catalogProductName;
  static String get catalogProductPrice => l10n.catalogProductPrice;
  static String catalogProductsCount(String n) => l10n.catalogProductsCount(n);
  static String get catalogReorder => l10n.catalogReorder;
  static String get catalogReorderHint => l10n.catalogReorderHint;
  static String get catalogReorderPartial => l10n.catalogReorderPartial;
  static String get catalogReorderSave => l10n.catalogReorderSave;
  static String get catalogReorderSaved => l10n.catalogReorderSaved;
  static String get catalogReorderTitle => l10n.catalogReorderTitle;
  static String catalogRequiredSummary(String rule) => l10n.catalogRequiredSummary(rule);
  static String get catalogRequiredTag => l10n.catalogRequiredTag;
  static String get catalogSaveError => l10n.catalogSaveError;
  static String get catalogSaveFirstForOptions => l10n.catalogSaveFirstForOptions;
  static String get catalogSaveProduct => l10n.catalogSaveProduct;
  static String get catalogSaveProductEdits => l10n.catalogSaveProductEdits;
  static String get catalogSaveRetryHint => l10n.catalogSaveRetryHint;
  static String get catalogSearchHint => l10n.catalogSearchHint;
  static String get catalogSectionAvailability => l10n.catalogSectionAvailability;
  static String get catalogSectionConfig => l10n.catalogSectionConfig;
  static String get catalogSectionGeneral => l10n.catalogSectionGeneral;
  static String get catalogSectionImage => l10n.catalogSectionImage;
  static String get catalogSectionInfo => l10n.catalogSectionInfo;
  static String get catalogSectionMedia => l10n.catalogSectionMedia;
  static String get catalogSectionPrice => l10n.catalogSectionPrice;
  static String get catalogSectionPriceDetails => l10n.catalogSectionPriceDetails;
  static String get catalogSingleChoice => l10n.catalogSingleChoice;
  static String get catalogStaffReadOnly => l10n.catalogStaffReadOnly;
  static String get catalogTabCategories => l10n.catalogTabCategories;
  static String get catalogTabProducts => l10n.catalogTabProducts;
  static String get catalogTitle => l10n.catalogTitle;
  static String get catalogUnavailableSection => l10n.catalogUnavailableSection;
  static String get catalogUncategorized => l10n.catalogUncategorized;
  static String get catalogVariantsInfo => l10n.catalogVariantsInfo;
  static String get catalogVariantsSubtitle => l10n.catalogVariantsSubtitle;
  static String get catalogVariantsTitle => l10n.catalogVariantsTitle;
  static String get catalogVisibilityError => l10n.catalogVisibilityError;
  static String get catalogVisible => l10n.catalogVisible;
  static String get checklistTitle => l10n.checklistTitle;
  static String get continueLabel => l10n.continueLabel;
  static String get contractFieldUnavailable => l10n.contractFieldUnavailable;
  static String get createMerchant => l10n.createMerchant;
  static String get deliveryArrived => l10n.deliveryArrived;
  static String get deliveryAssigned => l10n.deliveryAssigned;
  static String get deliveryAtPickup => l10n.deliveryAtPickup;
  static String get deliveryCancelled => l10n.deliveryCancelled;
  static String get deliveryDelivered => l10n.deliveryDelivered;
  static String get deliveryFailed => l10n.deliveryFailed;
  static String get deliveryImpactDriverWaiting => l10n.deliveryImpactDriverWaiting;
  static String deliveryImpactLatestRevision(String reason) => l10n.deliveryImpactLatestRevision(reason);
  static String get deliveryImpactMayDelayDriverAssignment => l10n.deliveryImpactMayDelayDriverAssignment;
  static String get deliveryImpactMayDelayPickup => l10n.deliveryImpactMayDelayPickup;
  static String get deliveryImpactTimingUnavailable => l10n.deliveryImpactTimingUnavailable;
  static String get deliveryImpactTitle => l10n.deliveryImpactTitle;
  static String get deliveryInTransit => l10n.deliveryInTransit;
  static String get deliveryPickedUp => l10n.deliveryPickedUp;
  static String get deliverySearching => l10n.deliverySearching;
  static String get deliveryToPickup => l10n.deliveryToPickup;
  static String get deliveryUnknown => l10n.deliveryUnknown;
  static String get dossierAttemptLabel => l10n.dossierAttemptLabel;
  static String get dossierConsentLabel => l10n.dossierConsentLabel;
  static String dossierConsentVersions(String terms, String declaration) => l10n.dossierConsentVersions(terms, declaration);
  static String get dossierReviewedAtLabel => l10n.dossierReviewedAtLabel;
  static String get dossierSubmittedAtLabel => l10n.dossierSubmittedAtLabel;
  static String get duplicateBackToCatalog => l10n.duplicateBackToCatalog;
  static String get duplicateCancel => l10n.duplicateCancel;
  static String get duplicateClearName => l10n.duplicateClearName;
  static String get duplicateConflict => l10n.duplicateConflict;
  static String get duplicateCopied => l10n.duplicateCopied;
  static String get duplicateCreate => l10n.duplicateCreate;
  static String get duplicateCreated => l10n.duplicateCreated;
  static String get duplicateCreating => l10n.duplicateCreating;
  static String duplicateDefaultName(String name) => l10n.duplicateDefaultName(name);
  static String get duplicateError => l10n.duplicateError;
  static String get duplicateForbiddenTitle => l10n.duplicateForbiddenTitle;
  static String get duplicateImage => l10n.duplicateImage;
  static String get duplicateNamePlaceholder => l10n.duplicateNamePlaceholder;
  static String get duplicateNameRequired => l10n.duplicateNameRequired;
  static String get duplicateNameTooLong => l10n.duplicateNameTooLong;
  static String get duplicateNetworkError => l10n.duplicateNetworkError;
  static String get duplicateNewName => l10n.duplicateNewName;
  static String get duplicateNewNameHint => l10n.duplicateNewNameHint;
  static String get duplicateNoImage => l10n.duplicateNoImage;
  static String get duplicateNotCopiedLead => l10n.duplicateNotCopiedLead;
  static String get duplicateNotCopiedStrong => l10n.duplicateNotCopiedStrong;
  static String get duplicateNotCopiedTail => l10n.duplicateNotCopiedTail;
  static String get duplicateNotFound => l10n.duplicateNotFound;
  static String get duplicateOptions => l10n.duplicateOptions;
  static String duplicatePrice(String price) => l10n.duplicatePrice(price);
  static String get duplicateReplayed => l10n.duplicateReplayed;
  static String get duplicateSaleUnits => l10n.duplicateSaleUnits;
  static String get duplicateSource => l10n.duplicateSource;
  static String get duplicateTitle => l10n.duplicateTitle;
  static String get duplicateUnavailableInfo => l10n.duplicateUnavailableInfo;
  static String get editNumber => l10n.editNumber;
  static String get eventAccepted => l10n.eventAccepted;
  static String get eventAcceptedCaption => l10n.eventAcceptedCaption;
  static String get eventCancelled => l10n.eventCancelled;
  static String get eventCompleted => l10n.eventCompleted;
  static String get eventCompletedCaption => l10n.eventCompletedCaption;
  static String get eventCreated => l10n.eventCreated;
  static String get eventCreatedCaption => l10n.eventCreatedCaption;
  static String get eventPrepStarted => l10n.eventPrepStarted;
  static String get eventPrepStartedCaption => l10n.eventPrepStartedCaption;
  static String get eventReady => l10n.eventReady;
  static String get eventReadyCaption => l10n.eventReadyCaption;
  static String get eventRejected => l10n.eventRejected;
  static String get eventStatusUpdate => l10n.eventStatusUpdate;
  static String get helpUnavailable => l10n.helpUnavailable;
  static String get homeActiveOrdersEmpty => l10n.homeActiveOrdersEmpty;
  static String get homeActiveOrdersTitle => l10n.homeActiveOrdersTitle;
  static String get homeCountCourier => l10n.homeCountCourier;
  static String get homeCountCourierUnavailable => l10n.homeCountCourierUnavailable;
  static String get homeCountIncoming => l10n.homeCountIncoming;
  static String get homeCountPreparing => l10n.homeCountPreparing;
  static String get homeCountReady => l10n.homeCountReady;
  static String get homeKpiCurrency => l10n.homeKpiCurrency;
  static String get homeKpiOrders => l10n.homeKpiOrders;
  static String get homeKpiOrdersUnit => l10n.homeKpiOrdersUnit;
  static String get homeKpiSales => l10n.homeKpiSales;
  static String get homeKpiUnavailable => l10n.homeKpiUnavailable;
  static String get homeNoMetrics => l10n.homeNoMetrics;
  static String get homeOpenOrder => l10n.homeOpenOrder;
  static String get homeOrderCountsTitle => l10n.homeOrderCountsTitle;
  static String get homeTitle => l10n.homeTitle;
  static String get homeTreatOrder => l10n.homeTreatOrder;
  static String get homeVerificationBody => l10n.homeVerificationBody;
  static String get homeVerificationTitle => l10n.homeVerificationTitle;
  static String get hoursExceptionsAdd => l10n.hoursExceptionsAdd;
  static String get hoursExceptionsBanner => l10n.hoursExceptionsBanner;
  static String get hoursExceptionsCancel => l10n.hoursExceptionsCancel;
  static String get hoursExceptionsClosed => l10n.hoursExceptionsClosed;
  static String get hoursExceptionsConflict => l10n.hoursExceptionsConflict;
  static String get hoursExceptionsDate => l10n.hoursExceptionsDate;
  static String get hoursExceptionsDateHint => l10n.hoursExceptionsDateHint;
  static String get hoursExceptionsDateRequired => l10n.hoursExceptionsDateRequired;
  static String get hoursExceptionsDateTaken => l10n.hoursExceptionsDateTaken;
  static String hoursExceptionsDeleteBody(String date) => l10n.hoursExceptionsDeleteBody(date);
  static String get hoursExceptionsDeleteConfirm => l10n.hoursExceptionsDeleteConfirm;
  static String get hoursExceptionsDeleteError => l10n.hoursExceptionsDeleteError;
  static String get hoursExceptionsDeleteTitle => l10n.hoursExceptionsDeleteTitle;
  static String get hoursExceptionsDeleted => l10n.hoursExceptionsDeleted;
  static String get hoursExceptionsEdit => l10n.hoursExceptionsEdit;
  static String get hoursExceptionsEmpty => l10n.hoursExceptionsEmpty;
  static String get hoursExceptionsHelpBody => l10n.hoursExceptionsHelpBody;
  static String get hoursExceptionsHelpOk => l10n.hoursExceptionsHelpOk;
  static String get hoursExceptionsHelpTitle => l10n.hoursExceptionsHelpTitle;
  static String get hoursExceptionsHours => l10n.hoursExceptionsHours;
  static String get hoursExceptionsIntervalsRequired => l10n.hoursExceptionsIntervalsRequired;
  static String get hoursExceptionsInvalid => l10n.hoursExceptionsInvalid;
  static String get hoursExceptionsLabel => l10n.hoursExceptionsLabel;
  static String get hoursExceptionsLabelHint => l10n.hoursExceptionsLabelHint;
  static String get hoursExceptionsLabelRequired => l10n.hoursExceptionsLabelRequired;
  static String get hoursExceptionsLoadError => l10n.hoursExceptionsLoadError;
  static String get hoursExceptionsMessage => l10n.hoursExceptionsMessage;
  static String get hoursExceptionsMessageHint => l10n.hoursExceptionsMessageHint;
  static String get hoursExceptionsNavSub => l10n.hoursExceptionsNavSub;
  static String get hoursExceptionsOpen => l10n.hoursExceptionsOpen;
  static String get hoursExceptionsSameDay => l10n.hoursExceptionsSameDay;
  static String get hoursExceptionsSave => l10n.hoursExceptionsSave;
  static String get hoursExceptionsSaveError => l10n.hoursExceptionsSaveError;
  static String get hoursExceptionsSaved => l10n.hoursExceptionsSaved;
  static String get hoursExceptionsStaffReadOnly => l10n.hoursExceptionsStaffReadOnly;
  static String get hoursExceptionsStatus => l10n.hoursExceptionsStatus;
  static String get hoursExceptionsTitle => l10n.hoursExceptionsTitle;
  static String get hoursExceptionsTo => l10n.hoursExceptionsTo;
  static String hoursExceptionsToday(String label) => l10n.hoursExceptionsToday(label);
  static String get hoursExceptionsTooMany => l10n.hoursExceptionsTooMany;
  static String get hoursExceptionsUpcoming => l10n.hoursExceptionsUpcoming;
  static String get hoursExceptionsWeeklyRequired => l10n.hoursExceptionsWeeklyRequired;
  static String get issuesApplicationTitle => l10n.issuesApplicationTitle;
  static String get issuesDocumentTitle => l10n.issuesDocumentTitle;
  static String get issuesFixHint => l10n.issuesFixHint;
  static String issuesRemaining(String count) {
    final n = int.tryParse(count) ?? 0;
    if (isArabic) {
      return n == 1
          ? 'نقطة واحدة متبقية للتصحيح'
          : '$count نقاط متبقية للتصحيح';
    }
    return n == 1
        ? '1 point restant à corriger'
        : '$count points restants à corriger';
  }
  static String get issuesReplaceDocument => l10n.issuesReplaceDocument;
  static String get issuesResolved => l10n.issuesResolved;
  static String get issuesTitle => l10n.issuesTitle;
  static String get languageApplied => l10n.languageApplied;
  static String get languageApply => l10n.languageApply;
  static String get languageBilingualTitle => l10n.languageBilingualTitle;
  static String get languageOptionArabic => l10n.languageOptionArabic;
  static String get languageOptionFrench => l10n.languageOptionFrench;
  static String get languagePreviewNote => l10n.languagePreviewNote;
  static String get languageSaveFailed => l10n.languageSaveFailed;
  static String get languageSettingsSubtitle => l10n.languageSettingsSubtitle;
  static String get languageSettingsTitle => l10n.languageSettingsTitle;
  static String get legalConsentHint => l10n.legalConsentHint;
  static String get legalConsentRequired => l10n.legalConsentRequired;
  static String get legalContentLink => l10n.legalContentLink;
  static String get legalDeclarationLabel => l10n.legalDeclarationLabel;
  static String get legalIncomplete => l10n.legalIncomplete;
  static String get legalLoadFailed => l10n.legalLoadFailed;
  static String get legalLoading => l10n.legalLoading;
  static String get legalRetry => l10n.legalRetry;
  static String get legalSectionBody => l10n.legalSectionBody;
  static String get legalSectionTitle => l10n.legalSectionTitle;
  static String get legalTermsLabel => l10n.legalTermsLabel;
  static String get legalVersionOutdated => l10n.legalVersionOutdated;
  static String legalVersionTag(String version) => l10n.legalVersionTag(version);
  static String get loading => l10n.loading;
  static String get logout => l10n.logout;
  static String get logoutActiveOrders => l10n.logoutActiveOrders;
  static String get logoutCancel => l10n.logoutCancel;
  static String get logoutConfirmAction => l10n.logoutConfirmAction;
  static String get logoutConfirmBody => l10n.logoutConfirmBody;
  static String get logoutConfirmTitle => l10n.logoutConfirmTitle;
  static String get logoutConnected => l10n.logoutConnected;
  static String get logoutDataPreserved => l10n.logoutDataPreserved;
  static String get logoutHandoverAdvice => l10n.logoutHandoverAdvice;
  static String get logoutStoreClosed => l10n.logoutStoreClosed;
  static String get logoutStoreOpen => l10n.logoutStoreOpen;
  static String get logoutStoreState => l10n.logoutStoreState;
  static String get logoutWarningTitle => l10n.logoutWarningTitle;
  static String get markReadyConfirm => l10n.markReadyConfirm;
  static String get markReadyPackingHint => l10n.markReadyPackingHint;
  static String get markReadyPackingTitle => l10n.markReadyPackingTitle;
  static String get merchantNameHint => l10n.merchantNameHint;
  static String get merchantNameLabel => l10n.merchantNameLabel;
  static String get navReveal => l10n.navReveal;
  static String get needBranchBody => l10n.needBranchBody;
  static String get needBranchTitle => l10n.needBranchTitle;
  static String get needHelp => l10n.needHelp;
  static String get networkError => l10n.networkError;
  static String get noMembershipBody => l10n.noMembershipBody;
  static String get noMembershipInvitationsCta => l10n.noMembershipInvitationsCta;
  static String get noMembershipTitle => l10n.noMembershipTitle;
  static String get notifPushStatusDenied => l10n.notifPushStatusDenied;
  static String get notifPushStatusDisabled => l10n.notifPushStatusDisabled;
  static String get notifPushStatusFailed => l10n.notifPushStatusFailed;
  static String get notifPushStatusPending => l10n.notifPushStatusPending;
  static String get notifPushStatusRegistered => l10n.notifPushStatusRegistered;
  static String get notifPushStatusTokenUnavailable => l10n.notifPushStatusTokenUnavailable;
  static String get notifSettingsCriticalWarning => l10n.notifSettingsCriticalWarning;
  static String get notifSettingsForeground => l10n.notifSettingsForeground;
  static String get notifSettingsInAppSection => l10n.notifSettingsInAppSection;
  static String get notifSettingsLockScreenNote => l10n.notifSettingsLockScreenNote;
  static String get notifSettingsNativePush => l10n.notifSettingsNativePush;
  static String get notifSettingsNativePushSub => l10n.notifSettingsNativePushSub;
  static String get notifSettingsOsDenied => l10n.notifSettingsOsDenied;
  static String get notifSettingsOsDeniedPush => l10n.notifSettingsOsDeniedPush;
  static String get notifSettingsOsEnabled => l10n.notifSettingsOsEnabled;
  static String get notifSettingsOsEnabledPush => l10n.notifSettingsOsEnabledPush;
  static String get notifSettingsOsNotAsked => l10n.notifSettingsOsNotAsked;
  static String get notifSettingsOsOpen => l10n.notifSettingsOsOpen;
  static String get notifSettingsPushBlocked => l10n.notifSettingsPushBlocked;
  static String get notifSettingsPushNotConfigured => l10n.notifSettingsPushNotConfigured;
  static String get notifSettingsPushSection => l10n.notifSettingsPushSection;
  static String get notifSettingsPushUnavailable => l10n.notifSettingsPushUnavailable;
  static String get notifSettingsSave => l10n.notifSettingsSave;
  static String get notifSettingsSaved => l10n.notifSettingsSaved;
  static String get notifSettingsScreenTitle => l10n.notifSettingsScreenTitle;
  static String get notifSettingsSound => l10n.notifSettingsSound;
  static String get notifSettingsSoundSection => l10n.notifSettingsSoundSection;
  static String get notifSettingsSwitchesNote => l10n.notifSettingsSwitchesNote;
  static String get notifSettingsTitle => l10n.notifSettingsTitle;
  static String get notifSettingsVibration => l10n.notifSettingsVibration;
  static String get notifSettingsVibrationSection => l10n.notifSettingsVibrationSection;
  static String get notificationsEmpty => l10n.notificationsEmpty;
  static String get notificationsFilterAll => l10n.notificationsFilterAll;
  static String get notificationsFilterOrders => l10n.notificationsFilterOrders;
  static String get notificationsJustNow => l10n.notificationsJustNow;
  static String get notificationsLoadError => l10n.notificationsLoadError;
  static String get notificationsMarkAllRead => l10n.notificationsMarkAllRead;
  static String get notificationsOpenDetails => l10n.notificationsOpenDetails;
  static String get notificationsOrderStale => l10n.notificationsOrderStale;
  static String get notificationsTitle => l10n.notificationsTitle;
  static String get notificationsToday => l10n.notificationsToday;
  static String get notificationsYesterday => l10n.notificationsYesterday;
  static String get onboardingHaveAccount => l10n.onboardingHaveAccount;
  static String get onboardingNext => l10n.onboardingNext;
  static String get onboardingPage1Body => l10n.onboardingPage1Body;
  static String get onboardingPage1Title => l10n.onboardingPage1Title;
  static String get onboardingPage2Body => l10n.onboardingPage2Body;
  static String get onboardingPage2Title => l10n.onboardingPage2Title;
  static String get onboardingPage3Body => l10n.onboardingPage3Body;
  static String get onboardingPage3Title => l10n.onboardingPage3Title;
  static String get onboardingPageSemantics => l10n.onboardingPageSemantics;
  static String get onboardingSaveFailed => l10n.onboardingSaveFailed;
  static String get onboardingSkip => l10n.onboardingSkip;
  static String get onboardingStart => l10n.onboardingStart;
  static String get openingHoursAddRange => l10n.openingHoursAddRange;
  static String get openingHoursAllDay => l10n.openingHoursAllDay;
  static String get openingHoursApply => l10n.openingHoursApply;
  static String get openingHoursClosed => l10n.openingHoursClosed;
  static String get openingHoursClosedNow => l10n.openingHoursClosedNow;
  static String get openingHoursCloses => l10n.openingHoursCloses;
  static String get openingHoursConflict => l10n.openingHoursConflict;
  static String get openingHoursDayClosedHint => l10n.openingHoursDayClosedHint;
  static String get openingHoursEditorHint => l10n.openingHoursEditorHint;
  static String get openingHoursEmpty => l10n.openingHoursEmpty;
  static String get openingHoursInfo => l10n.openingHoursInfo;
  static String get openingHoursInvalid => l10n.openingHoursInvalid;
  static String get openingHoursIssueOverlap => l10n.openingHoursIssueOverlap;
  static String get openingHoursIssueTooMany => l10n.openingHoursIssueTooMany;
  static String get openingHoursIssueZero => l10n.openingHoursIssueZero;
  static String get openingHoursLoadError => l10n.openingHoursLoadError;
  static String get openingHoursNextDay => l10n.openingHoursNextDay;
  static String get openingHoursNotConfigured => l10n.openingHoursNotConfigured;
  static String get openingHoursOpenNow => l10n.openingHoursOpenNow;
  static String get openingHoursOpens => l10n.openingHoursOpens;
  static String get openingHoursRemoveRange => l10n.openingHoursRemoveRange;
  static String get openingHoursSave => l10n.openingHoursSave;
  static String get openingHoursSaveError => l10n.openingHoursSaveError;
  static String get openingHoursSaved => l10n.openingHoursSaved;
  static String get openingHoursStaffReadOnly => l10n.openingHoursStaffReadOnly;
  static String get openingHoursTitle => l10n.openingHoursTitle;
  static String get openingHoursUsual => l10n.openingHoursUsual;
  static String get operationalActive => l10n.operationalActive;
  static String get operationalInactive => l10n.operationalInactive;
  static String get operationalSuspended => l10n.operationalSuspended;
  static String get orderAccept => l10n.orderAccept;
  static String get orderCancelledAck => l10n.orderCancelledAck;
  static String get orderCancelledByCustomer => l10n.orderCancelledByCustomer;
  static String get orderCancelledHeroBody => l10n.orderCancelledHeroBody;
  static String get orderChoosePrepTime => l10n.orderChoosePrepTime;
  static String get orderCurrentStatus => l10n.orderCurrentStatus;
  static String get orderCustomerLabel => l10n.orderCustomerLabel;
  static String get orderDeliveryAddress => l10n.orderDeliveryAddress;
  static String get orderDeliveryStatusTitle => l10n.orderDeliveryStatusTitle;
  static String get orderDetailCancelledTitle => l10n.orderDetailCancelledTitle;
  static String get orderDetailLoadError => l10n.orderDetailLoadError;
  static String get orderDetailTitle => l10n.orderDetailTitle;
  static String get orderDetailsTitle => l10n.orderDetailsTitle;
  static String get orderDriverAssigned => l10n.orderDriverAssigned;
  static String get orderDriverCall => l10n.orderDriverCall;
  static String get orderDriverCardTitle => l10n.orderDriverCardTitle;
  static String get orderDriverContactUnavailable => l10n.orderDriverContactUnavailable;
  static String get orderDriverEtaLabel => l10n.orderDriverEtaLabel;
  static String get orderDriverEtaUnavailable => l10n.orderDriverEtaUnavailable;
  static String get orderDriverStatusLabel => l10n.orderDriverStatusLabel;
  static String get orderFinanceCommissionUnavailable => l10n.orderFinanceCommissionUnavailable;
  static String get orderFinanceDeliveryFeeDisclaimer => l10n.orderFinanceDeliveryFeeDisclaimer;
  static String get orderFinanceDeliveryFeeNote => l10n.orderFinanceDeliveryFeeNote;
  static String get orderFinanceDiscount => l10n.orderFinanceDiscount;
  static String get orderFinanceGms => l10n.orderFinanceGms;
  static String get orderFinanceNet => l10n.orderFinanceNet;
  static String get orderFinanceNetCancelledNote => l10n.orderFinanceNetCancelledNote;
  static String get orderFinanceRestricted => l10n.orderFinanceRestricted;
  static String get orderFinanceTitle => l10n.orderFinanceTitle;
  static String get orderFulfillmentAccepted => l10n.orderFulfillmentAccepted;
  static String get orderFulfillmentIncoming => l10n.orderFulfillmentIncoming;
  static String get orderFulfillmentPreparing => l10n.orderFulfillmentPreparing;
  static String get orderFulfillmentReady => l10n.orderFulfillmentReady;
  static String get orderHandoffUnsupported => l10n.orderHandoffUnsupported;
  static String get orderHistoryEarlier => l10n.orderHistoryEarlier;
  static String get orderHistoryTitle => l10n.orderHistoryTitle;
  static String get orderHistoryToday => l10n.orderHistoryToday;
  static String get orderHistoryYesterday => l10n.orderHistoryYesterday;
  static String get orderIncomingBanner => l10n.orderIncomingBanner;
  static String get orderItemsTitle => l10n.orderItemsTitle;
  static String get orderItemsToPrepareTitle => l10n.orderItemsToPrepareTitle;
  static String get orderListAcceptNow => l10n.orderListAcceptNow;
  static String get orderListLate => l10n.orderListLate;
  static String get orderListMerchandiseLabel => l10n.orderListMerchandiseLabel;
  static String get orderMarkReady => l10n.orderMarkReady;
  static String get orderPaymentCod => l10n.orderPaymentCod;
  static String get orderPaymentElectronic => l10n.orderPaymentElectronic;
  static String get orderPaymentLabel => l10n.orderPaymentLabel;
  static String orderPaymentMethod(String method) => l10n.orderPaymentMethod(method);
  static String get orderQuickAccepted => l10n.orderQuickAccepted;
  static String get orderQuickAlreadyHandled => l10n.orderQuickAlreadyHandled;
  static String get orderQuickCheckFailed => l10n.orderQuickCheckFailed;
  static String get orderQuickNotAllowed => l10n.orderQuickNotAllowed;
  static String get orderQuickRejected => l10n.orderQuickRejected;
  static String get orderReadyBanner => l10n.orderReadyBanner;
  static String get orderReadyWaitingDelivery => l10n.orderReadyWaitingDelivery;
  static String get orderReasonLabel => l10n.orderReasonLabel;
  static String get orderReceivedAtLabel => l10n.orderReceivedAtLabel;
  static String get orderReferenceCopied => l10n.orderReferenceCopied;
  static String get orderReferenceCopy => l10n.orderReferenceCopy;
  static String get orderReferenceLabel => l10n.orderReferenceLabel;
  static String get orderReferenceShowFull => l10n.orderReferenceShowFull;
  static String get orderReject => l10n.orderReject;
  static String get orderRejectConfirm => l10n.orderRejectConfirm;
  static String get orderRejectHint => l10n.orderRejectHint;
  static String get orderRejectReasonLabel => l10n.orderRejectReasonLabel;
  static String get orderRejectTitle => l10n.orderRejectTitle;
  static String get orderRejectedByMerchant => l10n.orderRejectedByMerchant;
  static String get orderSegmentActive => l10n.orderSegmentActive;
  static String get orderSegmentHistory => l10n.orderSegmentHistory;
  static String get orderStartPreparation => l10n.orderStartPreparation;
  static String get orderStatusActive => l10n.orderStatusActive;
  static String get orderStatusCancelled => l10n.orderStatusCancelled;
  static String get orderStatusCompleted => l10n.orderStatusCompleted;
  static String get orderStatusConfirmed => l10n.orderStatusConfirmed;
  static String get orderStatusCreated => l10n.orderStatusCreated;
  static String get orderStatusFailed => l10n.orderStatusFailed;
  static String get orderSummaryTitle => l10n.orderSummaryTitle;
  static String get orderViewHistory => l10n.orderViewHistory;
  static String get ordersEmpty => l10n.ordersEmpty;
  static String get ordersEmptyAccepted => l10n.ordersEmptyAccepted;
  static String get ordersEmptyCancelled => l10n.ordersEmptyCancelled;
  static String get ordersEmptyCompleted => l10n.ordersEmptyCompleted;
  static String get ordersEmptyFailed => l10n.ordersEmptyFailed;
  static String get ordersEmptyIncoming => l10n.ordersEmptyIncoming;
  static String get ordersEmptyPreparing => l10n.ordersEmptyPreparing;
  static String get ordersEmptyReady => l10n.ordersEmptyReady;
  static String get ordersLoadError => l10n.ordersLoadError;
  static String get otpCooldownHint => l10n.otpCooldownHint;
  static String get otpSubtitle => l10n.otpSubtitle;
  static String get otpTitle => l10n.otpTitle;
  static String get permissionDenied => l10n.permissionDenied;
  static String get phoneHint => l10n.phoneHint;
  static String get phoneInvalid => l10n.phoneInvalid;
  static String get phoneLabel => l10n.phoneLabel;
  static String get phonePrefix => l10n.phonePrefix;
  static String get phoneSmsNote => l10n.phoneSmsNote;
  static String get phoneSubtitle => l10n.phoneSubtitle;
  static String get phoneTitle => l10n.phoneTitle;
  static String get pickupHandoffConfirmed => l10n.pickupHandoffConfirmed;
  static String get pickupHandoffInstruction1 => l10n.pickupHandoffInstruction1;
  static String get pickupHandoffInstruction2 => l10n.pickupHandoffInstruction2;
  static String get pickupHandoffLoadError => l10n.pickupHandoffLoadError;
  static String get pickupHandoffRegenerate => l10n.pickupHandoffRegenerate;
  static String get pickupHandoffRetry => l10n.pickupHandoffRetry;
  static String get pickupHandoffTitle => l10n.pickupHandoffTitle;
  static String get pickupHandoffWaiting => l10n.pickupHandoffWaiting;
  static String get prepAcceptTitle => l10n.prepAcceptTitle;
  static String get prepAddTime => l10n.prepAddTime;
  static String get prepBranchLabel => l10n.prepBranchLabel;
  static String prepClockOnDay(String day, String time) => l10n.prepClockOnDay(day, time);
  static String get prepConfirmAccept => l10n.prepConfirmAccept;
  static String get prepCurrentReady => l10n.prepCurrentReady;
  static String get prepCurrentShort => l10n.prepCurrentShort;
  static String get prepCustomEntry => l10n.prepCustomEntry;
  static String prepCustomRange(String min, String max) => l10n.prepCustomRange(min, max);
  static String get prepCustomTime => l10n.prepCustomTime;
  static String get prepEstimatedTitle => l10n.prepEstimatedTitle;
  static String get prepInProgress => l10n.prepInProgress;
  static String prepItemCount(String n) {
    final count = int.tryParse(n) ?? 0;
    if (isArabic) {
      return count <= 1 ? 'صنف واحد' : '$n أصناف';
    }
    return count <= 1 ? '1 article' : '$n articles';
  }
  static String get prepLateHint => l10n.prepLateHint;
  static String get prepMinutesCaption => l10n.prepMinutesCaption;
  static String get prepNewShort => l10n.prepNewShort;
  static String prepOnDay(String day) => l10n.prepOnDay(day);
  static String prepOriginalReady(String time) => l10n.prepOriginalReady(time);
  static String prepOriginalReadyLabel(String time) => l10n.prepOriginalReadyLabel(time);
  static String get prepReasonBusy => l10n.prepReasonBusy;
  static String get prepReasonFieldLabel => l10n.prepReasonFieldLabel;
  static String get prepReasonHint => l10n.prepReasonHint;
  static String get prepReasonLongPrep => l10n.prepReasonLongPrep;
  static String get prepReasonMissingIngredient => l10n.prepReasonMissingIngredient;
  static String get prepReasonOptional => l10n.prepReasonOptional;
  static String get prepReasonOther => l10n.prepReasonOther;
  static String get prepReasonShortcutsHint => l10n.prepReasonShortcutsHint;
  static String get prepRemainingTitle => l10n.prepRemainingTitle;
  static String get prepSecondsCaption => l10n.prepSecondsCaption;
  static String get prepUpdateAction => l10n.prepUpdateAction;
  static String get prepUpdateConfirm => l10n.prepUpdateConfirm;
  static String get prepUpdateTitle => l10n.prepUpdateTitle;
  static String get profileBranch => l10n.profileBranch;
  static String get profileBranchStatus => l10n.profileBranchStatus;
  static String get profileInfoReadonly => l10n.profileInfoReadonly;
  static String get profileMerchant => l10n.profileMerchant;
  static String get profileRole => l10n.profileRole;
  static String get profileRoleManager => l10n.profileRoleManager;
  static String get profileRoleOwner => l10n.profileRoleOwner;
  static String get profileRoleStaff => l10n.profileRoleStaff;
  static String get profileSectionAccount => l10n.profileSectionAccount;
  static String get profileSectionOps => l10n.profileSectionOps;
  static String get profileSectionPrefs => l10n.profileSectionPrefs;
  static String get profileSectionStore => l10n.profileSectionStore;
  static String get profileSectionSupport => l10n.profileSectionSupport;
  static String get profileSettingsTitle => l10n.profileSettingsTitle;
  static String get profileUnavailableItem => l10n.profileUnavailableItem;
  static String get pushOrderInaccessible => l10n.pushOrderInaccessible;
  static String get refresh => l10n.refresh;
  static String get refreshStatus => l10n.refreshStatus;
  static String get regAccountContinue => l10n.regAccountContinue;
  static String get regAccountTitle => l10n.regAccountTitle;
  static String get regActivityBody => l10n.regActivityBody;
  static String get regActivityTitle => l10n.regActivityTitle;
  static String get regAddressExactLabel => l10n.regAddressExactLabel;
  static String get regAddressGuidance => l10n.regAddressGuidance;
  static String get regAddressSection => l10n.regAddressSection;
  static String get regApprovedNext => l10n.regApprovedNext;
  static String get regBranchIncomplete => l10n.regBranchIncomplete;
  static String get regBranchNameFrLabel => l10n.regBranchNameFrLabel;
  static String get regBranchPhoneHint => l10n.regBranchPhoneHint;
  static String get regBranchPhoneLabel => l10n.regBranchPhoneLabel;
  static String get regCategoryReadonly => l10n.regCategoryReadonly;
  static String get regCategorySection => l10n.regCategorySection;
  static String get regChooseOnMap => l10n.regChooseOnMap;
  static String get regCommerceContext => l10n.regCommerceContext;
  static String get regConsentUnsupported => l10n.regConsentUnsupported;
  static String get regContactSection => l10n.regContactSection;
  static String get regContactTitle => l10n.regContactTitle;
  static String get regContinue => l10n.regContinue;
  static String get regCoordsConfirmHint => l10n.regCoordsConfirmHint;
  static String get regCoordsInvalid => l10n.regCoordsInvalid;
  static String get regCorrectionActionRequired => l10n.regCorrectionActionRequired;
  static String get regCorrectionDetails => l10n.regCorrectionDetails;
  static String get regCorrectionSubmit => l10n.regCorrectionSubmit;
  static String get regCorrectionTitle => l10n.regCorrectionTitle;
  static String get regDocsAppBar => l10n.regDocsAppBar;
  static String get regDocsBody => l10n.regDocsBody;
  static String get regDocsContinue => l10n.regDocsContinue;
  static String get regDocsContinueFinal => l10n.regDocsContinueFinal;
  static String get regDocsFormats => l10n.regDocsFormats;
  static String get regDocsPrivacy => l10n.regDocsPrivacy;
  static String get regDocsRequired => l10n.regDocsRequired;
  static String get regDocsTipFlash => l10n.regDocsTipFlash;
  static String get regDocsTipFrame => l10n.regDocsTipFrame;
  static String get regDocsTipLight => l10n.regDocsTipLight;
  static String get regDocsTipsTitle => l10n.regDocsTipsTitle;
  static String get regDocsTitle => l10n.regDocsTitle;
  static String get regEdit => l10n.regEdit;
  static String get regEmailUnsupported => l10n.regEmailUnsupported;
  static String get regEstablishmentBody => l10n.regEstablishmentBody;
  static String get regEstablishmentTitle => l10n.regEstablishmentTitle;
  static String get regFileTooLarge => l10n.regFileTooLarge;
  static String get regFileTypeUnsupported => l10n.regFileTypeUnsupported;
  static String get regIdentitySection => l10n.regIdentitySection;
  static String get regLegalIdUnsupported => l10n.regLegalIdUnsupported;
  static String get regLocationConfirm => l10n.regLocationConfirm;
  static String get regLocationConfirmed => l10n.regLocationConfirmed;
  static String get regLocationDenied => l10n.regLocationDenied;
  static String get regLocationDeniedForever => l10n.regLocationDeniedForever;
  static String get regLocationEdit => l10n.regLocationEdit;
  static String get regLocationGpsSuggestion => l10n.regLocationGpsSuggestion;
  static String get regLocationMoveHint => l10n.regLocationMoveHint;
  static String get regLocationPickerTitle => l10n.regLocationPickerTitle;
  static String get regLocationRequired => l10n.regLocationRequired;
  static String get regLocationServicesDisabled => l10n.regLocationServicesDisabled;
  static String get regLocationUnavailable => l10n.regLocationUnavailable;
  static String get regLocationUseGps => l10n.regLocationUseGps;
  static String get regMissingSteps => l10n.regMissingSteps;
  static String get regOperator => l10n.regOperator;
  static String get regOperatorHint => l10n.regOperatorHint;
  static String get regOperatorOpenInvitations => l10n.regOperatorOpenInvitations;
  static String get regOperatorUnsupported => l10n.regOperatorUnsupported;
  static String get regOwner => l10n.regOwner;
  static String get regOwnerHint => l10n.regOwnerHint;
  static String get regPickDocument => l10n.regPickDocument;
  static String get regPickerUnavailable => l10n.regPickerUnavailable;
  static String get regPickupPlace => l10n.regPickupPlace;
  static String get regPreviewLabel => l10n.regPreviewLabel;
  static String get regRejectionNoReason => l10n.regRejectionNoReason;
  static String get regReplaceDocument => l10n.regReplaceDocument;
  static String get regReviewBody => l10n.regReviewBody;
  static String get regReviewBranchTitle => l10n.regReviewBranchTitle;
  static String get regReviewDocsTitle => l10n.regReviewDocsTitle;
  static String get regReviewLocation => l10n.regReviewLocation;
  static String get regReviewTitle => l10n.regReviewTitle;
  static String get regRoleLabel => l10n.regRoleLabel;
  static String get regSelectRole => l10n.regSelectRole;
  static String get regStepOf => l10n.regStepOf;
  static String get regSubmit => l10n.regSubmit;
  static String get regTitle => l10n.regTitle;
  static String get regVerifiedPhone => l10n.regVerifiedPhone;
  static String get regVerifiedPhoneHint => l10n.regVerifiedPhoneHint;
  static String get rejectReasonClosingSoon => l10n.rejectReasonClosingSoon;
  static String get rejectReasonOther => l10n.rejectReasonOther;
  static String get rejectReasonProductUnavailable => l10n.rejectReasonProductUnavailable;
  static String get rejectReasonTilesHint => l10n.rejectReasonTilesHint;
  static String get rejectReasonTooBusy => l10n.rejectReasonTooBusy;
  static String get reportsAverageBasketMetric => l10n.reportsAverageBasketMetric;
  static String get reportsCancellationsMetric => l10n.reportsCancellationsMetric;
  static String get reportsCommission => l10n.reportsCommission;
  static String get reportsCommissionMixedRates => l10n.reportsCommissionMixedRates;
  static String get reportsCustomRangeTooLong => l10n.reportsCustomRangeTooLong;
  static String get reportsDailySummaryBreakdownTitle => l10n.reportsDailySummaryBreakdownTitle;
  static String get reportsDailySummaryCancellationMotifs => l10n.reportsDailySummaryCancellationMotifs;
  static String get reportsDailySummaryCancellationsKpi => l10n.reportsDailySummaryCancellationsKpi;
  static String get reportsDailySummaryCancelled => l10n.reportsDailySummaryCancelled;
  static String get reportsDailySummaryDelivered => l10n.reportsDailySummaryDelivered;
  static String get reportsDailySummaryEmpty => l10n.reportsDailySummaryEmpty;
  static String get reportsDailySummaryInProgress => l10n.reportsDailySummaryInProgress;
  static String get reportsDailySummaryLoadError => l10n.reportsDailySummaryLoadError;
  static String reportsDailySummaryOnTimePercent(String percent) => l10n.reportsDailySummaryOnTimePercent(percent);
  static String get reportsDailySummaryOnTimeRate => l10n.reportsDailySummaryOnTimeRate;
  static String get reportsDailySummaryOrdersKpi => l10n.reportsDailySummaryOrdersKpi;
  static String get reportsDailySummaryPrepAverage => l10n.reportsDailySummaryPrepAverage;
  static String get reportsDailySummaryPrepEfficiencyTitle => l10n.reportsDailySummaryPrepEfficiencyTitle;
  static String get reportsDailySummaryPrepKpi => l10n.reportsDailySummaryPrepKpi;
  static String get reportsDailySummarySalesKpi => l10n.reportsDailySummarySalesKpi;
  static String get reportsDailySummaryShortcut => l10n.reportsDailySummaryShortcut;
  static String get reportsDailySummaryTitle => l10n.reportsDailySummaryTitle;
  static String reportsDailySummaryTodayDate(String label) => l10n.reportsDailySummaryTodayDate(label);
  static String get reportsDailySummaryViewOrders => l10n.reportsDailySummaryViewOrders;
  static String get reportsDataUnavailable => l10n.reportsDataUnavailable;
  static String get reportsDataUnavailableShort => l10n.reportsDataUnavailableShort;
  static String get reportsDeletedProduct => l10n.reportsDeletedProduct;
  static String get reportsFinanceMissingSnapshot => l10n.reportsFinanceMissingSnapshot;
  static String get reportsFinanceRestricted => l10n.reportsFinanceRestricted;
  static String get reportsFinanceTitle => l10n.reportsFinanceTitle;
  static String get reportsFinanceUnavailable => l10n.reportsFinanceUnavailable;
  static String get reportsGrossSales => l10n.reportsGrossSales;
  static String get reportsLoadError => l10n.reportsLoadError;
  static String get reportsMerchantDiscount => l10n.reportsMerchantDiscount;
  static String get reportsMerchantNet => l10n.reportsMerchantNet;
  static String reportsOrderCount(String count) {
    final n = int.tryParse(count) ?? 0;
    if (isArabic) {
      return n == 1 ? 'طلب واحد' : '$count طلبات';
    }
    return n == 1 ? '1 commande' : '$count commandes';
  }
  static String get reportsOrdersMetric => l10n.reportsOrdersMetric;
  static String get reportsPeriodCustom => l10n.reportsPeriodCustom;
  static String get reportsPeriodMonth => l10n.reportsPeriodMonth;
  static String get reportsPeriodSelectorLabel => l10n.reportsPeriodSelectorLabel;
  static String get reportsPeriodToday => l10n.reportsPeriodToday;
  static String get reportsPeriodWeek => l10n.reportsPeriodWeek;
  static String get reportsPeriodYesterday => l10n.reportsPeriodYesterday;
  static String get reportsPrepTimeMetric => l10n.reportsPrepTimeMetric;
  static String get reportsPrepTimeNotTracked => l10n.reportsPrepTimeNotTracked;
  static String get reportsRankFirst => l10n.reportsRankFirst;
  static String get reportsRatingsCount => l10n.reportsRatingsCount;
  static String get reportsRatingsEmpty => l10n.reportsRatingsEmpty;
  static String get reportsRatingsTitle => l10n.reportsRatingsTitle;
  static String get reportsRatingsUnavailable => l10n.reportsRatingsUnavailable;
  static String get reportsRefundAdjustments => l10n.reportsRefundAdjustments;
  static String get reportsRefundsCompleted => l10n.reportsRefundsCompleted;
  static String get reportsRefundsNote => l10n.reportsRefundsNote;
  static String get reportsSalesLoadError => l10n.reportsSalesLoadError;
  static String get reportsSeeAll => l10n.reportsSeeAll;
  static String get reportsSettlementsEmpty => l10n.reportsSettlementsEmpty;
  static String get reportsSettlementsForbidden => l10n.reportsSettlementsForbidden;
  static String get reportsSettlementsTitle => l10n.reportsSettlementsTitle;
  static String get reportsSortOrders => l10n.reportsSortOrders;
  static String get reportsSortRevenue => l10n.reportsSortRevenue;
  static String get reportsTitle => l10n.reportsTitle;
  static String get reportsTopProductsEmpty => l10n.reportsTopProductsEmpty;
  static String get reportsTopProductsLoadError => l10n.reportsTopProductsLoadError;
  static String get reportsTopProductsScreenTitle => l10n.reportsTopProductsScreenTitle;
  static String get reportsTopProductsTitle => l10n.reportsTopProductsTitle;
  static String get reportsTopProductsUnavailable => l10n.reportsTopProductsUnavailable;
  static String get reportsTopSales => l10n.reportsTopSales;
  static String get reportsTrendEmpty => l10n.reportsTrendEmpty;
  static String reportsTrendSemantics(String orders, String gross) => l10n.reportsTrendSemantics(orders, gross);
  static String get reportsTrendTitle => l10n.reportsTrendTitle;
  static String get reportsTrendUnavailable => l10n.reportsTrendUnavailable;
  static String get resend => l10n.resend;
  static String get resendCode => l10n.resendCode;
  static String resendIn(String clock) => l10n.resendIn(clock);
  static String get restoreLoading => l10n.restoreLoading;
  static String get restoreOffline => l10n.restoreOffline;
  static String get restoreOtherAccount => l10n.restoreOtherAccount;
  static String get restoreRetry => l10n.restoreRetry;
  static String get restoreTitle => l10n.restoreTitle;
  static String get retry => l10n.retry;
  static String get save => l10n.save;
  static String get selectBranchSubtitle => l10n.selectBranchSubtitle;
  static String get selectBranchTitle => l10n.selectBranchTitle;
  static String get sellingUnitApply => l10n.sellingUnitApply;
  static String get sellingUnitCalloutBody => l10n.sellingUnitCalloutBody;
  static String get sellingUnitCalloutTitle => l10n.sellingUnitCalloutTitle;
  static String get sellingUnitCommon => l10n.sellingUnitCommon;
  static String get sellingUnitCustomHint => l10n.sellingUnitCustomHint;
  static String get sellingUnitCustomName => l10n.sellingUnitCustomName;
  static String get sellingUnitNone => l10n.sellingUnitNone;
  static String get sellingUnitNoneSub => l10n.sellingUnitNoneSub;
  static String get sellingUnitNotSet => l10n.sellingUnitNotSet;
  static String get sellingUnitPackaging => l10n.sellingUnitPackaging;
  static String get sellingUnitPreviewLabel => l10n.sellingUnitPreviewLabel;
  static String get sellingUnitPreviewNoPrice => l10n.sellingUnitPreviewNoPrice;
  static String get sellingUnitReadOnly => l10n.sellingUnitReadOnly;
  static String get sellingUnitTitle => l10n.sellingUnitTitle;
  static String get sessionExpired => l10n.sessionExpired;
  static String get settingsHelpCenter => l10n.settingsHelpCenter;
  static String get settingsLanguageRow => l10n.settingsLanguageRow;
  static String get settingsNotificationsOff => l10n.settingsNotificationsOff;
  static String get settingsProfileRow => l10n.settingsProfileRow;
  static String get settingsSupportSection => l10n.settingsSupportSection;
  static String get settingsTeamInvitationsRow => l10n.settingsTeamInvitationsRow;
  static String get settingsTeamRow => l10n.settingsTeamRow;
  static String get splashLegacyTagline => l10n.splashLegacyTagline;
  static String get splashTagline => l10n.splashTagline;
  static String get storeAddressBanner => l10n.storeAddressBanner;
  static String get storeAddressCommune => l10n.storeAddressCommune;
  static String get storeAddressConfirmMap => l10n.storeAddressConfirmMap;
  static String get storeAddressCoordsSection => l10n.storeAddressCoordsSection;
  static String get storeAddressDetailed => l10n.storeAddressDetailed;
  static String get storeAddressLocationSummary => l10n.storeAddressLocationSummary;
  static String get storeAddressPhone => l10n.storeAddressPhone;
  static String get storeAddressPhoneHint => l10n.storeAddressPhoneHint;
  static String get storeAddressPickupHints => l10n.storeAddressPickupHints;
  static String get storeAddressPublicContact => l10n.storeAddressPublicContact;
  static String get storeAddressSave => l10n.storeAddressSave;
  static String get storeAddressSaveError => l10n.storeAddressSaveError;
  static String get storeAddressSection => l10n.storeAddressSection;
  static String get storeAddressTitle => l10n.storeAddressTitle;
  static String get storeAddressWilaya => l10n.storeAddressWilaya;
  static String get storeCategoryClear => l10n.storeCategoryClear;
  static String get storeCategoryCleared => l10n.storeCategoryCleared;
  static String get storeCategoryEmpty => l10n.storeCategoryEmpty;
  static String get storeCategoryForbidden => l10n.storeCategoryForbidden;
  static String get storeCategoryInfo => l10n.storeCategoryInfo;
  static String get storeCategoryLoadError => l10n.storeCategoryLoadError;
  static String get storeCategoryNoMatch => l10n.storeCategoryNoMatch;
  static String get storeCategoryNotSet => l10n.storeCategoryNotSet;
  static String get storeCategoryReadOnly => l10n.storeCategoryReadOnly;
  static String get storeCategoryRestricted => l10n.storeCategoryRestricted;
  static String get storeCategorySave => l10n.storeCategorySave;
  static String get storeCategorySaveError => l10n.storeCategorySaveError;
  static String get storeCategorySaved => l10n.storeCategorySaved;
  static String get storeCategorySearch => l10n.storeCategorySearch;
  static String get storeCategorySubtitle => l10n.storeCategorySubtitle;
  static String get storeCategoryTitle => l10n.storeCategoryTitle;
  static String get storeCoverBindPartial => l10n.storeCoverBindPartial;
  static String get storeCoverHint => l10n.storeCoverHint;
  static String get storeCoverPick => l10n.storeCoverPick;
  static String get storeCoverRemoteUnavailable => l10n.storeCoverRemoteUnavailable;
  static String get storeCoverRemove => l10n.storeCoverRemove;
  static String get storeCoverReplace => l10n.storeCoverReplace;
  static String get storeCoverSave => l10n.storeCoverSave;
  static String get storeCoverSection => l10n.storeCoverSection;
  static String get storeCoverSectionHint => l10n.storeCoverSectionHint;
  static String get storeCoverTitle => l10n.storeCoverTitle;
  static String get storeCoverUploadError => l10n.storeCoverUploadError;
  static String get storeCustomerPreviewHint => l10n.storeCustomerPreviewHint;
  static String get storeCustomerPreviewTitle => l10n.storeCustomerPreviewTitle;
  static String get storeGeneralBranchName => l10n.storeGeneralBranchName;
  static String get storeGeneralBranchNameHint => l10n.storeGeneralBranchNameHint;
  static String get storeGeneralDescription => l10n.storeGeneralDescription;
  static String get storeGeneralDescriptionHint => l10n.storeGeneralDescriptionHint;
  static String get storeGeneralEmailInvalid => l10n.storeGeneralEmailInvalid;
  static String get storeGeneralForbidden => l10n.storeGeneralForbidden;
  static String get storeGeneralMerchantLocked => l10n.storeGeneralMerchantLocked;
  static String get storeGeneralMerchantName => l10n.storeGeneralMerchantName;
  static String get storeGeneralNameAr => l10n.storeGeneralNameAr;
  static String get storeGeneralNameArHint => l10n.storeGeneralNameArHint;
  static String get storeGeneralNameRequired => l10n.storeGeneralNameRequired;
  static String get storeGeneralPhoneElsewhere => l10n.storeGeneralPhoneElsewhere;
  static String get storeGeneralPreviewClosed => l10n.storeGeneralPreviewClosed;
  static String get storeGeneralPreviewOpen => l10n.storeGeneralPreviewOpen;
  static String get storeGeneralPreviewTitle => l10n.storeGeneralPreviewTitle;
  static String get storeGeneralPublicEmail => l10n.storeGeneralPublicEmail;
  static String get storeGeneralPublicEmailHint => l10n.storeGeneralPublicEmailHint;
  static String get storeGeneralReadOnly => l10n.storeGeneralReadOnly;
  static String get storeGeneralRestricted => l10n.storeGeneralRestricted;
  static String get storeGeneralSave => l10n.storeGeneralSave;
  static String get storeGeneralSaveError => l10n.storeGeneralSaveError;
  static String get storeGeneralSaved => l10n.storeGeneralSaved;
  static String get storeGeneralTitle => l10n.storeGeneralTitle;
  static String get storeLogoAdd => l10n.storeLogoAdd;
  static String get storeLogoBindPartial => l10n.storeLogoBindPartial;
  static String get storeLogoEdit => l10n.storeLogoEdit;
  static String get storeLogoEmpty => l10n.storeLogoEmpty;
  static String get storeLogoPending => l10n.storeLogoPending;
  static String get storeLogoRemoteUnavailable => l10n.storeLogoRemoteUnavailable;
  static String get storeLogoRemove => l10n.storeLogoRemove;
  static String get storeLogoRemoveError => l10n.storeLogoRemoveError;
  static String get storeLogoRemoved => l10n.storeLogoRemoved;
  static String get storeLogoSection => l10n.storeLogoSection;
  static String get storeLogoSectionHint => l10n.storeLogoSectionHint;
  static String get storeLogoTooLarge => l10n.storeLogoTooLarge;
  static String get storeLogoTooSmall => l10n.storeLogoTooSmall;
  static String get storeLogoUploadError => l10n.storeLogoUploadError;
  static String get storeMediaPartialSaved => l10n.storeMediaPartialSaved;
  static String get storeProfileAddress => l10n.storeProfileAddress;
  static String get storeProfileAddressSub => l10n.storeProfileAddressSub;
  static String get storeProfileAvailability => l10n.storeProfileAvailability;
  static String get storeProfileAvailabilitySub => l10n.storeProfileAvailabilitySub;
  static String get storeProfileCategory => l10n.storeProfileCategory;
  static String get storeProfileCategorySub => l10n.storeProfileCategorySub;
  static String get storeProfileCustomerPreview => l10n.storeProfileCustomerPreview;
  static String get storeProfileGeneral => l10n.storeProfileGeneral;
  static String get storeProfileGeneralSub => l10n.storeProfileGeneralSub;
  static String get storeProfileHours => l10n.storeProfileHours;
  static String get storeProfileHoursSub => l10n.storeProfileHoursSub;
  static String get storeProfileMedia => l10n.storeProfileMedia;
  static String get storeProfileMediaSub => l10n.storeProfileMediaSub;
  static String get storeProfileMediaUnavailable => l10n.storeProfileMediaUnavailable;
  static String get storeProfileNotifications => l10n.storeProfileNotifications;
  static String get storeProfileNotificationsSub => l10n.storeProfileNotificationsSub;
  static String get storeProfilePrep => l10n.storeProfilePrep;
  static String get storeProfilePrepUnavailable => l10n.storeProfilePrepUnavailable;
  static String get storeProfilePreviewUnavailable => l10n.storeProfilePreviewUnavailable;
  static String get storeProfileSettings => l10n.storeProfileSettings;
  static String get storeProfileSettingsSub => l10n.storeProfileSettingsSub;
  static String get storeProfileTitle => l10n.storeProfileTitle;
  static String get submitVerification => l10n.submitVerification;
  static String get submitVerificationUnavailable => l10n.submitVerificationUnavailable;
  static String get supportActiveTickets => l10n.supportActiveTickets;
  static String get supportBackToOrder => l10n.supportBackToOrder;
  static String get supportCenterTitle => l10n.supportCenterTitle;
  static String get supportComposeHint => l10n.supportComposeHint;
  static String get supportComposeTitle => l10n.supportComposeTitle;
  static String get supportContact => l10n.supportContact;
  static String get supportCustomerLabel => l10n.supportCustomerLabel;
  static String get supportDescriptionHint => l10n.supportDescriptionHint;
  static String get supportDescriptionLabel => l10n.supportDescriptionLabel;
  static String get supportFaqEmpty => l10n.supportFaqEmpty;
  static String get supportFaqLoadError => l10n.supportFaqLoadError;
  static String get supportFaqTitle => l10n.supportFaqTitle;
  static String get supportForbidden => l10n.supportForbidden;
  static String get supportLinkedOrder => l10n.supportLinkedOrder;
  static String get supportLoadError => l10n.supportLoadError;
  static String get supportMerchandiseLabel => l10n.supportMerchandiseLabel;
  static String get supportNewTicket => l10n.supportNewTicket;
  static String get supportNoMessages => l10n.supportNoMessages;
  static String get supportNoTickets => l10n.supportNoTickets;
  static String get supportOrderLabel => l10n.supportOrderLabel;
  static String get supportReplyError => l10n.supportReplyError;
  static String get supportReplyHint => l10n.supportReplyHint;
  static String get supportReplySend => l10n.supportReplySend;
  static String get supportReportTitle => l10n.supportReportTitle;
  static String get supportResolvedTickets => l10n.supportResolvedTickets;
  static String get supportSend => l10n.supportSend;
  static String get supportSendError => l10n.supportSendError;
  static String get supportSensitiveHint => l10n.supportSensitiveHint;
  static String get supportSentBodyNoRef => l10n.supportSentBodyNoRef;
  static String get supportSentTitle => l10n.supportSentTitle;
  static String get supportShort => l10n.supportShort;
  static String get supportSubjectHint => l10n.supportSubjectHint;
  static String get supportSubjectLabel => l10n.supportSubjectLabel;
  static String get supportSubjectRequired => l10n.supportSubjectRequired;
  static String get supportTeam => l10n.supportTeam;
  static String get supportTicketFinished => l10n.supportTicketFinished;
  static String get supportTicketLoadError => l10n.supportTicketLoadError;
  static String get supportTicketTitle => l10n.supportTicketTitle;
  static String get supportTopicLabel => l10n.supportTopicLabel;
  static String get supportTopicRequired => l10n.supportTopicRequired;
  static String get supportTopicsEmpty => l10n.supportTopicsEmpty;
  static String get supportTopicsHint => l10n.supportTopicsHint;
  static String get supportTopicsLoadError => l10n.supportTopicsLoadError;
  static String get supportTopicsTitle => l10n.supportTopicsTitle;
  /// Editable body prefixes for the legacy topic-tile compose sheet (D-G6).
  static String get supportTopicCatalogPrefix =>
      isArabic ? 'الكتالوج: ' : 'Catalogue : ';
  static String get supportTopicPaymentPrefix =>
      isArabic ? 'الدفع: ' : 'Paiement : ';
  static String get supportYou => l10n.supportYou;
  static String get suspendedBody => l10n.suspendedBody;
  static String get suspendedTitle => l10n.suspendedTitle;
  static String get switchBranch => l10n.switchBranch;
  static String get tabCatalog => l10n.tabCatalog;
  static String get tabHome => l10n.tabHome;
  static String get tabOrders => l10n.tabOrders;
  static String get tabProfile => l10n.tabProfile;
  static String get tabReports => l10n.tabReports;
  static String get teamAccept => l10n.teamAccept;
  static String get teamAcceptCodeInvalid => l10n.teamAcceptCodeInvalid;
  static String get teamAcceptCodeLabel => l10n.teamAcceptCodeLabel;
  static String get teamAcceptConfirm => l10n.teamAcceptConfirm;
  static String get teamAcceptTitle => l10n.teamAcceptTitle;
  static String get teamActiveMembers => l10n.teamActiveMembers;
  static String get teamCancelInvitation => l10n.teamCancelInvitation;
  static String teamCancelInviteBody(String phone) => l10n.teamCancelInviteBody(phone);
  static String get teamCancelInviteConfirm => l10n.teamCancelInviteConfirm;
  static String get teamCancelInviteTitle => l10n.teamCancelInviteTitle;
  static String get teamChangeRole => l10n.teamChangeRole;
  static String get teamCodeCopied => l10n.teamCodeCopied;
  static String get teamCodeCopy => l10n.teamCodeCopy;
  static String get teamCodeDone => l10n.teamCodeDone;
  static String get teamCodeRegeneratedNote => l10n.teamCodeRegeneratedNote;
  static String get teamCodeRegeneratedTitle => l10n.teamCodeRegeneratedTitle;
  static String get teamCodeTitle => l10n.teamCodeTitle;
  static String get teamEmptyInvitations => l10n.teamEmptyInvitations;
  static String get teamEmptyMembers => l10n.teamEmptyMembers;
  static String get teamErrorCodeInvalid => l10n.teamErrorCodeInvalid;
  static String get teamErrorConflict => l10n.teamErrorConflict;
  static String get teamErrorDuplicateInvite => l10n.teamErrorDuplicateInvite;
  static String get teamErrorDuplicateMember => l10n.teamErrorDuplicateMember;
  static String get teamErrorGeneric => l10n.teamErrorGeneric;
  static String get teamErrorInvalidInput => l10n.teamErrorInvalidInput;
  static String get teamErrorInviteExpired => l10n.teamErrorInviteExpired;
  static String get teamErrorInviteGone => l10n.teamErrorInviteGone;
  static String get teamErrorOwnerProtected => l10n.teamErrorOwnerProtected;
  static String get teamErrorPhoneMismatch => l10n.teamErrorPhoneMismatch;
  static String get teamErrorSelf => l10n.teamErrorSelf;
  static String teamExpiresOn(String date) => l10n.teamExpiresOn(date);
  static String get teamForbiddenBody => l10n.teamForbiddenBody;
  static String get teamForbiddenTitle => l10n.teamForbiddenTitle;
  static String get teamInvitationExpired => l10n.teamInvitationExpired;
  static String get teamInvitationsEmpty => l10n.teamInvitationsEmpty;
  static String get teamInvitationsHint => l10n.teamInvitationsHint;
  static String get teamInvitationsLoadError => l10n.teamInvitationsLoadError;
  static String get teamInvitationsTitle => l10n.teamInvitationsTitle;
  static String get teamInviteCancelled => l10n.teamInviteCancelled;
  static String get teamInviteCreate => l10n.teamInviteCreate;
  static String get teamInviteHint => l10n.teamInviteHint;
  static String get teamInviteMember => l10n.teamInviteMember;
  static String get teamInvitePhoneHelper => l10n.teamInvitePhoneHelper;
  static String get teamInvitePhoneHint => l10n.teamInvitePhoneHint;
  static String get teamInvitePhoneInvalid => l10n.teamInvitePhoneInvalid;
  static String get teamInvitePhoneLabel => l10n.teamInvitePhoneLabel;
  static String get teamInviteRoleLabel => l10n.teamInviteRoleLabel;
  static String get teamInviteTitle => l10n.teamInviteTitle;
  static String get teamKeep => l10n.teamKeep;
  static String get teamLoadError => l10n.teamLoadError;
  static String get teamOwnerBadge => l10n.teamOwnerBadge;
  static String get teamPendingInvitations => l10n.teamPendingInvitations;
  static String get teamPhoneUnavailable => l10n.teamPhoneUnavailable;
  static String get teamRegenerateCode => l10n.teamRegenerateCode;
  static String get teamRevoke => l10n.teamRevoke;
  static String get teamRevokeTitle => l10n.teamRevokeTitle;
  static String get teamRevoked => l10n.teamRevoked;
  static String teamRoleLine(String role) => l10n.teamRoleLine(role);
  static String get teamRoleManager => l10n.teamRoleManager;
  static String get teamRoleManagerHint => l10n.teamRoleManagerHint;
  static String get teamRoleOwner => l10n.teamRoleOwner;
  static String get teamRoleSave => l10n.teamRoleSave;
  static String get teamRoleSheetHint => l10n.teamRoleSheetHint;
  static String get teamRoleSheetTitle => l10n.teamRoleSheetTitle;
  static String get teamRoleStaff => l10n.teamRoleStaff;
  static String get teamRoleStaffHint => l10n.teamRoleStaffHint;
  static String get teamRoleUpdated => l10n.teamRoleUpdated;
  static String get teamRolesSummary => l10n.teamRolesSummary;
  static String get teamSelfBadge => l10n.teamSelfBadge;
  static String get teamStoreContext => l10n.teamStoreContext;
  static String get teamSummaryManager => l10n.teamSummaryManager;
  static String get teamSummaryOwner => l10n.teamSummaryOwner;
  static String get teamSummaryScope => l10n.teamSummaryScope;
  static String get teamSummaryStaff => l10n.teamSummaryStaff;
  static String get teamTitle => l10n.teamTitle;
  static String get temporaryClosure1h => l10n.temporaryClosure1h;
  static String get temporaryClosure30m => l10n.temporaryClosure30m;
  static String get temporaryClosureActionRequired => l10n.temporaryClosureActionRequired;
  static String get temporaryClosureConfirm => l10n.temporaryClosureConfirm;
  static String get temporaryClosureImageImpact => l10n.temporaryClosureImageImpact;
  static String get temporaryClosureImpactLead => l10n.temporaryClosureImpactLead;
  static String get temporaryClosureImpactNone => l10n.temporaryClosureImpactNone;
  static String get temporaryClosureImpactUnknown => l10n.temporaryClosureImpactUnknown;
  static String get temporaryClosureIndefinite => l10n.temporaryClosureIndefinite;
  static String get temporaryClosureManualReopenHint => l10n.temporaryClosureManualReopenHint;
  static String get temporaryClosureMessage => l10n.temporaryClosureMessage;
  static String get temporaryClosureMessageHint => l10n.temporaryClosureMessageHint;
  static String get temporaryClosureOptional => l10n.temporaryClosureOptional;
  static String get temporaryClosurePastTime => l10n.temporaryClosurePastTime;
  static String get temporaryClosurePickTime => l10n.temporaryClosurePickTime;
  static String get temporaryClosureReason => l10n.temporaryClosureReason;
  static String get temporaryClosureReopen => l10n.temporaryClosureReopen;
  static String get temporaryClosureStaffReadOnly => l10n.temporaryClosureStaffReadOnly;
  static String get temporaryClosureTitle => l10n.temporaryClosureTitle;
  static String get valueUnavailable => l10n.valueUnavailable;
  static String get verificationApprovedBody => l10n.verificationApprovedBody;
  static String get verificationApprovedTitle => l10n.verificationApprovedTitle;
  static String get verificationCorrectAndSubmit => l10n.verificationCorrectAndSubmit;
  static String get verificationDossierProgress => l10n.verificationDossierProgress;
  static String get verificationFinalStep => l10n.verificationFinalStep;
  static String get verificationFinalStepBody => l10n.verificationFinalStepBody;
  static String get verificationNeedHelp => l10n.verificationNeedHelp;
  static String get verificationPendingBody => l10n.verificationPendingBody;
  static String get verificationPendingTitle => l10n.verificationPendingTitle;
  static String get verificationReferenceFull => l10n.verificationReferenceFull;
  static String get verificationReferenceLabel => l10n.verificationReferenceLabel;
  static String get verificationRejectedBody => l10n.verificationRejectedBody;
  static String get verificationRejectedTitle => l10n.verificationRejectedTitle;
  static String get verificationRequestIdLabel => l10n.verificationRequestIdLabel;
  static String get verificationReviewStep => l10n.verificationReviewStep;
  static String get verificationReviewStepBody => l10n.verificationReviewStepBody;
  static String get verificationSubmittedStep => l10n.verificationSubmittedStep;
  static String get verificationTimelineTitle => l10n.verificationTimelineTitle;
  static String get verify => l10n.verify;

  // Complex helpers


  static String otpSentTo(String masked) =>
      isArabic ? 'تم إرسال الرمز إلى $masked' : 'Code envoyé au $masked';

  static String verificationRejectedGreeting(String merchantName) => isArabic
      ? 'مرحبًا، ملف $merchantName يحتاج إلى تصحيحات.'
      : 'Bonjour, le dossier de $merchantName nécessite des corrections.';

  static String homeLastSync(String hhmm) =>
      isArabic ? 'آخر مزامنة: $hhmm' : 'Dernière sync : $hhmm';

  static String supportSentBody(String ref) => isArabic
      ? 'تم إرسال تذكرتك $ref إلى فريق SpeedyGo.'
      : 'Votre ticket $ref a été transmis à l’équipe SpeedyGo.';

  static String supportShowingLatest(int shown, int total) => isArabic
      ? 'عرض أحدث $shown تذاكر من أصل $total.'
      : '$shown tickets les plus récents sur $total.';

  static String supportCreated(String reference) =>
      isArabic ? 'تم إرسال التذكرة: $reference' : 'Ticket envoyé : $reference';

  static String orderDeliveredOn(String when) =>
      isArabic ? 'تم التسليم في $when' : 'Livrée le $when';
  static String orderCompletedOn(String when) =>
      isArabic ? 'اكتمل في $when' : 'Terminée le $when';
  static String orderReadySince(String hhmm) =>
      isArabic ? 'جاهز منذ $hhmm' : 'Prête depuis $hhmm';
  static String orderListReadyAt(String hhmm) =>
      isArabic ? 'جاهز نحو $hhmm' : 'Prête vers $hhmm';
  static String orderCreatedAt(String when) =>
      isArabic ? 'أُنشئ في $when' : 'Créée le $when';
  static String orderConfirmedAt(String when) =>
      isArabic ? 'تم التأكيد في $when' : 'Confirmée le $when';
  static String orderCancelledAt(String when) =>
      isArabic ? 'أُلغي في $when' : 'Annulée le $when';
  static String orderCreatedShort(String when) =>
      isArabic ? 'أُنشئ $when' : 'Créée $when';
  static String orderFinanceCommission(String amount) =>
      isArabic ? 'العمولة: $amount' : 'Commission : $amount';

  static String orderDriverSearchStarted(String when) =>
      isArabic ? 'بدأ البحث عن سائق في $when' : 'Recherche livreur démarrée à $when';
  static String orderDriverSearchStartedAt(String hhmm) =>
      isArabic ? 'بدأ البحث عند $hhmm' : 'Recherche démarrée à $hhmm';
  static String orderDriverEtaEstimate(String minutes) =>
      isArabic ? 'وصول تقديري خلال $minutes د' : 'ETA estimée : $minutes min';
  static String reportsLastUpdated(String when) =>
      isArabic ? 'آخر تحديث: $when' : 'Dernière mise à jour : $when';
  static String reportsSyncedAt(String when) =>
      isArabic ? 'آخر مزامنة: $when' : 'Synchronisé à $when';
  static String reportsUnitCount(int count) {
    if (isArabic) {
      return count == 1 ? 'وحدة واحدة' : '$count وحدات';
    }
    return count == 1 ? '1 unité' : '$count unités';
  }
  static String catalogCategoriesCount(int count) =>
      isArabic ? '$count فئة' : '$count catégorie${count == 1 ? '' : 's'}';
  static String catalogBulkSelected(int count) =>
      isArabic ? '$count محدد' : '$count sélectionné${count == 1 ? '' : 's'}';
  static String catalogChoiceRange(int min, int max) =>
      isArabic ? 'من $min إلى $max' : 'De $min à $max';
  static String regCorrectionIntro(String merchantName) => isArabic
      ? 'صحّح العناصر المطلوبة ثم أعد الإرسال. سيتم تفعيل مؤسستك $merchantName بعد التحقق.'
      : 'Corrigez les éléments nécessaires puis soumettez à nouveau. Votre établissement $merchantName sera activé après validation.';
  static String issuesDocumentConcerned(String label) =>
      isArabic ? 'المستند المعني: $label' : 'Pièce concernée : $label';
  static String teamCodeInstruction(String phone) => isArabic
      ? 'لا ترسل SpeedyGo رسالة SMS أو بريدًا. انسخ هذا الرمز وسلّمه بنفسك إلى $phone. لن يُعرض مرة أخرى.'
      : 'Aucun SMS ni e-mail n’est émis par SpeedyGo. Copiez ce code et transmettez-le vous-même à $phone. Il ne sera plus affiché.';
  static String teamRevokeBody(String phone) => isArabic
      ? 'سيفقد $phone الوصول إلى هذا المتجر وتُغلق جلساته. حساب SpeedyGo الخاص به لا يُحذف.'
      : '$phone perdra l’accès à ce commerce et ses sessions seront fermées. Son compte SpeedyGo n’est pas supprimé.';
  static String teamAccepted(String merchantName) => isArabic
      ? 'تم قبول الدعوة. لديك الآن صلاحية الوصول إلى $merchantName.'
      : 'Invitation acceptée. Vous avez maintenant accès à $merchantName.';
  static String temporaryClosureImpactTail(int count) {
    if (isArabic) {
      return count == 1
          ? ' سيُبقى ويجب تحضيره.'
          : ' ستُبقى ويجب تحضيرها.';
    }
    return count == 1
        ? ' sera maintenue et doit être préparée.'
        : ' seront maintenues et doivent être préparées.';
  }

  static String supportStatus(String code) {
    if (isArabic) {
      return switch (code) {
        'open' || 'OPEN' => 'مفتوح',
        'inProgress' || 'IN_PROGRESS' => 'قيد المعالجة',
        'waitingCustomer' || 'WAITING_CUSTOMER' => 'بانتظار الرد',
        'resolved' || 'RESOLVED' => 'تم الحل',
        'closed' || 'CLOSED' => 'مغلق',
        _ => 'حالة غير معروفة',
      };
    }
    return switch (code) {
      'open' || 'OPEN' => 'Ouvert',
      'inProgress' || 'IN_PROGRESS' => 'En cours',
      'waitingCustomer' || 'WAITING_CUSTOMER' => 'Réponse attendue',
      'resolved' || 'RESOLVED' => 'Résolu',
      'closed' || 'CLOSED' => 'Fermé',
      _ => 'Statut inconnu',
    };
  }

  static String reportsSettlementStatus(String code) {
    if (isArabic) {
      return switch (code.toUpperCase()) {
        'DRAFT' => 'مسودة',
        'FINALIZED' => 'نهائي',
        _ => 'حالة غير معروفة',
      };
    }
    return switch (code.toUpperCase()) {
      'DRAFT' => 'Brouillon',
      'FINALIZED' => 'Finalisé',
      _ => 'Statut inconnu',
    };
  }

  static String _ddMmYyyy(DateTime at) {
    final l = at.toUtc().add(const Duration(hours: 1));
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year}';
  }

  static String supportDate(DateTime at) => _ddMmYyyy(at);

  static String supportUpdated(DateTime updatedAt, DateTime now) {
    final diff = now.difference(updatedAt);
    if (isArabic) {
      if (diff.inMinutes < 1) return 'تم التحديث للتو';
      if (diff.inMinutes < 60) return 'تم التحديث منذ ${diff.inMinutes} د';
      if (diff.inHours < 24) return 'تم التحديث منذ ${diff.inHours} س';
      return 'تم التحديث في ${_ddMmYyyy(updatedAt)}';
    }
    if (diff.inMinutes < 1) return 'Mis à jour à l’instant';
    if (diff.inMinutes < 60) return 'Mis à jour il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Mis à jour il y a ${diff.inHours} h';
    return 'Mis à jour le ${_ddMmYyyy(updatedAt)}';
  }

  static String prepSelectHint(int itemCount) {
    if (isArabic) {
      if (itemCount <= 1) return 'حدد الوقت اللازم لتحضير المنتج.';
      return 'حدد الوقت اللازم لتحضير الـ $itemCount منتجات.';
    }
    if (itemCount <= 1) {
      return 'Sélectionnez le temps nécessaire pour préparer l’article.';
    }
    return 'Sélectionnez le temps nécessaire pour préparer les $itemCount articles.';
  }

  static String durationFr(int minutes) {
    if (minutes < 60) return isArabic ? '$minutes د' : '$minutes min';
    final days = minutes ~/ (24 * 60);
    final hours = (minutes % (24 * 60)) ~/ 60;
    final rest = minutes % 60;
    if (isArabic) {
      if (days > 0) return hours > 0 ? '$days ي $hours س' : '$days ي';
      return rest > 0 ? '$hours س $rest د' : '$hours س';
    }
    if (days > 0) return hours > 0 ? '$days j $hours h' : '$days j';
    return rest > 0 ? '$hours h $rest min' : '$hours h';
  }

  static String prepLateBy(int minutes) {
    if (minutes <= 0) return isArabic ? 'متأخر' : 'En retard';
    return isArabic
        ? 'متأخر ${durationFr(minutes)}'
        : '${durationFr(minutes)} de retard';
  }

  static String availabilityLastUpdate(DateTime updatedAt, DateTime now) {
    final minutes = now.difference(updatedAt).inMinutes;
    if (isArabic) {
      final String when;
      if (minutes < 1) {
        when = 'الآن';
      } else if (minutes < 60) {
        when = 'منذ $minutes د';
      } else if (minutes < 24 * 60) {
        when = 'منذ ${minutes ~/ 60} س';
      } else {
        when = 'في ${_ddMmYyyy(updatedAt)}';
      }
      return 'آخر تحديث: $when';
    }
    final String when;
    if (minutes < 1) {
      when = 'à l’instant';
    } else if (minutes < 60) {
      when = 'il y a $minutes min';
    } else if (minutes < 24 * 60) {
      when = 'il y a ${minutes ~/ 60} h';
    } else {
      when = 'le ${_ddMmYyyy(updatedAt)}';
    }
    return 'Dernière mise à jour : $when';
  }

  static String availabilityCloseWarningBody(int? count) {
    if (isArabic) {
      if (count == null) {
        return 'سيتم رفض جميع الطلبات الجديدة. يجب متابعة معالجة الطلبات النشطة.';
      }
      if (count == 0) {
        return 'سيتم رفض جميع الطلبات الجديدة. لا توجد طلبات نشطة قيد المعالجة.';
      }
      if (count == 1) {
        return 'سيتم رفض جميع الطلبات الجديدة. يجب متابعة معالجة الطلب النشط.';
      }
      return 'سيتم رفض جميع الطلبات الجديدة. يجب متابعة معالجة الـ $count طلبات النشطة.';
    }
    if (count == null) {
      return 'Toutes les nouvelles commandes seront rejetées. Les commandes actives doivent toujours être traitées.';
    }
    if (count == 0) {
      return 'Toutes les nouvelles commandes seront rejetées. Aucune commande active en cours.';
    }
    return 'Toutes les nouvelles commandes seront rejetées. Vous devez toujours traiter '
        '${count == 1 ? 'la commande active' : 'les $count commandes actives'}.';
  }

  static String availabilityActiveOrders(int count) {
    if (isArabic) {
      return count == 1 ? 'طلب واحد قيد التنفيذ' : '$count طلبات قيد التنفيذ';
    }
    return count == 1 ? '1 commande en cours' : '$count commandes en cours';
  }

  static String temporaryClosureImpactCount(int count) {
    if (isArabic) {
      return count == 1 ? 'الطلب الجاري' : 'الـ $count طلبات الجارية';
    }
    return count == 1 ? 'La commande en cours' : 'Les $count commandes en cours';
  }

  static String reportsTotalArticles(int count) {
    if (isArabic) {
      return count == 1 ? 'المجموع: منتج واحد' : 'المجموع: $count منتجات';
    }
    return count == 1 ? 'Total : 1 article' : 'Total : $count articles';
  }

  static String catalogMaxSelections(int n) {
    if (isArabic) {
      return n == 1 ? 'اختيار واحد كحد أقصى' : 'حد أقصى $n اختيارات';
    }
    return n == 1 ? 'Maximum 1 sélection' : 'Maximum $n sélections';
  }


  static String prepMinutesLabel(int minutes) =>
      isArabic ? '$minutes د' : '$minutes min';

  static String catalogArticles(int n) {
    if (isArabic) {
      return n <= 1 ? '$n منتج' : '$n منتجات';
    }
    return n <= 1 ? '$n article' : '$n articles';
  }

  static String temporaryClosureAt({
    required bool today,
    required String hhmm,
  }) {
    if (isArabic) {
      return '${today ? 'اليوم' : 'غدًا'} في $hhmm';
    }
    return '${today ? 'Aujourd’hui' : 'Demain'} à $hhmm';
  }

  static String logoutWarningBody({
    required bool hasActiveOrders,
    required bool storeOpen,
  }) {
    if (isArabic) {
      return switch ((hasActiveOrders, storeOpen)) {
        (true, true) =>
          'لديك طلبات نشطة والمتجر مفتوح حاليًا.',
        (true, false) => 'لديك طلبات نشطة.',
        _ => 'المتجر مفتوح حاليًا.',
      };
    }
    return switch ((hasActiveOrders, storeOpen)) {
      (true, true) =>
        'Vous avez des commandes actives et le magasin est actuellement ouvert.',
      (true, false) => 'Vous avez des commandes actives.',
      _ => 'Le magasin est actuellement ouvert.',
    };
  }


  static String catalogGroupsCount(int n) {
    if (isArabic) {
      if (n <= 0) return "لا توجد مجموعات";
      if (n == 1) return "مجموعة";
      return "$n مجموعات";
    }
    if (n <= 0) return "Aucun groupe";
    if (n == 1) return "1 groupe";
    return "$n groupes";
  }

  static String prepScheduledAtLocal(String time) => isArabic
      ? 'الوقت المتوقع: $time (التوقيت المحلي)'
      : 'Heure prévue : $time (heure locale)';

  static String prepScheduledOnLocal(String day, String time) => isArabic
      ? 'الوقت المتوقع: يوم $day عند $time (التوقيت المحلي)'
      : 'Heure prévue : le $day à $time (heure locale)';

  static String prepNewEstimate(String from, String to, int add) => isArabic
      ? "تقدير جديد: $to بدلًا من $from، بزيادة $add د"
      : "Nouvelle estimation : $to au lieu de $from, plus $add minutes";

  static String prepSpokenClock(String time, String? day) {
    if (day == null || day.isEmpty) return time;
    return isArabic ? "$time يوم $day" : "$time le $day";
  }

  static String reportsCommissionWithRate(String rate) =>
      isArabic ? 'عمولة SpeedyGo ($rate)' : 'Commission SpeedyGo ($rate)';

  static String reportsDailySummaryMinutes(int minutes) =>
      isArabic ? "$minutes د" : "$minutes min";


  static String errorForCode(String? code) {
    switch (code) {
      case 'AUTH_INVALID_OTP':
        return isArabic ? 'رمز غير صحيح.' : 'Code incorrect.';
      case 'AUTH_OTP_EXPIRED':
        return isArabic
            ? 'انتهت صلاحية الرمز. اطلب رمزًا جديدًا.'
            : 'Code expiré. Demandez-en un nouveau.';
      case 'AUTH_OTP_ATTEMPTS_EXCEEDED':
        return isArabic
            ? 'محاولات كثيرة. اطلب رمزًا جديدًا.'
            : 'Trop de tentatives. Demandez un nouveau code.';
      case 'AUTH_RATE_LIMITED':
        return isArabic
            ? 'طلبات كثيرة. أعد المحاولة لاحقًا.'
            : 'Trop de demandes. Réessayez plus tard.';
      case 'AUTH_ACCOUNT_SUSPENDED':
      case 'AUTH_ACCOUNT_DISABLED':
        return isArabic ? 'الحساب غير متاح.' : 'Compte indisponible.';
      case 'AUTH_INVALID_TOKEN':
      case 'AUTH_SESSION_REVOKED':
      case 'AUTH_SESSION_EXPIRED':
        return sessionExpired;
      case 'MERCHANT_ROLE_FORBIDDEN':
        return permissionDenied;
      case 'MERCHANT_STATUS_RESTRICTED':
        return accessRestrictedBody;
      case 'MERCHANT_NOT_FOUND':
        return isArabic ? 'التجارة غير موجودة.' : 'Commerce introuvable.';
      case 'MERCHANT_ORDER_NOT_FOUND':
        return isArabic ? 'الطلب غير موجود.' : 'Commande introuvable.';
      case 'MERCHANT_ORDER_ALREADY_ACCEPTED':
        return isArabic
            ? 'تم قبول هذا الطلب مسبقًا.'
            : 'Cette commande a déjà été acceptée.';
      case 'MERCHANT_ORDER_NOT_REJECTABLE':
        return isArabic
            ? 'لم يعد بالإمكان رفض هذا الطلب.'
            : 'Cette commande ne peut plus être refusée.';
      case 'MERCHANT_ORDER_INVALID_TRANSITION':
        return isArabic
            ? 'هذا الإجراء لم يعد ممكنًا للحالة الحالية.'
            : 'Cette action n’est plus possible pour l’état actuel.';
      case 'MERCHANT_ORDER_PAYMENT_NOT_READY':
        return isArabic
            ? 'الدفع غير جاهز بعد لبدء التحضير.'
            : 'Le paiement n’est pas encore prêt pour démarrer la préparation.';
      case 'MERCHANT_ORDER_PREP_ESTIMATE_INVALID':
        return isArabic
            ? 'وقت التحضير غير صالح.'
            : 'Temps de préparation invalide.';
      case 'MERCHANT_ORDER_PREP_ESTIMATE_CONFLICT':
        return isArabic
            ? 'تغيّر التقدير. حدّث ثم أعد المحاولة.'
            : 'L’estimation a changé. Actualisez puis réessayez.';
      case 'MERCHANT_ORDER_PREP_ESTIMATE_NOT_ALLOWED':
        return isArabic
            ? 'لم يعد تحديث الوقت ممكنًا لهذه الحالة.'
            : 'La mise à jour du temps n’est plus possible pour cet état.';
      case 'MERCHANT_VERIFICATION_NOT_READY':
        return submitVerificationUnavailable;
      case 'LEGAL_ACCEPTANCE_REQUIRED':
        return legalConsentRequired;
      case 'LEGAL_VERSION_OUTDATED':
        return legalVersionOutdated;
      default:
        return networkError;
    }
  }
}
