import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_merchant_app/app/app.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/network/api_config.dart';
import 'package:speedygo_merchant_app/core/network/token_refresher.dart';
import 'package:speedygo_merchant_app/core/storage/approval_notice_store.dart';
import 'package:speedygo_merchant_app/core/storage/session_store.dart';
import 'package:speedygo_merchant_app/features/access/application/access_controller.dart';
import 'package:speedygo_merchant_app/features/access/data/geo_models.dart';
import 'package:speedygo_merchant_app/features/access/data/merchant_api.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_controller.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_providers.dart';
import 'package:speedygo_merchant_app/features/auth/application/session_state.dart';
import 'package:speedygo_merchant_app/features/auth/data/auth_api.dart';
import 'package:speedygo_merchant_app/features/auth/data/models.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/orders/application/orders_controller.dart';
import 'package:speedygo_merchant_app/features/orders/data/order_models.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';
import 'package:speedygo_merchant_app/features/store/data/classification_models.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';
import 'package:speedygo_merchant_app/features/support/data/support_models.dart';
import 'package:speedygo_merchant_app/features/team/data/team_models.dart';

class FakeAuthApi implements AuthClient {
  FakeAuthApi({
    this.requestOtpHandler,
    this.verifyOtpHandler,
    this.meHandler,
    this.refreshHandler,
  });

  Future<void> Function(String)? requestOtpHandler;
  Future<TokenPair> Function(OtpVerifyBody)? verifyOtpHandler;
  Future<AuthMe> Function()? meHandler;
  Future<TokenPair> Function(String)? refreshHandler;
  int requestOtpCalls = 0;
  int verifyOtpCalls = 0;

  @override
  Future<void> requestOtp(String identifier) async {
    requestOtpCalls += 1;
    if (requestOtpHandler != null) {
      await requestOtpHandler!(identifier);
      return;
    }
  }

  @override
  Future<TokenPair> verifyOtp(OtpVerifyBody body) async {
    verifyOtpCalls += 1;
    if (verifyOtpHandler != null) return verifyOtpHandler!(body);
    return const TokenPair(
      accessToken: 'access',
      refreshToken: 'refresh-token-value',
      expiresIn: 900,
      tokenType: 'Bearer',
    );
  }

  @override
  Future<TokenPair> refresh(String refreshToken) async {
    if (refreshHandler != null) return refreshHandler!(refreshToken);
    return TokenPair(
      accessToken: 'access-rotated',
      refreshToken: refreshToken,
      expiresIn: 900,
      tokenType: 'Bearer',
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthMe> me() async {
    if (meHandler != null) return meHandler!();
    return const AuthMe(
      accountId: 'acc-1',
      phone: '+213550000001',
      status: 'ACTIVE',
      hasMerchantMembership: true,
    );
  }
}

class FakeMerchantApi implements MerchantClient {
  FakeMerchantApi({
    this.meHandler,
    this.ordersHandler,
    this.orderDetailHandler,
    this.catalogBootstrapHandler,
    this.categoriesHandler,
    this.productsHandler,
    this.updateAvailabilityHandler,
    this.ratingsHandler,
    this.settlementsHandler,
    this.availabilityHandler,
    this.salesSummaryHandler,
    this.topProductsHandler,
    this.dailySummaryHandler,
  });

  Future<MerchantSalesSummary> Function({
    required String merchantId,
    required ReportPeriodSelection period,
    String? branchId,
  })?
  salesSummaryHandler;
  Future<MerchantTopProducts> Function({
    required String merchantId,
    required ReportPeriodSelection period,
    String? branchId,
    required TopProductSort sort,
    required int limit,
  })?
  topProductsHandler;
  Future<MerchantDailySummary> Function({
    required String merchantId,
    String? date,
    String? branchId,
  })?
  dailySummaryHandler;

  Future<MerchantMe> Function()? meHandler;
  Future<MerchantOrderListPage> Function({
    required String merchantId,
    String? branchId,
    String? orderStatus,
    String? fulfillmentStatus,
    int limit,
    int offset,
  })?
  ordersHandler;
  Future<MerchantOrderDetail> Function({
    required String merchantId,
    required String orderId,
  })?
  orderDetailHandler;
  Future<CatalogBootstrap> Function({
    required String merchantId,
    required String branchId,
  })?
  catalogBootstrapHandler;
  Future<List<CatalogCategory>> Function({
    required String merchantId,
    required String branchId,
  })?
  categoriesHandler;
  Future<List<CatalogProduct>> Function({
    required String merchantId,
    required String branchId,
    String? categoryId,
  })?
  productsHandler;
  Future<CatalogProduct> Function({
    required String merchantId,
    required String productId,
    required bool available,
  })?
  updateAvailabilityHandler;
  Future<MerchantRatingSummary> Function({required String merchantId})?
  ratingsHandler;
  Future<List<MerchantSettlementSummary>> Function({
    required String merchantId,
  })?
  settlementsHandler;
  Future<OpeningHoursSchedule> Function({
    required String merchantId,
    required String branchId,
  })?
  openingHoursHandler;
  Future<List<MerchantNotificationItem>> Function()? notificationsHandler;
  Future<BranchAvailabilityState> Function({
    required String merchantId,
    required String branchId,
  })?
  availabilityHandler;
  int unreadCount = 0;
  Future<MerchantDeliverySummary?> Function({required String orderId})?
  deliveryHandler;
  Future<MerchantPickupHandoff> Function({required String orderId})?
  pickupHandoffHandler;
  Future<MerchantPickupHandoff> Function({required String orderId})?
  regeneratePickupHandoffHandler;
  Future<String> Function({required String body, String? orderId})?
  supportTicketHandler;
  final List<Map<String, String?>> supportTickets = [];
  final List<String> orderCalls = [];
  final List<String> mutationCalls = [];
  String? lastCreatedName;
  final Map<String, List<String>> uploadedTypes = {};
  MerchantOrderDetail? mutableDetail;
  int acceptCalls = 0;
  bool acceptThrowsNetwork = false;
  bool acceptThrowsConflict = false;

  @override
  Future<MerchantMe> me() async {
    if (meHandler != null) return meHandler!();
    return const MerchantMe(merchantMembershipExists: false, memberships: []);
  }

  @override
  Future<MerchantMembership> createProfile({required String name}) async {
    lastCreatedName = name;
    return membership(
      status: 'PENDING_REVIEW',
      approved: false,
      operationalReady: false,
      merchantId: 'm-new',
    ).copyWithName(name);
  }

  @override
  Future<MerchantMembership> updateProfile({
    required String merchantId,
    required String name,
  }) async {
    return membership(
      status: 'PENDING_REVIEW',
      approved: false,
      operationalReady: false,
      merchantId: merchantId,
    ).copyWithName(name);
  }

  @override
  Future<MerchantBranch> createBranch({
    required String merchantId,
    required String name,
    required String phone,
    required String addressText,
    required double latitude,
    required double longitude,
    required String wilayaCode,
    required int communeId,
  }) async {
    return MerchantBranch(
      id: 'b-new',
      name: name,
      phone: phone,
      addressText: addressText,
      latitude: latitude,
      longitude: longitude,
      operationalStatus: 'ACTIVE',
      wilayaCode: wilayaCode,
      communeId: communeId,
      wilayaNameFr: 'Alger',
      communeNameFr: 'Alger Centre',
    );
  }

  @override
  Future<MerchantBranch> updateBranch({
    required String merchantId,
    required String branchId,
    String? name,
    String? phone,
    String? addressText,
    double? latitude,
    double? longitude,
    String? wilayaCode,
    int? communeId,
    Map<String, String?>? publicInfo,
  }) async {
    return MerchantBranch(
      id: branchId,
      name: name ?? 'Branch',
      phone: phone ?? '0550000001',
      addressText: addressText ?? 'Alger',
      latitude: latitude ?? 36.7,
      longitude: longitude ?? 3.0,
      operationalStatus: 'ACTIVE',
      wilayaCode: wilayaCode,
      communeId: communeId,
      description: publicInfo?['description'],
      nameAr: publicInfo?['nameAr'],
      publicEmail: publicInfo?['publicEmail'],
    );
  }

  List<CommerceVertical> commerceVerticals = const [
    CommerceVertical(
      id: 'v-restaurant',
      slug: 'restaurant',
      name: 'Restaurant',
      iconKey: 'restaurant',
      sortOrder: 0,
    ),
    CommerceVertical(
      id: 'v-bakery',
      slug: 'boulangerie',
      name: 'Boulangerie',
      iconKey: 'bakery',
      sortOrder: 1,
    ),
  ];
  BranchClassification? branchClassification;
  final classificationPuts = <String>[];

  @override
  Future<List<CommerceVertical>> listCommerceVerticals() async =>
      commerceVerticals;

  @override
  Future<BranchClassification?> getBranchClassification({
    required String merchantId,
    required String branchId,
  }) async =>
      branchClassification;

  @override
  Future<BranchClassification> putBranchClassification({
    required String merchantId,
    required String branchId,
    required String verticalId,
  }) async {
    classificationPuts.add(verticalId);
    final match = commerceVerticals.firstWhere((v) => v.id == verticalId);
    branchClassification = BranchClassification(
      verticalId: match.id,
      slug: match.slug,
      name: match.name,
      iconKey: match.iconKey,
    );
    return branchClassification!;
  }

  @override
  Future<void> deleteBranchClassification({
    required String merchantId,
    required String branchId,
  }) async {
    branchClassification = null;
  }

  @override
  Future<List<AlgeriaWilaya>> listWilayas() async {
    return const [
      AlgeriaWilaya(code: '16', nameFr: 'Alger', nameAr: 'الجزائر'),
    ];
  }

  @override
  Future<List<AlgeriaCommune>> listCommunes({
    required String wilayaCode,
    String? q,
  }) async {
    return const [
      AlgeriaCommune(
        id: 556,
        wilayaCode: '16',
        nameFr: 'Alger Centre',
        nameAr: 'الجزائر الوسطى',
      ),
    ];
  }

  @override
  Future<MerchantOrderListPage> listOrders({
    required String merchantId,
    String? branchId,
    String? orderStatus,
    String? fulfillmentStatus,
    int limit = 50,
    int offset = 0,
  }) async {
    orderCalls.add(
      '$merchantId:${branchId ?? ''}:${fulfillmentStatus ?? ''}:$offset',
    );
    if (ordersHandler != null) {
      return ordersHandler!(
        merchantId: merchantId,
        branchId: branchId,
        orderStatus: orderStatus,
        fulfillmentStatus: fulfillmentStatus,
        limit: limit,
        offset: offset,
      );
    }
    return const MerchantOrderListPage(
      items: [],
      limit: 50,
      offset: 0,
      total: 0,
    );
  }

  @override
  Future<MerchantOrderDetail> getOrder({
    required String merchantId,
    required String orderId,
  }) async {
    if (orderDetailHandler != null) {
      return orderDetailHandler!(merchantId: merchantId, orderId: orderId);
    }
    if (mutableDetail != null && mutableDetail!.id == orderId) {
      return mutableDetail!;
    }
    throw const ApiException(
      'Commande introuvable.',
      code: 'MERCHANT_ORDER_NOT_FOUND',
      statusCode: 404,
    );
  }

  @override
  Future<MerchantOrderDetail> acceptOrder({
    required String merchantId,
    required String orderId,
    int? preparationMinutes,
  }) async {
    mutationCalls.add(
      preparationMinutes == null
          ? 'accept:$orderId'
          : 'accept:$orderId:$preparationMinutes',
    );
    acceptCalls++;
    if (acceptThrowsNetwork) {
      throw const NetworkException('network', code: 'NETWORK');
    }
    if (acceptThrowsConflict) {
      throw const ApiException(
        'already',
        code: 'MERCHANT_ORDER_ALREADY_ACCEPTED',
        statusCode: 409,
      );
    }
    final current = await getOrder(merchantId: merchantId, orderId: orderId);
    final confirmedAt = '2026-01-01T00:01:00Z';
    final readyAt = preparationMinutes == null
        ? null
        : DateTime.parse(confirmedAt)
              .add(Duration(minutes: preparationMinutes))
              .toUtc()
              .toIso8601String();
    mutableDetail = MerchantOrderDetail(
      id: current.id,
      publicReference: current.publicReference,
      status: 'CONFIRMED',
      fulfillmentStatus: 'ACCEPTED',
      merchantBranchId: current.merchantBranchId,
      createdAt: current.createdAt,
      confirmedAt: confirmedAt,
      customerFullName: current.customerFullName,
      payment: current.payment,
      financial: current.financial,
      preparationMinutes: preparationMinutes,
      originalPreparationMinutes: preparationMinutes,
      estimatedReadyAt: readyAt,
      originalEstimatedReadyAt: readyAt,
      preparationEstimateVersion: preparationMinutes == null ? 0 : 1,
      isPreparationLate: false,
      items: current.items,
      deliveryAddress: current.deliveryAddress,
      statusHistory: current.statusHistory,
    );
    return mutableDetail!;
  }

  @override
  Future<MerchantOrderDetail> updatePreparationEstimate({
    required String merchantId,
    required String orderId,
    required int addMinutes,
    required int expectedEstimateVersion,
    String? reason,
  }) async {
    mutationCalls.add(
      'prep-estimate:$orderId:$addMinutes:$expectedEstimateVersion',
    );
    final current = await getOrder(merchantId: merchantId, orderId: orderId);
    if (current.preparationEstimateVersion != expectedEstimateVersion) {
      throw const ApiException(
        'stale',
        code: 'MERCHANT_ORDER_PREP_ESTIMATE_CONFLICT',
        statusCode: 409,
      );
    }
    if (current.fulfillmentStatus != 'ACCEPTED' &&
        current.fulfillmentStatus != 'PREPARING') {
      throw const ApiException(
        'not allowed',
        code: 'MERCHANT_ORDER_PREP_ESTIMATE_NOT_ALLOWED',
        statusCode: 409,
      );
    }
    if (current.estimatedReadyAt == null || addMinutes < 1 || addMinutes > 60) {
      throw const ApiException(
        'invalid',
        code: 'MERCHANT_ORDER_PREP_ESTIMATE_INVALID',
        statusCode: 400,
      );
    }
    final nextReady = DateTime.parse(current.estimatedReadyAt!)
        .add(Duration(minutes: addMinutes))
        .toUtc()
        .toIso8601String();
    mutableDetail = MerchantOrderDetail(
      id: current.id,
      publicReference: current.publicReference,
      status: current.status,
      fulfillmentStatus: current.fulfillmentStatus,
      merchantBranchId: current.merchantBranchId,
      createdAt: current.createdAt,
      confirmedAt: current.confirmedAt,
      customerFullName: current.customerFullName,
      payment: current.payment,
      financial: current.financial,
      preparationMinutes: current.preparationMinutes,
      originalPreparationMinutes: current.originalPreparationMinutes,
      estimatedReadyAt: nextReady,
      originalEstimatedReadyAt: current.originalEstimatedReadyAt,
      preparationEstimateVersion: current.preparationEstimateVersion + 1,
      isPreparationLate: false,
      items: current.items,
      deliveryAddress: current.deliveryAddress,
      statusHistory: current.statusHistory,
      cancellation: current.cancellation,
    );
    return mutableDetail!;
  }

  @override
  Future<MerchantOrderDetail> rejectOrder({
    required String merchantId,
    required String orderId,
    required String reason,
    String? reasonCode,
  }) async {
    mutationCalls.add(
      'reject:$orderId:${reasonCode ?? ''}:$reason',
    );
    final current = await getOrder(merchantId: merchantId, orderId: orderId);
    mutableDetail = MerchantOrderDetail(
      id: current.id,
      publicReference: current.publicReference,
      status: 'CANCELLED',
      fulfillmentStatus: 'PENDING_ACCEPTANCE',
      merchantBranchId: current.merchantBranchId,
      createdAt: current.createdAt,
      confirmedAt: current.confirmedAt,
      customerFullName: current.customerFullName,
      payment: current.payment,
      financial: current.financial,
      preparationMinutes: current.preparationMinutes,
      originalPreparationMinutes: current.originalPreparationMinutes,
      estimatedReadyAt: current.estimatedReadyAt,
      originalEstimatedReadyAt: current.originalEstimatedReadyAt,
      preparationEstimateVersion: current.preparationEstimateVersion,
      isPreparationLate: current.isPreparationLate,
      items: current.items,
      deliveryAddress: current.deliveryAddress,
      statusHistory: current.statusHistory,
      cancellation: MerchantOrderCancellation(
        reason: reason,
        cancelledAt: '2026-01-01T00:02:00Z',
      ),
    );
    return mutableDetail!;
  }

  @override
  Future<MerchantOrderDetail> startPreparation({
    required String merchantId,
    required String orderId,
  }) async {
    mutationCalls.add('start:$orderId');
    final current = await getOrder(merchantId: merchantId, orderId: orderId);
    mutableDetail = MerchantOrderDetail(
      id: current.id,
      publicReference: current.publicReference,
      status: 'ACTIVE',
      fulfillmentStatus: 'PREPARING',
      merchantBranchId: current.merchantBranchId,
      createdAt: current.createdAt,
      confirmedAt: current.confirmedAt,
      customerFullName: current.customerFullName,
      payment: current.payment,
      financial: current.financial,
      preparationMinutes: current.preparationMinutes,
      originalPreparationMinutes: current.originalPreparationMinutes,
      estimatedReadyAt: current.estimatedReadyAt,
      originalEstimatedReadyAt: current.originalEstimatedReadyAt,
      preparationEstimateVersion: current.preparationEstimateVersion,
      isPreparationLate: current.isPreparationLate,
      items: current.items,
      deliveryAddress: current.deliveryAddress,
      statusHistory: current.statusHistory,
    );
    return mutableDetail!;
  }

  @override
  Future<MerchantOrderDetail> markReady({
    required String merchantId,
    required String orderId,
  }) async {
    mutationCalls.add('ready:$orderId');
    final current = await getOrder(merchantId: merchantId, orderId: orderId);
    mutableDetail = MerchantOrderDetail(
      id: current.id,
      publicReference: current.publicReference,
      status: 'ACTIVE',
      fulfillmentStatus: 'READY',
      merchantBranchId: current.merchantBranchId,
      createdAt: current.createdAt,
      confirmedAt: current.confirmedAt,
      customerFullName: current.customerFullName,
      payment: current.payment,
      financial: current.financial,
      preparationMinutes: current.preparationMinutes,
      originalPreparationMinutes: current.originalPreparationMinutes,
      estimatedReadyAt: current.estimatedReadyAt,
      originalEstimatedReadyAt: current.originalEstimatedReadyAt,
      preparationEstimateVersion: current.preparationEstimateVersion,
      isPreparationLate: current.isPreparationLate,
      items: current.items,
      deliveryAddress: current.deliveryAddress,
      statusHistory: current.statusHistory,
    );
    return mutableDetail!;
  }

  @override
  Future<MerchantDeliverySummary?> getOrderDelivery({
    required String merchantId,
    required String orderId,
  }) async {
    return deliveryHandler?.call(orderId: orderId);
  }

  @override
  Future<MerchantPickupHandoff> getPickupHandoff({
    required String merchantId,
    required String orderId,
  }) async {
    if (pickupHandoffHandler != null) {
      return pickupHandoffHandler!(orderId: orderId);
    }
    throw const ApiException(
      'Handoff indisponible.',
      code: 'PICKUP_HANDOFF_NOT_FOUND',
      statusCode: 404,
    );
  }

  @override
  Future<MerchantPickupHandoff> regeneratePickupHandoff({
    required String merchantId,
    required String orderId,
  }) async {
    if (regeneratePickupHandoffHandler != null) {
      return regeneratePickupHandoffHandler!(orderId: orderId);
    }
    throw const ApiException(
      'Handoff indisponible.',
      code: 'PICKUP_HANDOFF_NOT_FOUND',
      statusCode: 404,
    );
  }

  Future<LegalCurrent> Function()? legalCurrentHandler;
  Future<void> Function(String merchantId, List<LegalAcceptance> acceptances)?
  submitVerificationHandler;
  int legalCurrentCalls = 0;
  final submittedAcceptances = <List<LegalAcceptance>>[];

  @override
  Future<LegalCurrent> getLegalCurrent() async {
    legalCurrentCalls += 1;
    if (legalCurrentHandler != null) return legalCurrentHandler!();
    return const LegalCurrent(
      versions: [
        LegalVersion(kind: LegalKind.merchantTerms, version: 'v1'),
        LegalVersion(kind: LegalKind.dossierAccuracyDeclaration, version: 'v1'),
      ],
    );
  }

  @override
  Future<void> submitVerification(
    String merchantId, {
    required List<LegalAcceptance> acceptances,
  }) async {
    submittedAcceptances.add(acceptances);
    await submitVerificationHandler?.call(merchantId, acceptances);
  }

  @override
  Future<EvidenceUploadResult> uploadEvidenceContent({
    required String merchantId,
    required String type,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {
    uploadedTypes.putIfAbsent(merchantId, () => []).add(type);
    return EvidenceUploadResult(
      uploadReference: 'sg-upload:v1:$type',
      contentType: contentType,
      sizeBytes: bytes.length,
      purpose: 'MERCHANT_VERIFICATION',
    );
  }

  @override
  Future<MerchantMembership> bindEvidence({
    required String merchantId,
    required String type,
    required String uploadReference,
    String? expiryDate,
  }) async {
    final uploads = uploadedTypes[merchantId] ?? [];
    final identity =
        uploads.contains('BUSINESS_IDENTITY') || type == 'BUSINESS_IDENTITY';
    final registration =
        uploads.contains('BUSINESS_REGISTRATION') ||
        type == 'BUSINESS_REGISTRATION';
    return membership(
      status: 'PENDING_REVIEW',
      approved: false,
      operationalReady: false,
      verificationReady: identity && registration,
      merchantId: merchantId,
      evidenceChecklist: [
        MerchantEvidenceItem(
          type: 'BUSINESS_IDENTITY',
          required: true,
          present: identity,
          complete: identity,
          status: 'PENDING',
        ),
        MerchantEvidenceItem(
          type: 'BUSINESS_REGISTRATION',
          required: true,
          present: registration,
          complete: registration,
          status: 'PENDING',
        ),
        const MerchantEvidenceItem(
          type: 'SUPPORTING_DOCUMENT',
          required: false,
          present: false,
          complete: false,
        ),
      ],
    );
  }

  @override
  Future<CatalogBootstrap> getCatalogBootstrap({
    required String merchantId,
    required String branchId,
  }) async {
    if (catalogBootstrapHandler != null) {
      return catalogBootstrapHandler!(
        merchantId: merchantId,
        branchId: branchId,
      );
    }
    return CatalogBootstrap(
      branchId: branchId,
      stats: const CatalogStats(
        categoryCount: 0,
        productCount: 0,
        availableProductCount: 0,
      ),
      categories: const [],
    );
  }

  @override
  Future<List<CatalogCategory>> listCategories({
    required String merchantId,
    required String branchId,
  }) async {
    if (categoriesHandler != null) {
      return categoriesHandler!(merchantId: merchantId, branchId: branchId);
    }
    final bootstrap = await getCatalogBootstrap(
      merchantId: merchantId,
      branchId: branchId,
    );
    return bootstrap.categories;
  }

  @override
  Future<List<CatalogProduct>> listProducts({
    required String merchantId,
    required String branchId,
    String? categoryId,
  }) async {
    if (productsHandler != null) {
      return productsHandler!(
        merchantId: merchantId,
        branchId: branchId,
        categoryId: categoryId,
      );
    }
    return const [];
  }

  @override
  Future<CatalogProduct> updateProductAvailability({
    required String merchantId,
    required String productId,
    required bool available,
  }) async {
    if (updateAvailabilityHandler != null) {
      return updateAvailabilityHandler!(
        merchantId: merchantId,
        productId: productId,
        available: available,
      );
    }
    return CatalogProduct(
      id: productId,
      branchId: '',
      categoryId: '',
      name: 'Product',
      description: null,
      priceMinor: '0',
      available: available,
    );
  }

  @override
  Future<CatalogProduct> getProduct({
    required String merchantId,
    required String productId,
  }) async {
    return CatalogProduct(
      id: productId,
      branchId: 'b-1',
      categoryId: 'c-1',
      name: 'Product',
      description: null,
      priceMinor: '1000',
      available: true,
    );
  }

  @override
  Future<CatalogProduct> createProduct({
    required String merchantId,
    required String branchId,
    required String categoryId,
    required String name,
    String? description,
    required int priceMinor,
    bool available = true,
    SellingUnitSelection? sellingUnit,
  }) async {
    return CatalogProduct(
      id: 'p-new',
      branchId: branchId,
      categoryId: categoryId,
      name: name,
      description: description,
      priceMinor: '$priceMinor',
      available: available,
      sellingUnitCode: sellingUnit?.code,
      sellingUnitLabelFr: sellingUnit?.labelFr,
    );
  }

  @override
  Future<CatalogProduct> updateProduct({
    required String merchantId,
    required String productId,
    String? categoryId,
    String? name,
    String? description,
    int? priceMinor,
    bool? available,
    SellingUnitSelection? sellingUnit,
  }) async {
    return CatalogProduct(
      id: productId,
      branchId: 'b-1',
      categoryId: categoryId ?? 'c-1',
      name: name ?? 'Product',
      description: description,
      priceMinor: '${priceMinor ?? 1000}',
      available: available ?? true,
      sellingUnitCode: sellingUnit?.isNone == true ? null : sellingUnit?.code,
      sellingUnitLabelFr:
          sellingUnit?.isNone == true ? null : sellingUnit?.labelFr,
    );
  }

  @override
  Future<void> deleteProduct({
    required String merchantId,
    required String productId,
  }) async {}

  final List<String> duplicateRequestIds = [];
  Future<ProductDuplicateResult> Function({
    required String merchantId,
    required String productId,
    required String requestId,
    String? name,
  })?
  duplicateHandler;

  @override
  Future<ProductDuplicateResult> duplicateProduct({
    required String merchantId,
    required String productId,
    required String requestId,
    String? name,
  }) async {
    duplicateRequestIds.add(requestId);
    if (duplicateHandler != null) {
      return duplicateHandler!(
        merchantId: merchantId,
        productId: productId,
        requestId: requestId,
        name: name,
      );
    }
    throw const ApiException('not configured', statusCode: 500);
  }

  /// In-memory option groups keyed by product id.
  final Map<String, List<CatalogOptionGroup>> optionGroups = {};
  final List<String> optionCalls = [];
  int _optionSeq = 0;

  List<CatalogOptionGroup> _groups(String productId) =>
      optionGroups.putIfAbsent(productId, () => []);

  CatalogOptionGroup _copyGroup(
    CatalogOptionGroup g, {
    String? name,
    bool? required,
    int? minSelections,
    int? maxSelections,
    List<CatalogOption>? options,
  }) =>
      CatalogOptionGroup(
        id: g.id,
        name: name ?? g.name,
        required: required ?? g.required,
        minSelections: minSelections ?? g.minSelections,
        maxSelections: maxSelections ?? g.maxSelections,
        options: options ?? g.options,
      );

  void _replaceGroup(String productId, CatalogOptionGroup next) {
    final list = _groups(productId);
    final i = list.indexWhere((g) => g.id == next.id);
    if (i >= 0) list[i] = next;
  }

  @override
  Future<List<CatalogOptionGroup>> listOptionGroups({
    required String merchantId,
    required String productId,
  }) async {
    optionCalls.add('list:$productId');
    return List.of(_groups(productId));
  }

  @override
  Future<CatalogOptionGroup> createOptionGroup({
    required String merchantId,
    required String productId,
    required String name,
    required bool required,
    required int minSelections,
    required int maxSelections,
  }) async {
    optionCalls.add('createGroup:$name:$required:$minSelections:$maxSelections');
    final g = CatalogOptionGroup(
      id: 'g-${++_optionSeq}',
      name: name,
      required: required,
      minSelections: minSelections,
      maxSelections: maxSelections,
      options: const [],
    );
    _groups(productId).add(g);
    return g;
  }

  @override
  Future<CatalogOptionGroup> updateOptionGroup({
    required String merchantId,
    required String productId,
    required String groupId,
    String? name,
    bool? required,
    int? minSelections,
    int? maxSelections,
  }) async {
    optionCalls.add('updateGroup:$groupId');
    final g = _groups(productId).firstWhere((g) => g.id == groupId);
    final next = _copyGroup(
      g,
      name: name,
      required: required,
      minSelections: minSelections,
      maxSelections: maxSelections,
    );
    _replaceGroup(productId, next);
    return next;
  }

  @override
  Future<void> deleteOptionGroup({
    required String merchantId,
    required String productId,
    required String groupId,
  }) async {
    optionCalls.add('deleteGroup:$groupId');
    _groups(productId).removeWhere((g) => g.id == groupId);
  }

  @override
  Future<CatalogOption> createOption({
    required String merchantId,
    required String productId,
    required String groupId,
    required String name,
    required int additionalPriceMinor,
    bool available = true,
  }) async {
    optionCalls.add('createOption:$groupId:$name:$additionalPriceMinor');
    final o = CatalogOption(
      id: 'o-${++_optionSeq}',
      name: name,
      additionalPriceMinor: '$additionalPriceMinor',
      available: available,
    );
    final g = _groups(productId).firstWhere((g) => g.id == groupId);
    _replaceGroup(productId, _copyGroup(g, options: [...g.options, o]));
    return o;
  }

  @override
  Future<CatalogOption> updateOption({
    required String merchantId,
    required String productId,
    required String groupId,
    required String optionId,
    String? name,
    int? additionalPriceMinor,
    bool? available,
  }) async {
    optionCalls.add('updateOption:$optionId');
    final g = _groups(productId).firstWhere((g) => g.id == groupId);
    late CatalogOption next;
    final options = [
      for (final o in g.options)
        if (o.id == optionId)
          next = CatalogOption(
            id: o.id,
            name: name ?? o.name,
            additionalPriceMinor:
                additionalPriceMinor?.toString() ?? o.additionalPriceMinor,
            available: available ?? o.available,
          )
        else
          o,
    ];
    _replaceGroup(productId, _copyGroup(g, options: options));
    return next;
  }

  @override
  Future<void> deleteOption({
    required String merchantId,
    required String productId,
    required String groupId,
    required String optionId,
  }) async {
    optionCalls.add('deleteOption:$optionId');
    final g = _groups(productId).firstWhere((g) => g.id == groupId);
    _replaceGroup(
      productId,
      _copyGroup(g, options: g.options.where((o) => o.id != optionId).toList()),
    );
  }

  @override
  Future<CatalogCategory> createCategory({
    required String merchantId,
    required String branchId,
    required String name,
    int? sortOrder,
    bool active = true,
  }) async {
    return CatalogCategory(
      id: 'c-new',
      branchId: branchId,
      name: name,
      sortOrder: sortOrder ?? 0,
      active: active,
    );
  }

  @override
  Future<CatalogCategory> updateCategory({
    required String merchantId,
    required String categoryId,
    String? name,
    int? sortOrder,
    bool? active,
  }) async {
    return CatalogCategory(
      id: categoryId,
      branchId: 'b-1',
      name: name ?? 'Category',
      sortOrder: sortOrder ?? 0,
      active: active ?? true,
    );
  }

  @override
  Future<void> deleteCategory({
    required String merchantId,
    required String categoryId,
  }) async {}

  @override
  Future<EvidenceUploadResult> uploadProductImageContent({
    required String merchantId,
    required String branchId,
    required String productId,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {
    return const EvidenceUploadResult(
      uploadReference: 'upload-product',
      contentType: 'image/jpeg',
      sizeBytes: 1,
      purpose: 'PRODUCT_IMAGE',
    );
  }

  @override
  Future<MediaBindResult> bindProductImage({
    required String merchantId,
    required String branchId,
    required String productId,
    required String uploadReference,
  }) async {
    return MediaBindResult(
      imageUrl: '/customer/branches/$branchId/products/$productId/image',
      contentType: 'image/jpeg',
    );
  }

  @override
  Future<void> deleteProductImage({
    required String merchantId,
    required String branchId,
    required String productId,
  }) async {}

  @override
  Future<Uint8List?> fetchProductImageBytes({
    required String merchantId,
    required String branchId,
    required String productId,
  }) async => null;

  @override
  Future<EvidenceUploadResult> uploadBranchCoverContent({
    required String merchantId,
    required String branchId,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {
    return const EvidenceUploadResult(
      uploadReference: 'upload-cover',
      contentType: 'image/jpeg',
      sizeBytes: 1,
      purpose: 'MERCHANT_BRANCH_COVER',
    );
  }

  @override
  Future<MediaBindResult> bindBranchCover({
    required String merchantId,
    required String branchId,
    required String uploadReference,
  }) async {
    return MediaBindResult(
      imageUrl: '/customer/branches/$branchId/cover',
      contentType: 'image/jpeg',
    );
  }

  @override
  Future<void> deleteBranchCover({
    required String merchantId,
    required String branchId,
  }) async {}

  @override
  Future<Uint8List?> fetchBranchCoverBytes({
    required String merchantId,
    required String branchId,
  }) async => null;

  /// In-memory branch logo: upload keeps bytes pending until bind.
  Uint8List? logoBytes;
  Uint8List? pendingLogoBytes;
  final List<String> logoCalls = [];
  Object? logoBindError;

  @override
  Future<EvidenceUploadResult> uploadBranchLogoContent({
    required String merchantId,
    required String branchId,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {
    logoCalls.add('upload');
    pendingLogoBytes = bytes;
    return EvidenceUploadResult(
      uploadReference: 'upload-logo',
      contentType: contentType,
      sizeBytes: bytes.length,
      purpose: 'MERCHANT_BRANCH_LOGO',
    );
  }

  @override
  Future<MediaBindResult> bindBranchLogo({
    required String merchantId,
    required String branchId,
    required String uploadReference,
  }) async {
    logoCalls.add('bind');
    if (logoBindError != null) throw logoBindError!;
    logoBytes = pendingLogoBytes;
    pendingLogoBytes = null;
    return MediaBindResult(
      imageUrl: '/merchant/$merchantId/branches/$branchId/logo',
      contentType: 'image/jpeg',
    );
  }

  @override
  Future<void> deleteBranchLogo({
    required String merchantId,
    required String branchId,
  }) async {
    logoCalls.add('delete');
    logoBytes = null;
  }

  @override
  Future<Uint8List?> fetchBranchLogoBytes({
    required String merchantId,
    required String branchId,
  }) async => logoBytes;

  @override
  Future<MerchantRatingSummary> ratingsSummary({
    required String merchantId,
  }) async {
    if (ratingsHandler != null) {
      return ratingsHandler!(merchantId: merchantId);
    }
    return MerchantRatingSummary(
      merchantId: merchantId,
      count: 0,
      average: null,
    );
  }

  @override
  Future<List<MerchantSettlementSummary>> listSettlements({
    required String merchantId,
  }) async {
    if (settlementsHandler != null) {
      return settlementsHandler!(merchantId: merchantId);
    }
    return const [];
  }

  @override
  Future<MerchantSalesSummary> salesSummary({
    required String merchantId,
    required ReportPeriodSelection period,
    String? branchId,
  }) async {
    if (salesSummaryHandler != null) {
      return salesSummaryHandler!(
        merchantId: merchantId,
        period: period,
        branchId: branchId,
      );
    }
    return MerchantSalesSummary.fromJson({
      'scope': {'merchantId': merchantId, 'branchId': branchId},
      'period': {'period': period.period.apiValue},
      'asOf': '2026-01-01T12:00:00.000Z',
      'currency': 'DZD',
      'dataStatus': 'COMPLETE',
      'completedOrderCount': 0,
      'grossMerchandiseMinor': '0',
      'averageBasketMinor': null,
      'cancelledOrderCount': 0,
      'financeAccess': 'ROLE_RESTRICTED',
      'finance': null,
      'trend': {'granularity': 'HOUR', 'buckets': <Object>[]},
    });
  }

  @override
  Future<MerchantTopProducts> topProducts({
    required String merchantId,
    required ReportPeriodSelection period,
    String? branchId,
    TopProductSort sort = TopProductSort.orders,
    int limit = 5,
  }) async {
    if (topProductsHandler != null) {
      return topProductsHandler!(
        merchantId: merchantId,
        period: period,
        branchId: branchId,
        sort: sort,
        limit: limit,
      );
    }
    return MerchantTopProducts(
      asOf: '2026-01-01T12:00:00.000Z',
      sort: sort,
      distinctProductCount: 0,
      items: const [],
    );
  }

  @override
  Future<MerchantDailySummary> dailySummary({
    required String merchantId,
    String? date,
    String? branchId,
  }) async {
    if (dailySummaryHandler != null) {
      return dailySummaryHandler!(
        merchantId: merchantId,
        date: date,
        branchId: branchId,
      );
    }
    return MerchantDailySummary.fromJson({
      'scope': {'merchantId': merchantId, 'branchId': branchId},
      'date': date ?? '2031-03-15',
      'period': {
        'period': 'CUSTOM',
        'from': '2031-03-14T23:00:00.000Z',
        'to': '2031-03-15T23:00:00.000Z',
        'localFrom': date ?? '2031-03-15',
        'localToInclusive': date ?? '2031-03-15',
      },
      'asOf': '2031-03-15T10:30:00.000Z',
      'currency': 'DZD',
      'dataStatus': 'OK',
      'financeAccess': 'GRANTED',
      'ordersCreatedCount': 0,
      'completedOrderCount': 0,
      'cancelledOrderCount': 0,
      'activeOrderCount': 0,
      'breakdown': {
        'completed': 0,
        'inProgress': 0,
        'cancelled': 0,
        'failed': 0,
      },
      'grossMerchandiseMinor': '0',
      'averageBasketMinor': null,
      'averageActualPreparationMinutes': null,
      'preparationSampleCount': 0,
      'onTimeLateSampleCount': 0,
      'onTimePreparationCount': 0,
      'latePreparationCount': 0,
      'onTimePreparationRateBps': null,
      'cancellationReasons': <Object>[],
    });
  }

  @override
  Future<OpeningHoursSchedule> getOpeningHours({
    required String merchantId,
    required String branchId,
  }) async {
    if (openingHoursHandler != null) {
      return openingHoursHandler!(merchantId: merchantId, branchId: branchId);
    }
    return OpeningHoursSchedule(
      branchId: branchId,
      timezone: 'Africa/Algiers',
      hoursConfigured: false,
      version: 0,
      days: OpeningHoursSchedule.blankWeek(),
    );
  }

  @override
  Future<OpeningHoursSchedule> putOpeningHours({
    required String merchantId,
    required String branchId,
    required int expectedVersion,
    required List<OpeningDay> days,
  }) async {
    return OpeningHoursSchedule(
      branchId: branchId,
      timezone: 'Africa/Algiers',
      hoursConfigured: true,
      version: expectedVersion + 1,
      days: days,
    );
  }

  /// In-memory exceptional dates (server semantics: version starts at 1).
  String exceptionsToday = '2026-10-02';
  final List<OpeningHoursException> hoursExceptions = [];
  final List<String> exceptionCalls = [];
  Object? putExceptionError;
  Object? listExceptionsError;

  @override
  Future<OpeningHoursExceptionList> listOpeningHoursExceptions({
    required String merchantId,
    required String branchId,
  }) async {
    exceptionCalls.add('list');
    if (listExceptionsError != null) throw listExceptionsError!;
    final items = [...hoursExceptions]..sort((a, b) => a.date.compareTo(b.date));
    return OpeningHoursExceptionList(
      branchId: branchId,
      timezone: 'Africa/Algiers',
      today: exceptionsToday,
      items: items,
    );
  }

  @override
  Future<OpeningHoursException> putOpeningHoursException({
    required String merchantId,
    required String branchId,
    required String date,
    required int expectedVersion,
    required bool closed,
    required List<OpeningInterval> intervals,
    required String label,
    String? customerMessage,
  }) async {
    exceptionCalls.add('put:$date:$expectedVersion');
    if (putExceptionError != null) throw putExceptionError!;
    final index = hoursExceptions.indexWhere((e) => e.date == date);
    final current = index < 0 ? 0 : hoursExceptions[index].version;
    if (current != expectedVersion) {
      throw const ApiException(
        'stale',
        code: 'OPENING_HOURS_EXCEPTION_VERSION_CONFLICT',
        statusCode: 409,
      );
    }
    final saved = OpeningHoursException(
      date: date,
      closed: closed,
      label: label,
      customerMessage: customerMessage,
      intervals: closed ? const [] : intervals,
      version: current + 1,
      updatedAt: '2026-10-02T10:00:00.000Z',
    );
    if (index < 0) {
      hoursExceptions.add(saved);
    } else {
      hoursExceptions[index] = saved;
    }
    return saved;
  }

  @override
  Future<void> deleteOpeningHoursException({
    required String merchantId,
    required String branchId,
    required String date,
    required int expectedVersion,
  }) async {
    exceptionCalls.add('delete:$date:$expectedVersion');
    final index = hoursExceptions.indexWhere((e) => e.date == date);
    if (index < 0) {
      throw const ApiException(
        'missing',
        code: 'OPENING_HOURS_EXCEPTION_NOT_FOUND',
        statusCode: 404,
      );
    }
    if (hoursExceptions[index].version != expectedVersion) {
      throw const ApiException(
        'stale',
        code: 'OPENING_HOURS_EXCEPTION_VERSION_CONFLICT',
        statusCode: 409,
      );
    }
    hoursExceptions.removeAt(index);
  }

  @override
  Future<BranchAvailabilityState> getAvailability({
    required String merchantId,
    required String branchId,
  }) async {
    if (availabilityHandler != null) {
      return availabilityHandler!(merchantId: merchantId, branchId: branchId);
    }
    return BranchAvailabilityState(
      branchId: branchId,
      timezone: 'Africa/Algiers',
      availabilityMode: 'FOLLOW_SCHEDULE',
      effectiveMode: 'FOLLOW_SCHEDULE',
      hoursConfigured: true,
      isOpenNow: true,
      acceptingOrders: true,
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

  @override
  Future<BranchAvailabilityState> putAvailability({
    required String merchantId,
    required String branchId,
    required int expectedVersion,
    required String mode,
    String? reasonCode,
    String? customerMessage,
    String? closedUntil,
  }) async {
    return BranchAvailabilityState(
      branchId: branchId,
      timezone: 'Africa/Algiers',
      availabilityMode: mode,
      effectiveMode: mode,
      hoursConfigured: true,
      isOpenNow: mode == 'FOLLOW_SCHEDULE',
      acceptingOrders: mode == 'FOLLOW_SCHEDULE',
      temporaryExpired: false,
      outsideWeeklyHours: false,
      reasonCode: reasonCode,
      customerMessage: customerMessage,
      closedUntil: closedUntil,
      nextOpenAt: null,
      currentClosesAt: null,
      version: expectedVersion + 1,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<List<MerchantNotificationItem>> listNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    if (notificationsHandler != null) return notificationsHandler!();
    return const [];
  }

  @override
  Future<int> notificationsUnreadCount() async => unreadCount;

  @override
  Future<String> createSupportTicket({
    required String merchantId,
    required String subject,
    required String topicCode,
    required String body,
    String? orderId,
  }) async {
    final reference = supportTicketHandler != null
        ? await supportTicketHandler!(body: body, orderId: orderId)
        : 'sgt_test';
    supportTickets.add({
      'body': body,
      'orderId': orderId,
      'subject': subject,
      'topicCode': topicCode,
    });
    return reference;
  }

  List<SupportTopic> supportTopics = const [
    SupportTopic(code: 'ORDER_ISSUE', labelFr: 'Problème de commande'),
    SupportTopic(code: 'PAYMENT_COD', labelFr: 'Paiement et espèces (COD)'),
    SupportTopic(code: 'ACCOUNT_ACCESS', labelFr: 'Accès au compte'),
    SupportTopic(
      code: 'CATALOGUE_TECH',
      labelFr: 'Catalogue ou problème technique',
    ),
    SupportTopic(code: 'OTHER', labelFr: 'Autre demande'),
  ];
  List<SupportFaqArticle> supportFaq = const [
    SupportFaqArticle(
      slug: 'verification',
      titleFr: 'Vérification du dossier',
      bodyFr: 'Le dossier est examiné par SpeedyGo après soumission.',
      version: '2026-10-03',
    ),
  ];

  @override
  Future<List<SupportTopic>> listSupportTopics({
    required String merchantId,
  }) async =>
      supportTopics;

  @override
  Future<List<SupportFaqArticle>> listSupportFaq({
    required String merchantId,
  }) async =>
      supportFaq;

  Future<SupportTicketPage> Function({required int limit, required int offset})?
  supportListHandler;
  Future<SupportTicketDetail> Function(String ticketId)? supportDetailHandler;
  final supportReplies = <(String, String)>[];

  @override
  Future<SupportTicketPage> listSupportTickets({
    required String merchantId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (supportListHandler != null) {
      return supportListHandler!(limit: limit, offset: offset);
    }
    return const SupportTicketPage(items: [], total: 0);
  }

  @override
  Future<SupportTicketDetail> getSupportTicket({
    required String merchantId,
    required String ticketId,
  }) async {
    if (supportDetailHandler != null) return supportDetailHandler!(ticketId);
    throw const ApiException('not found', statusCode: 404);
  }

  @override
  Future<SupportMessage> replySupportTicket({
    required String merchantId,
    required String ticketId,
    required String body,
  }) async {
    supportReplies.add((ticketId, body));
    return SupportMessage(
      id: 'm-${supportReplies.length}',
      authorAccountId: 'acc-1',
      body: body,
      createdAt: DateTime.utc(2026, 9, 30, 11),
      displayName: null,
    );
  }

  MerchantTeam team = const MerchantTeam(
    merchantId: 'm-1',
    members: [],
    invitations: [],
    canManage: true,
  );
  Future<MerchantTeam> Function()? teamHandler;
  Object? teamMutationError;
  String teamAcceptCode = 'a' * 64;
  final teamCalls = <String>[];
  int teamFetches = 0;

  void _throwTeamMutationError() {
    final error = teamMutationError;
    if (error == null) return;
    teamMutationError = null;
    throw error;
  }

  @override
  Future<MerchantTeam> getTeam({required String merchantId}) async {
    teamFetches += 1;
    if (teamHandler != null) return teamHandler!();
    return team;
  }

  @override
  Future<TeamInvitationIssued> createTeamInvitation({
    required String merchantId,
    required String phone,
    required String role,
  }) async {
    teamCalls.add('invite:$phone:$role');
    _throwTeamMutationError();
    final invitation = TeamInvitation(
      id: 'inv-${team.invitations.length + 1}',
      phone: phone,
      role: role,
      status: 'PENDING',
      version: 1,
      expiresAt: DateTime.utc(2026, 10, 11, 12),
      createdAt: DateTime.utc(2026, 10, 4, 12),
    );
    team = MerchantTeam(
      merchantId: team.merchantId,
      members: team.members,
      invitations: [...team.invitations, invitation],
      canManage: team.canManage,
    );
    return TeamInvitationIssued(
      invitation: invitation,
      acceptCode: teamAcceptCode,
    );
  }

  @override
  Future<TeamInvitation> cancelTeamInvitation({
    required String merchantId,
    required String invitationId,
    required int expectedVersion,
  }) async {
    teamCalls.add('cancel:$invitationId:$expectedVersion');
    _throwTeamMutationError();
    final target = team.invitations.firstWhere((i) => i.id == invitationId);
    team = MerchantTeam(
      merchantId: team.merchantId,
      members: team.members,
      invitations: [
        for (final i in team.invitations)
          if (i.id != invitationId) i,
      ],
      canManage: team.canManage,
    );
    return target;
  }

  @override
  Future<TeamInvitationIssued> regenerateTeamInvitationCode({
    required String merchantId,
    required String invitationId,
    required int expectedVersion,
  }) async {
    teamCalls.add('regenerate:$invitationId:$expectedVersion');
    _throwTeamMutationError();
    final target = team.invitations.firstWhere((i) => i.id == invitationId);
    final bumped = TeamInvitation(
      id: target.id,
      phone: target.phone,
      role: target.role,
      status: 'PENDING',
      version: target.version + 1,
      expiresAt: DateTime.utc(2026, 10, 12, 12),
      createdAt: target.createdAt,
    );
    team = MerchantTeam(
      merchantId: team.merchantId,
      members: team.members,
      invitations: [
        for (final i in team.invitations) i.id == invitationId ? bumped : i,
      ],
      canManage: team.canManage,
    );
    return TeamInvitationIssued(
      invitation: bumped,
      acceptCode: teamAcceptCode,
    );
  }

  @override
  Future<TeamMember> updateTeamMemberRole({
    required String merchantId,
    required String memberId,
    required String role,
    required int expectedVersion,
  }) async {
    teamCalls.add('role:$memberId:$role:$expectedVersion');
    _throwTeamMutationError();
    final target = team.members.firstWhere((m) => m.id == memberId);
    final updated = TeamMember(
      id: target.id,
      phone: target.phone,
      role: role,
      isSelf: target.isSelf,
      version: target.version + 1,
      createdAt: target.createdAt,
    );
    team = MerchantTeam(
      merchantId: team.merchantId,
      members: [for (final m in team.members) m.id == memberId ? updated : m],
      invitations: team.invitations,
      canManage: team.canManage,
    );
    return updated;
  }

  @override
  Future<void> revokeTeamMember({
    required String merchantId,
    required String memberId,
    required int expectedVersion,
  }) async {
    teamCalls.add('revoke:$memberId:$expectedVersion');
    _throwTeamMutationError();
    team = MerchantTeam(
      merchantId: team.merchantId,
      members: [
        for (final m in team.members)
          if (m.id != memberId) m,
      ],
      invitations: team.invitations,
      canManage: team.canManage,
    );
  }

  List<MyTeamInvitation> myTeamInvitations = const [];
  Future<List<MyTeamInvitation>> Function()? myTeamInvitationsHandler;

  @override
  Future<List<MyTeamInvitation>> listMyTeamInvitations() async {
    if (myTeamInvitationsHandler != null) return myTeamInvitationsHandler!();
    return myTeamInvitations;
  }

  @override
  Future<TeamInvitationAccepted> acceptTeamInvitation({
    required String invitationId,
    required String acceptCode,
  }) async {
    teamCalls.add('accept:$invitationId:$acceptCode');
    _throwTeamMutationError();
    final target = myTeamInvitations.firstWhere((i) => i.id == invitationId);
    myTeamInvitations = [
      for (final i in myTeamInvitations)
        if (i.id != invitationId) i,
    ];
    return TeamInvitationAccepted(
      merchantId: target.merchantId,
      memberId: 'member-new',
      role: target.role,
    );
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {}

  @override
  Future<int> markAllNotificationsRead() async => 0;

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {}

  @override
  Future<void> deactivateDeviceToken({required String token}) async {}
}

extension MerchantMembershipTestX on MerchantMembership {
  MerchantMembership copyWithName(String name) {
    return MerchantMembership(
      merchantId: merchantId,
      role: role,
      profileComplete: profileComplete,
      hasBranch: hasBranch,
      branchReady: branchReady,
      approved: approved,
      operationalReady: operationalReady,
      verificationReady: verificationReady,
      verificationSubmitted: verificationSubmitted,
      verificationAttentionRequired: verificationAttentionRequired,
      merchantName: name,
      merchantStatus: merchantStatus,
      merchantPublicReference: merchantPublicReference,
      verifiedAt: verifiedAt,
      branches: branches,
      evidenceChecklist: evidenceChecklist,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt,
      attemptNumber: attemptNumber,
      legalAcceptance: legalAcceptance,
      currentIssues: currentIssues,
      unresolvedIssueCount: unresolvedIssueCount,
    );
  }

  MerchantMembership copyWithEvidence(List<MerchantEvidenceItem> checklist) {
    return MerchantMembership(
      merchantId: merchantId,
      role: role,
      profileComplete: profileComplete,
      hasBranch: hasBranch,
      branchReady: branchReady,
      approved: approved,
      operationalReady: operationalReady,
      verificationReady: verificationReady,
      verificationSubmitted: verificationSubmitted,
      verificationAttentionRequired: verificationAttentionRequired,
      merchantName: merchantName,
      merchantStatus: merchantStatus,
      merchantPublicReference: merchantPublicReference,
      verifiedAt: verifiedAt,
      branches: branches,
      evidenceChecklist: checklist,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt,
      attemptNumber: attemptNumber,
      legalAcceptance: legalAcceptance,
      currentIssues: currentIssues,
      unresolvedIssueCount: unresolvedIssueCount,
    );
  }
}

MerchantMembership membership({
  String status = 'ACTIVE',
  bool approved = true,
  bool operationalReady = true,
  bool verificationSubmitted = false,
  bool verificationReady = false,
  List<MerchantBranch> branches = const [],
  List<MerchantEvidenceItem> evidenceChecklist = const [],
  String role = 'OWNER',
  String merchantId = 'm-1',
  String? submittedAt,
  String? reviewedAt,
  int? attemptNumber,
  MerchantLegalAcceptanceRecord? legalAcceptance,
  List<VerificationIssue> currentIssues = const [],
}) {
  return MerchantMembership(
    submittedAt: submittedAt,
    reviewedAt: reviewedAt,
    attemptNumber: attemptNumber,
    legalAcceptance: legalAcceptance,
    currentIssues: currentIssues,
    unresolvedIssueCount: currentIssues.where((i) => !i.isResolved).length,
    merchantId: merchantId,
    role: role,
    profileComplete: true,
    hasBranch: branches.isNotEmpty,
    branchReady: branches.any((b) => b.operationalStatus == 'ACTIVE'),
    approved: approved,
    operationalReady: operationalReady,
    verificationReady: verificationReady,
    verificationSubmitted: verificationSubmitted,
    verificationAttentionRequired: false,
    merchantName: 'Demo Merchant',
    merchantStatus: status,
    merchantPublicReference: 'sgm_1',
    verifiedAt: approved ? '2026-01-01T00:00:00Z' : null,
    branches: branches,
    evidenceChecklist: evidenceChecklist,
  );
}

MerchantBranch branch(String id, {String status = 'ACTIVE', String? name}) {
  return MerchantBranch(
    id: id,
    name: name ?? 'Branch $id',
    phone: '0550000001',
    addressText: 'Alger',
    latitude: 36.7,
    longitude: 3.0,
    operationalStatus: status,
  );
}

ProviderContainer testContainer({
  required FakeAuthApi auth,
  required FakeMerchantApi merchant,
  MemorySessionStore? store,
  LaunchStore? launch,
  MemoryContextStore? context,
  ApprovalNoticeStore? approvals,
  Duration splashMin = Duration.zero,
  List<Override> overrides = const [],
}) {
  final sessionStore = store ?? MemorySessionStore();
  final launchStore =
      launch ?? MemoryLaunchStore(languageSeen: true, onboardingSeen: true);
  final contextStore = context ?? MemoryContextStore();
  final cache = TokenCache();
  final epoch = SessionEpoch();
  final refresher = TokenRefresher(
    authApi: auth,
    store: sessionStore,
    cache: cache,
    currentGeneration: () => epoch.value,
  );
  final dio = Dio();
  final infra = AuthInfrastructure(
    authApi: AuthApi(dio: dio, refreshDio: dio),
    merchantApi: MerchantApi(dio),
    refresher: refresher,
    config: const ApiConfig(apiBaseUrl: 'http://example.test'),
    dio: dio,
  );

  return ProviderContainer(
    overrides: [
      sessionStoreProvider.overrideWithValue(sessionStore),
      launchStoreProvider.overrideWithValue(launchStore),
      contextStoreProvider.overrideWithValue(contextStore),
      approvalNoticeStoreProvider.overrideWithValue(
        approvals ?? MemoryApprovalNoticeStore(),
      ),
      tokenCacheProvider.overrideWithValue(cache),
      sessionEpochProvider.overrideWithValue(epoch),
      splashMinDurationProvider.overrideWithValue(splashMin),
      splashAnimateProvider.overrideWithValue(false),
      authApiProvider.overrideWithValue(auth),
      merchantApiProvider.overrideWithValue(merchant),
      authInfrastructureProvider.overrideWithValue(infra),
      ...overrides,
    ],
  );
}

Future<void> pumpApp(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SpeedyGoApp()),
  );
  await tester.pump();
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> restoreAndResolve(ProviderContainer container) async {
  container.read(accessControllerProvider);
  await container.read(sessionControllerProvider.notifier).restore();
  await container.read(accessControllerProvider.notifier).resolve();
}

void main() {
  testWidgets('cold start without session reaches phone', (tester) async {
    final auth = FakeAuthApi();
    final merchant = FakeMerchantApi();
    final container = testContainer(auth: auth, merchant: merchant);
    addTearDown(container.dispose);

    await pumpApp(tester, container);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
  });

  testWidgets('OTP cooldown blocks duplicate request', (tester) async {
    final auth = FakeAuthApi();
    final merchant = FakeMerchantApi();
    final container = testContainer(auth: auth, merchant: merchant);
    addTearDown(container.dispose);

    await pumpApp(tester, container);
    await tester.enterText(
      find.byKey(const Key('merchant-phone-field')),
      '550000001',
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('merchant-phone-continue')),
    );
    await tester.tap(find.byKey(const Key('merchant-phone-continue')));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(auth.requestOtpCalls, 1);
    expect(find.text(AppStrings.otpTitle), findsOneWidget);

    final session = container.read(sessionControllerProvider);
    expect(session.canRequestOtp, isFalse);
    await container
        .read(sessionControllerProvider.notifier)
        .requestOtp('0550000001');
    expect(auth.requestOtpCalls, 1);
  });

  testWidgets('auth failure clears session and leaves signed out', (
    tester,
  ) async {
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final auth = FakeAuthApi(
      meHandler: () async {
        throw const ApiException('revoked', code: 'AUTH_SESSION_REVOKED');
      },
    );
    final merchant = FakeMerchantApi();
    final container = testContainer(
      auth: auth,
      merchant: merchant,
      store: store,
    );
    addTearDown(container.dispose);

    await pumpApp(tester, container);
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.signedOut,
    );
    expect(store.value, isNull);
    expect(find.text(AppStrings.phoneTitle), findsOneWidget);
  });

  test('no membership routes to noMembership destination', () async {
    final auth = FakeAuthApi();
    final merchant = FakeMerchantApi(
      meHandler: () async =>
          const MerchantMe(merchantMembershipExists: false, memberships: []),
    );
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final container = testContainer(
      auth: auth,
      merchant: merchant,
      store: store,
    );
    addTearDown(container.dispose);
    container.read(tokenCacheProvider).current = store.value;
    await restoreAndResolve(container);
    expect(
      container.read(accessControllerProvider).destination,
      AccessDestination.noMembership,
    );
  });

  test('single active branch auto-selects home', () async {
    final auth = FakeAuthApi();
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(branches: [branch('b1')]),
        ],
      ),
    );
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final container = testContainer(
      auth: auth,
      merchant: merchant,
      store: store,
    );
    addTearDown(container.dispose);
    container.read(tokenCacheProvider).current = store.value;
    await restoreAndResolve(container);
    expect(
      container.read(accessControllerProvider).destination,
      AccessDestination.home,
    );
    expect(container.read(accessControllerProvider).selectedBranch?.id, 'b1');
    expect(container.read(sessionControllerProvider).phase, SessionPhase.ready);
  });

  test('multiple branches require picker', () async {
    final auth = FakeAuthApi();
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(branches: [branch('b1'), branch('b2')]),
        ],
      ),
    );
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final container = testContainer(
      auth: auth,
      merchant: merchant,
      store: store,
    );
    addTearDown(container.dispose);
    container.read(tokenCacheProvider).current = store.value;
    await restoreAndResolve(container);
    expect(
      container.read(accessControllerProvider).destination,
      AccessDestination.selectBranch,
    );
  });

  test('permission denied maps destination', () async {
    final auth = FakeAuthApi();
    final merchant = FakeMerchantApi(
      meHandler: () async {
        throw const ApiException('forbidden', code: 'MERCHANT_ROLE_FORBIDDEN');
      },
    );
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final container = testContainer(
      auth: auth,
      merchant: merchant,
      store: store,
    );
    addTearDown(container.dispose);
    container.read(tokenCacheProvider).current = store.value;
    await restoreAndResolve(container);
    expect(
      container.read(accessControllerProvider).destination,
      AccessDestination.permissionDenied,
    );
  });

  test('pending review never reaches home', () async {
    final auth = FakeAuthApi();
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(
            status: 'PENDING_REVIEW',
            approved: false,
            operationalReady: false,
            verificationSubmitted: true,
            branches: [branch('b1')],
          ),
        ],
      ),
    );
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final container = testContainer(
      auth: auth,
      merchant: merchant,
      store: store,
    );
    addTearDown(container.dispose);
    container.read(tokenCacheProvider).current = store.value;
    await restoreAndResolve(container);
    expect(
      container.read(accessControllerProvider).destination,
      AccessDestination.verificationPending,
    );
    expect(
      container.read(sessionControllerProvider).phase,
      isNot(SessionPhase.ready),
    );
  });

  test(
    'refreshInPlace stays on verification pending (no loading hop)',
    () async {
      final auth = FakeAuthApi();
      var meCalls = 0;
      final merchant = FakeMerchantApi(
        meHandler: () async {
          meCalls++;
          return MerchantMe(
            merchantMembershipExists: true,
            memberships: [
              membership(
                status: 'PENDING_REVIEW',
                approved: false,
                operationalReady: false,
                verificationSubmitted: true,
                branches: [branch('b1')],
              ),
            ],
          );
        },
      );
      final store = MemorySessionStore()
        ..value = const TokenPair(
          accessToken: 'a',
          refreshToken: 'r-token-value',
          expiresIn: 900,
          tokenType: 'Bearer',
        );
      final container = testContainer(
        auth: auth,
        merchant: merchant,
        store: store,
      );
      addTearDown(container.dispose);
      container.read(tokenCacheProvider).current = store.value;
      await restoreAndResolve(container);
      expect(
        container.read(accessControllerProvider).destination,
        AccessDestination.verificationPending,
      );
      final seen = <AccessDestination>[];
      final sub = container.listen(accessControllerProvider, (prev, next) {
        seen.add(next.destination);
      });
      addTearDown(sub.close);
      await container.read(accessControllerProvider.notifier).refreshInPlace();
      expect(meCalls, greaterThanOrEqualTo(2));
      expect(
        container.read(accessControllerProvider).destination,
        AccessDestination.verificationPending,
      );
      expect(seen, isNot(contains(AccessDestination.loading)));
      expect(
        seen.every((d) => d == AccessDestination.verificationPending),
        isTrue,
      );
    },
  );

  test('incomplete pending dossier resumes registration', () async {
    final auth = FakeAuthApi();
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(
            status: 'PENDING_REVIEW',
            approved: false,
            operationalReady: false,
            verificationSubmitted: false,
            branches: [branch('b1')],
          ),
        ],
      ),
    );
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final container = testContainer(
      auth: auth,
      merchant: merchant,
      store: store,
    );
    addTearDown(container.dispose);
    container.read(tokenCacheProvider).current = store.value;
    await restoreAndResolve(container);
    expect(
      container.read(accessControllerProvider).destination,
      AccessDestination.registration,
    );
  });

  test(
    'orders scope to selected branch and ignore stale generations',
    () async {
      final auth = FakeAuthApi();
      final merchant = FakeMerchantApi(
        meHandler: () async => MerchantMe(
          merchantMembershipExists: true,
          memberships: [
            membership(branches: [branch('b1'), branch('b2')]),
          ],
        ),
        ordersHandler:
            ({
              required merchantId,
              branchId,
              orderStatus,
              fulfillmentStatus,
              limit = 50,
              offset = 0,
            }) async {
              return MerchantOrderListPage(
                items: [
                  MerchantOrderSummary(
                    id: 'o-$branchId',
                    publicReference: 'REF-$branchId',
                    status: 'CREATED',
                    fulfillmentStatus: 'PENDING_ACCEPTANCE',
                    merchantBranchId: branchId ?? '',
                    createdAt: '2026-01-01T00:00:00Z',
                  ),
                ],
                limit: limit,
                offset: offset,
                total: 1,
              );
            },
      );
      final store = MemorySessionStore()
        ..value = const TokenPair(
          accessToken: 'a',
          refreshToken: 'r-token-value',
          expiresIn: 900,
          tokenType: 'Bearer',
        );
      final container = testContainer(
        auth: auth,
        merchant: merchant,
        store: store,
      );
      addTearDown(container.dispose);
      container.read(tokenCacheProvider).current = store.value;
      await restoreAndResolve(container);

      await container
          .read(accessControllerProvider.notifier)
          .selectBranch(branch('b1'));
      final forB1 = await container.read(ordersListControllerProvider.future);
      expect(forB1.items.single.merchantBranchId, 'b1');
      expect(merchant.orderCalls.last.startsWith('m-1:b1:'), isTrue);

      await container
          .read(accessControllerProvider.notifier)
          .selectBranch(branch('b2'));
      final forB2 = await container.read(ordersListControllerProvider.future);
      expect(forB2.items.single.merchantBranchId, 'b2');
      expect(merchant.orderCalls.last.startsWith('m-1:b2:'), isTrue);
    },
  );

  testWidgets('home empty orders and tab navigation', (tester) async {
    final auth = FakeAuthApi();
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(branches: [branch('b1')]),
        ],
      ),
    );
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final container = testContainer(
      auth: auth,
      merchant: merchant,
      store: store,
    );
    addTearDown(container.dispose);
    container.read(tokenCacheProvider).current = store.value;

    await pumpApp(tester, container);
    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
    expect(find.byKey(const Key('home-count-incoming')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-orders')));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text(AppStrings.ordersEmptyIncoming), findsOneWidget);

    await tester.tap(find.text(AppStrings.tabCatalog));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const Key('catalog-screen')), findsOneWidget);
    expect(find.text(AppStrings.catalogEmptyProducts), findsOneWidget);

    await tester.tap(find.text(AppStrings.tabProfile));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const Key('store-profile-screen')), findsOneWidget);

    await tester.tap(find.text(AppStrings.tabHome));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const Key('home-branch-name')), findsOneWidget);
  });

  test('orders list surfaces recoverable errors', () async {
    final auth = FakeAuthApi();
    final merchant = FakeMerchantApi(
      meHandler: () async => MerchantMe(
        merchantMembershipExists: true,
        memberships: [
          membership(branches: [branch('b1')]),
        ],
      ),
      ordersHandler:
          ({
            required merchantId,
            branchId,
            orderStatus,
            fulfillmentStatus,
            limit = 50,
            offset = 0,
          }) async {
            throw const ApiException('boom', code: 'NETWORK');
          },
    );
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'a',
        refreshToken: 'r-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final container = testContainer(
      auth: auth,
      merchant: merchant,
      store: store,
    );
    addTearDown(container.dispose);
    container.read(tokenCacheProvider).current = store.value;
    await restoreAndResolve(container);

    // Force evaluation without awaiting a hanging .future on error.
    container.listen(ordersListControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final async = container.read(ordersListControllerProvider);
    expect(async.hasError, isTrue);
  });
}
