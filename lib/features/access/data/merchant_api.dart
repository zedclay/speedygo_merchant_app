import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:speedygo_merchant_app/core/constants/app_constants.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';
import 'package:speedygo_merchant_app/core/network/api_error_parser.dart';
import 'package:speedygo_merchant_app/features/access/data/geo_models.dart';
import 'package:speedygo_merchant_app/features/access/data/models.dart';
import 'package:speedygo_merchant_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_merchant_app/features/reports/data/reports_models.dart';
import 'package:speedygo_merchant_app/features/store/data/classification_models.dart';
import 'package:speedygo_merchant_app/features/store/data/store_models.dart';
import 'package:speedygo_merchant_app/features/support/data/support_models.dart';
import 'package:speedygo_merchant_app/features/team/data/team_models.dart';

class EvidenceUploadResult {
  const EvidenceUploadResult({
    required this.uploadReference,
    required this.contentType,
    required this.sizeBytes,
    required this.purpose,
  });

  final String uploadReference;
  final String contentType;
  final int sizeBytes;
  final String purpose;

  factory EvidenceUploadResult.fromJson(Map<String, dynamic> json) {
    return EvidenceUploadResult(
      uploadReference: json['uploadReference']?.toString() ?? '',
      contentType: json['contentType']?.toString() ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      purpose: json['purpose']?.toString() ?? '',
    );
  }
}

class MediaBindResult {
  const MediaBindResult({
    required this.imageUrl,
    required this.contentType,
    this.widthPx,
    this.heightPx,
  });

  /// Relative API path (typically customer-authenticated stream).
  final String imageUrl;
  final String contentType;
  final int? widthPx;
  final int? heightPx;

  factory MediaBindResult.fromJson(Map<String, dynamic> json) {
    return MediaBindResult(
      imageUrl:
          (json['imageUrl'] ?? json['coverImageUrl'] ?? json['logoImageUrl'])
              ?.toString() ??
          '',
      contentType: json['contentType']?.toString() ?? '',
      widthPx: (json['widthPx'] as num?)?.toInt(),
      heightPx: (json['heightPx'] as num?)?.toInt(),
    );
  }
}

abstract class MerchantClient {
  Future<MerchantMe> me();
  Future<MerchantMembership> createProfile({required String name});
  Future<MerchantMembership> updateProfile({
    required String merchantId,
    required String name,
  });
  Future<MerchantBranch> createBranch({
    required String merchantId,
    required String name,
    required String phone,
    required String addressText,
    required double latitude,
    required double longitude,
    required String wilayaCode,
    required int communeId,
  });
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
  });

  /// `GET /merchant/commerce-verticals` (server-managed list).
  Future<List<CommerceVertical>> listCommerceVerticals();

  /// `GET …/branches/:branchId/classification`; null when none is assigned.
  Future<BranchClassification?> getBranchClassification({
    required String merchantId,
    required String branchId,
  });

  /// `PUT …/classification` with `{ verticalId }` (single vertical, 0..1).
  Future<BranchClassification> putBranchClassification({
    required String merchantId,
    required String branchId,
    required String verticalId,
  });

  /// `DELETE …/classification` unsets the vertical.
  Future<void> deleteBranchClassification({
    required String merchantId,
    required String branchId,
  });
  Future<List<AlgeriaWilaya>> listWilayas();
  Future<List<AlgeriaCommune>> listCommunes({
    required String wilayaCode,
    String? q,
  });
  Future<MerchantOrderListPage> listOrders({
    required String merchantId,
    String? branchId,
    String? orderStatus,
    String? fulfillmentStatus,
    int limit = 50,
    int offset = 0,
  });
  Future<MerchantOrderDetail> getOrder({
    required String merchantId,
    required String orderId,
  });
  Future<MerchantOrderDetail> acceptOrder({
    required String merchantId,
    required String orderId,
    int? preparationMinutes,
  });
  Future<MerchantOrderDetail> updatePreparationEstimate({
    required String merchantId,
    required String orderId,
    required int addMinutes,
    required int expectedEstimateVersion,
    String? reason,
  });
  Future<MerchantOrderDetail> rejectOrder({
    required String merchantId,
    required String orderId,
    required String reason,
    String? reasonCode,
  });
  Future<MerchantOrderDetail> startPreparation({
    required String merchantId,
    required String orderId,
  });
  Future<MerchantOrderDetail> markReady({
    required String merchantId,
    required String orderId,
  });
  Future<MerchantDeliverySummary?> getOrderDelivery({
    required String merchantId,
    required String orderId,
  });

  Future<MerchantPickupHandoff> getPickupHandoff({
    required String merchantId,
    required String orderId,
  });

  Future<MerchantPickupHandoff> regeneratePickupHandoff({
    required String merchantId,
    required String orderId,
  });

  /// `POST /merchant/:merchantId/support` (OWNER/MANAGER). Returns the ticket
  /// `publicReference`.
  Future<String> createSupportTicket({
    required String merchantId,
    required String subject,
    required String topicCode,
    required String body,
    String? orderId,
  });

  /// `GET /merchant/:merchantId/support/topics` (OWNER/MANAGER).
  Future<List<SupportTopic>> listSupportTopics({required String merchantId});

  /// `GET /merchant/:merchantId/support/faq` (OWNER/MANAGER).
  Future<List<SupportFaqArticle>> listSupportFaq({required String merchantId});

  /// `GET /merchant/:merchantId/support` (OWNER/MANAGER).
  Future<SupportTicketPage> listSupportTickets({
    required String merchantId,
    int limit = 50,
    int offset = 0,
  });

  /// `GET /merchant/:merchantId/support/:ticketId` (no internal notes).
  Future<SupportTicketDetail> getSupportTicket({
    required String merchantId,
    required String ticketId,
  });

  /// `POST /merchant/:merchantId/support/:ticketId/messages`.
  Future<SupportMessage> replySupportTicket({
    required String merchantId,
    required String ticketId,
    required String body,
  });

  /// `GET /merchant/legal/current` — active versions to accept on submit.
  Future<LegalCurrent> getLegalCurrent();

  /// `POST /merchant/:merchantId/verification/submit`. [acceptances] must carry
  /// the exact active versions from [getLegalCurrent]; otherwise the server
  /// answers `LEGAL_ACCEPTANCE_REQUIRED` / `LEGAL_VERSION_OUTDATED`.
  Future<void> submitVerification(
    String merchantId, {
    required List<LegalAcceptance> acceptances,
  });
  Future<EvidenceUploadResult> uploadEvidenceContent({
    required String merchantId,
    required String type,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  });
  Future<MerchantMembership> bindEvidence({
    required String merchantId,
    required String type,
    required String uploadReference,
    String? expiryDate,
  });
  Future<CatalogBootstrap> getCatalogBootstrap({
    required String merchantId,
    required String branchId,
  });
  Future<List<CatalogCategory>> listCategories({
    required String merchantId,
    required String branchId,
  });
  Future<List<CatalogProduct>> listProducts({
    required String merchantId,
    required String branchId,
    String? categoryId,
  });
  Future<CatalogProduct> updateProductAvailability({
    required String merchantId,
    required String productId,
    required bool available,
  });
  Future<CatalogProduct> getProduct({
    required String merchantId,
    required String productId,
  });
  Future<CatalogProduct> createProduct({
    required String merchantId,
    required String branchId,
    required String categoryId,
    required String name,
    String? description,
    required int priceMinor,
    bool available = true,
    SellingUnitSelection? sellingUnit,
  });

  /// [sellingUnit] null leaves the unit untouched; [SellingUnitSelection.none]
  /// clears it.
  Future<CatalogProduct> updateProduct({
    required String merchantId,
    required String productId,
    String? categoryId,
    String? name,
    String? description,
    int? priceMinor,
    bool? available,
    SellingUnitSelection? sellingUnit,
  });
  Future<void> deleteProduct({
    required String merchantId,
    required String productId,
  });

  /// One server transaction; [requestId] makes retries return the same copy.
  Future<ProductDuplicateResult> duplicateProduct({
    required String merchantId,
    required String productId,
    required String requestId,
    String? name,
  });
  Future<CatalogCategory> createCategory({
    required String merchantId,
    required String branchId,
    required String name,
    int? sortOrder,
    bool active = true,
  });
  Future<CatalogCategory> updateCategory({
    required String merchantId,
    required String categoryId,
    String? name,
    int? sortOrder,
    bool? active,
  });
  Future<void> deleteCategory({
    required String merchantId,
    required String categoryId,
  });
  Future<List<CatalogOptionGroup>> listOptionGroups({
    required String merchantId,
    required String productId,
  });
  Future<CatalogOptionGroup> createOptionGroup({
    required String merchantId,
    required String productId,
    required String name,
    required bool required,
    required int minSelections,
    required int maxSelections,
  });
  Future<CatalogOptionGroup> updateOptionGroup({
    required String merchantId,
    required String productId,
    required String groupId,
    String? name,
    bool? required,
    int? minSelections,
    int? maxSelections,
  });
  Future<void> deleteOptionGroup({
    required String merchantId,
    required String productId,
    required String groupId,
  });
  Future<CatalogOption> createOption({
    required String merchantId,
    required String productId,
    required String groupId,
    required String name,
    required int additionalPriceMinor,
    bool available = true,
  });
  Future<CatalogOption> updateOption({
    required String merchantId,
    required String productId,
    required String groupId,
    required String optionId,
    String? name,
    int? additionalPriceMinor,
    bool? available,
  });
  Future<void> deleteOption({
    required String merchantId,
    required String productId,
    required String groupId,
    required String optionId,
  });
  Future<EvidenceUploadResult> uploadProductImageContent({
    required String merchantId,
    required String branchId,
    required String productId,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  });
  Future<MediaBindResult> bindProductImage({
    required String merchantId,
    required String branchId,
    required String productId,
    required String uploadReference,
  });
  Future<void> deleteProductImage({
    required String merchantId,
    required String branchId,
    required String productId,
  });
  Future<Uint8List?> fetchProductImageBytes({
    required String merchantId,
    required String branchId,
    required String productId,
  });
  Future<EvidenceUploadResult> uploadBranchCoverContent({
    required String merchantId,
    required String branchId,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  });
  Future<MediaBindResult> bindBranchCover({
    required String merchantId,
    required String branchId,
    required String uploadReference,
  });
  Future<void> deleteBranchCover({
    required String merchantId,
    required String branchId,
  });
  Future<Uint8List?> fetchBranchCoverBytes({
    required String merchantId,
    required String branchId,
  });
  Future<EvidenceUploadResult> uploadBranchLogoContent({
    required String merchantId,
    required String branchId,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  });
  Future<MediaBindResult> bindBranchLogo({
    required String merchantId,
    required String branchId,
    required String uploadReference,
  });
  Future<void> deleteBranchLogo({
    required String merchantId,
    required String branchId,
  });

  /// Null when no logo is bound (404).
  Future<Uint8List?> fetchBranchLogoBytes({
    required String merchantId,
    required String branchId,
  });
  Future<MerchantRatingSummary> ratingsSummary({required String merchantId});
  Future<List<MerchantSettlementSummary>> listSettlements({
    required String merchantId,
  });
  Future<MerchantSalesSummary> salesSummary({
    required String merchantId,
    required ReportPeriodSelection period,
    String? branchId,
  });
  Future<MerchantTopProducts> topProducts({
    required String merchantId,
    required ReportPeriodSelection period,
    String? branchId,
    TopProductSort sort = TopProductSort.orders,
    int limit = 5,
  });
  Future<MerchantDailySummary> dailySummary({
    required String merchantId,
    String? date,
    String? branchId,
  });
  Future<OpeningHoursSchedule> getOpeningHours({
    required String merchantId,
    required String branchId,
  });
  Future<OpeningHoursSchedule> putOpeningHours({
    required String merchantId,
    required String branchId,
    required int expectedVersion,
    required List<OpeningDay> days,
  });
  Future<OpeningHoursExceptionList> listOpeningHoursExceptions({
    required String merchantId,
    required String branchId,
  });

  /// [expectedVersion] 0 creates the date; otherwise it must match.
  Future<OpeningHoursException> putOpeningHoursException({
    required String merchantId,
    required String branchId,
    required String date,
    required int expectedVersion,
    required bool closed,
    required List<OpeningInterval> intervals,
    required String label,
    String? customerMessage,
  });
  Future<void> deleteOpeningHoursException({
    required String merchantId,
    required String branchId,
    required String date,
    required int expectedVersion,
  });
  Future<BranchAvailabilityState> getAvailability({
    required String merchantId,
    required String branchId,
  });
  Future<BranchAvailabilityState> putAvailability({
    required String merchantId,
    required String branchId,
    required int expectedVersion,
    required String mode,
    String? reasonCode,
    String? customerMessage,
    String? closedUntil,
  });
  Future<List<MerchantNotificationItem>> listNotifications({
    int limit = 50,
    int offset = 0,
  });
  Future<int> notificationsUnreadCount();
  Future<void> markNotificationRead(String notificationId);
  Future<int> markAllNotificationsRead();
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  });
  Future<void> deactivateDeviceToken({required String token});

  /// `GET /merchant/:merchantId/team` (OWNER/MANAGER; STAFF gets 403).
  Future<MerchantTeam> getTeam({required String merchantId});

  /// `POST …/team/invitations` (OWNER). The response carries the one-time
  /// `acceptCode`; nothing is delivered by SMS or e-mail.
  Future<TeamInvitationIssued> createTeamInvitation({
    required String merchantId,
    required String phone,
    required String role,
  });

  /// `POST …/team/invitations/:id/cancel` (OWNER).
  Future<TeamInvitation> cancelTeamInvitation({
    required String merchantId,
    required String invitationId,
    required int expectedVersion,
  });

  /// `POST …/team/invitations/:id/regenerate-code` (OWNER). The previous
  /// code stops working.
  Future<TeamInvitationIssued> regenerateTeamInvitationCode({
    required String merchantId,
    required String invitationId,
    required int expectedVersion,
  });

  /// `PATCH …/team/members/:id` (OWNER): MANAGER <-> STAFF only.
  Future<TeamMember> updateTeamMemberRole({
    required String merchantId,
    required String memberId,
    required String role,
    required int expectedVersion,
  });

  /// `DELETE …/team/members/:id?expectedVersion=` (OWNER).
  Future<void> revokeTeamMember({
    required String merchantId,
    required String memberId,
    required int expectedVersion,
  });

  /// `GET /merchant/me/team-invitations` (phone-bound).
  Future<List<MyTeamInvitation>> listMyTeamInvitations();

  /// `POST /merchant/me/team-invitations/:id/accept` (phone-bound).
  Future<TeamInvitationAccepted> acceptTeamInvitation({
    required String invitationId,
    required String acceptCode,
  });
}

class MerchantApi implements MerchantClient {
  MerchantApi(this._dio);
  final Dio _dio;

  static const _productPageSize = 100;
  static const _productMaxOffset = 10000;
  static const _productMaxPages = 20;

  @override
  Future<MerchantMe> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantMePath,
      );
      return MerchantMe.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantMembership> createProfile({required String name}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantProfile,
        data: {'name': name},
      );
      return MerchantMembership.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantMembership> updateProfile({
    required String merchantId,
    required String name,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.merchantProfileUpdate(merchantId),
        data: {'name': name},
      );
      return MerchantMembership.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
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
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantBranches(merchantId),
        data: {
          'name': name,
          'phone': phone,
          'addressText': addressText,
          'latitude': latitude,
          'longitude': longitude,
          'wilayaCode': wilayaCode,
          'communeId': communeId,
        },
      );
      return MerchantBranch.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
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
    try {
      final data = <String, dynamic>{
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (addressText != null) 'addressText': addressText,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (wilayaCode != null) 'wilayaCode': wilayaCode,
        if (communeId != null) 'communeId': communeId,
        ...?publicInfo,
      };
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.merchantBranch(merchantId, branchId),
        data: data,
      );
      return MerchantBranch.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<CommerceVertical>> listCommerceVerticals() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantCommerceVerticals,
      );
      final raw = response.data?['items'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => CommerceVertical.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<BranchClassification?> getBranchClassification({
    required String merchantId,
    required String branchId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.merchantBranchClassification(merchantId, branchId),
      );
      return BranchClassification.tryParse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw mapDioError(e);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<BranchClassification> putBranchClassification({
    required String merchantId,
    required String branchId,
    required String verticalId,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        ApiEndpoints.merchantBranchClassification(merchantId, branchId),
        data: {'verticalId': verticalId},
      );
      return BranchClassification.tryParse(response.data) ??
          BranchClassification(
            verticalId: verticalId,
            slug: '',
            name: '',
            iconKey: null,
          );
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> deleteBranchClassification({
    required String merchantId,
    required String branchId,
  }) async {
    try {
      await _dio.delete(
        ApiEndpoints.merchantBranchClassification(merchantId, branchId),
      );
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<AlgeriaWilaya>> listWilayas() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.geoWilayas,
      );
      final raw = response.data?['wilayas'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((row) => AlgeriaWilaya.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<AlgeriaCommune>> listCommunes({
    required String wilayaCode,
    String? q,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.geoCommunes(wilayaCode),
        queryParameters: {if (q != null && q.trim().isNotEmpty) 'q': q.trim()},
      );
      final raw = response.data?['communes'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((row) => AlgeriaCommune.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (e) {
      throw mapDioError(e);
    }
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
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantOrders(merchantId),
        queryParameters: {
          if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
          if (orderStatus != null && orderStatus.isNotEmpty)
            'orderStatus': orderStatus,
          if (fulfillmentStatus != null && fulfillmentStatus.isNotEmpty)
            'fulfillmentStatus': fulfillmentStatus,
          'limit': limit,
          'offset': offset,
        },
      );
      return MerchantOrderListPage.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantOrderDetail> getOrder({
    required String merchantId,
    required String orderId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantOrder(merchantId, orderId),
      );
      return MerchantOrderDetail.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantOrderDetail> acceptOrder({
    required String merchantId,
    required String orderId,
    int? preparationMinutes,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantOrderAccept(merchantId, orderId),
        data: {
          if (preparationMinutes != null)
            'preparationMinutes': preparationMinutes,
        },
      );
      return MerchantOrderDetail.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantOrderDetail> updatePreparationEstimate({
    required String merchantId,
    required String orderId,
    required int addMinutes,
    required int expectedEstimateVersion,
    String? reason,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantOrderPreparationEstimate(merchantId, orderId),
        data: {
          'addMinutes': addMinutes,
          'expectedEstimateVersion': expectedEstimateVersion,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
      );
      return MerchantOrderDetail.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantOrderDetail> rejectOrder({
    required String merchantId,
    required String orderId,
    required String reason,
    String? reasonCode,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantOrderReject(merchantId, orderId),
        data: {
          'reason': reason,
          if (reasonCode != null) 'reasonCode': reasonCode,
        },
      );
      return MerchantOrderDetail.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<String> createSupportTicket({
    required String merchantId,
    required String subject,
    required String topicCode,
    required String body,
    String? orderId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantSupport(merchantId),
        data: {
          'subject': subject,
          'topicCode': topicCode,
          'body': body,
          'orderId': ?orderId,
        },
      );
      return response.data?['publicReference']?.toString() ?? '';
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<SupportTopic>> listSupportTopics({
    required String merchantId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.merchantSupportTopics(merchantId),
      );
      return _maps(response.data, const [
        'items',
        'topics',
      ]).map(SupportTopic.fromJson).where((t) => t.code.isNotEmpty).toList();
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<SupportFaqArticle>> listSupportFaq({
    required String merchantId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.merchantSupportFaq(merchantId),
      );
      return _maps(response.data, const [
        'items',
        'articles',
        'faq',
      ]).map(SupportFaqArticle.fromJson).toList();
    } catch (e) {
      throw mapDioError(e);
    }
  }

  /// Rows of a list response that is either a bare array or wrapped under one
  /// of [keys].
  static List<Map<String, dynamic>> _maps(Object? data, List<String> keys) {
    Object? raw = data;
    if (data is Map) {
      raw = null;
      for (final key in keys) {
        if (data[key] is List) {
          raw = data[key];
          break;
        }
      }
    }
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  @override
  Future<SupportTicketPage> listSupportTickets({
    required String merchantId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantSupport(merchantId),
        queryParameters: {'limit': limit, 'offset': offset},
      );
      return SupportTicketPage.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<SupportTicketDetail> getSupportTicket({
    required String merchantId,
    required String ticketId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantSupportTicket(merchantId, ticketId),
      );
      return SupportTicketDetail.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<SupportMessage> replySupportTicket({
    required String merchantId,
    required String ticketId,
    required String body,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantSupportMessages(merchantId, ticketId),
        data: {'body': body},
      );
      return SupportMessage.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantOrderDetail> startPreparation({
    required String merchantId,
    required String orderId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantOrderStartPreparation(merchantId, orderId),
        data: const <String, dynamic>{},
      );
      return MerchantOrderDetail.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantOrderDetail> markReady({
    required String merchantId,
    required String orderId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantOrderMarkReady(merchantId, orderId),
        data: const <String, dynamic>{},
      );
      return MerchantOrderDetail.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantDeliverySummary?> getOrderDelivery({
    required String merchantId,
    required String orderId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantOrderDelivery(merchantId, orderId),
      );
      return MerchantDeliverySummary.fromJson(response.data ?? {});
    } on ApiException catch (e) {
      // DELIVERY_NOT_FOUND is expected until matching starts.
      if (e.statusCode == 404) return null;
      rethrow;
    } catch (e) {
      final mapped = mapDioError(e);
      if (mapped is ApiException && mapped.statusCode == 404) return null;
      throw mapped;
    }
  }

  @override
  Future<MerchantPickupHandoff> getPickupHandoff({
    required String merchantId,
    required String orderId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantOrderPickupHandoff(merchantId, orderId),
      );
      return MerchantPickupHandoff.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantPickupHandoff> regeneratePickupHandoff({
    required String merchantId,
    required String orderId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantOrderPickupHandoffRegenerate(merchantId, orderId),
        data: const <String, dynamic>{},
      );
      return MerchantPickupHandoff.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<LegalCurrent> getLegalCurrent() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantLegalCurrent,
      );
      return LegalCurrent.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> submitVerification(
    String merchantId, {
    required List<LegalAcceptance> acceptances,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantVerificationSubmit(merchantId),
        data: {'acceptances': acceptances.map((a) => a.toJson()).toList()},
      );
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<EvidenceUploadResult> uploadEvidenceContent({
    required String merchantId,
    required String type,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(contentType),
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantEvidenceContent(merchantId, type),
        data: form,
      );
      return EvidenceUploadResult.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantMembership> bindEvidence({
    required String merchantId,
    required String type,
    required String uploadReference,
    String? expiryDate,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.merchantEvidenceBind(merchantId, type),
        data: {
          'uploadReference': uploadReference,
          if (expiryDate != null && expiryDate.isNotEmpty)
            'expiryDate': expiryDate,
        },
      );
      return MerchantMembership.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<CatalogBootstrap> getCatalogBootstrap({
    required String merchantId,
    required String branchId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantCatalog(merchantId),
        queryParameters: {'branchId': branchId},
      );
      return CatalogBootstrap.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<CatalogCategory>> listCategories({
    required String merchantId,
    required String branchId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantCategories(merchantId),
        queryParameters: {'branchId': branchId},
      );
      final raw = response.data?['categories'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => CatalogCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<CatalogProduct>> listProducts({
    required String merchantId,
    required String branchId,
    String? categoryId,
  }) async {
    try {
      final products = <CatalogProduct>[];
      var offset = 0;
      while (true) {
        final response = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.merchantProducts(merchantId),
          queryParameters: {
            'branchId': branchId,
            if (categoryId != null && categoryId.isNotEmpty)
              'categoryId': categoryId,
            'limit': _productPageSize,
            'offset': offset,
          },
        );
        final raw = response.data?['items'] ?? response.data?['products'];
        if (raw is! List || raw.isEmpty) break;
        products.addAll(
          raw.whereType<Map>().map(
            (e) => CatalogProduct.fromJson(Map<String, dynamic>.from(e)),
          ),
        );
        offset += raw.length;
        final pages = (offset / _productPageSize).ceil();
        final total = (response.data?['total'] as num?)?.toInt();
        if (total == null ||
            offset >= total ||
            offset > _productMaxOffset ||
            pages >= _productMaxPages) {
          break;
        }
      }
      return products;
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<CatalogProduct> updateProductAvailability({
    required String merchantId,
    required String productId,
    required bool available,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.merchantProduct(merchantId, productId),
        data: {'available': available},
      );
      return CatalogProduct.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<CatalogProduct> getProduct({
    required String merchantId,
    required String productId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantProduct(merchantId, productId),
      );
      return CatalogProduct.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
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
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantProducts(merchantId),
        data: {
          'branchId': branchId,
          'categoryId': categoryId,
          'name': name,
          if (description != null) 'description': description,
          'priceMinor': priceMinor,
          'available': available,
          if (sellingUnit != null && !sellingUnit.isNone) ...{
            'sellingUnitCode': sellingUnit.code,
            'sellingUnitLabelFr': sellingUnit.labelFr,
          },
        },
      );
      return CatalogProduct.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
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
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.merchantProduct(merchantId, productId),
        data: {
          if (categoryId != null) 'categoryId': categoryId,
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (priceMinor != null) 'priceMinor': priceMinor,
          if (available != null) 'available': available,
          if (sellingUnit != null) ...{
            'sellingUnitCode': sellingUnit.code,
            'sellingUnitLabelFr': sellingUnit.labelFr,
          },
        },
      );
      return CatalogProduct.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> deleteProduct({
    required String merchantId,
    required String productId,
  }) async {
    try {
      await _dio.delete(ApiEndpoints.merchantProduct(merchantId, productId));
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<ProductDuplicateResult> duplicateProduct({
    required String merchantId,
    required String productId,
    required String requestId,
    String? name,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantProductDuplicate(merchantId, productId),
        data: {'requestId': requestId, if (name != null) 'name': name},
      );
      return ProductDuplicateResult.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<CatalogCategory> createCategory({
    required String merchantId,
    required String branchId,
    required String name,
    int? sortOrder,
    bool active = true,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantCategories(merchantId),
        data: {
          'branchId': branchId,
          'name': name,
          if (sortOrder != null) 'sortOrder': sortOrder,
          'active': active,
        },
      );
      return CatalogCategory.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<CatalogCategory> updateCategory({
    required String merchantId,
    required String categoryId,
    String? name,
    int? sortOrder,
    bool? active,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.merchantCategory(merchantId, categoryId),
        data: {
          if (name != null) 'name': name,
          if (sortOrder != null) 'sortOrder': sortOrder,
          if (active != null) 'active': active,
        },
      );
      return CatalogCategory.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> deleteCategory({
    required String merchantId,
    required String categoryId,
  }) async {
    try {
      await _dio.delete(ApiEndpoints.merchantCategory(merchantId, categoryId));
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<CatalogOptionGroup>> listOptionGroups({
    required String merchantId,
    required String productId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantOptionGroups(merchantId, productId),
      );
      final raw = response.data?['optionGroups'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => CatalogOptionGroup.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw mapDioError(e);
    }
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
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantOptionGroups(merchantId, productId),
        data: {
          'name': name,
          'required': required,
          'minSelections': minSelections,
          'maxSelections': maxSelections,
        },
      );
      return CatalogOptionGroup.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
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
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.merchantOptionGroup(merchantId, productId, groupId),
        data: {
          'name': ?name,
          'required': ?required,
          'minSelections': ?minSelections,
          'maxSelections': ?maxSelections,
        },
      );
      return CatalogOptionGroup.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> deleteOptionGroup({
    required String merchantId,
    required String productId,
    required String groupId,
  }) async {
    try {
      await _dio.delete(
        ApiEndpoints.merchantOptionGroup(merchantId, productId, groupId),
      );
    } catch (e) {
      throw mapDioError(e);
    }
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
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantOptions(merchantId, productId, groupId),
        data: {
          'name': name,
          'additionalPriceMinor': additionalPriceMinor,
          'available': available,
        },
      );
      return CatalogOption.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
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
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.merchantOption(merchantId, productId, groupId, optionId),
        data: {
          'name': ?name,
          'additionalPriceMinor': ?additionalPriceMinor,
          'available': ?available,
        },
      );
      return CatalogOption.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> deleteOption({
    required String merchantId,
    required String productId,
    required String groupId,
    required String optionId,
  }) async {
    try {
      await _dio.delete(
        ApiEndpoints.merchantOption(merchantId, productId, groupId, optionId),
      );
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<EvidenceUploadResult> uploadProductImageContent({
    required String merchantId,
    required String branchId,
    required String productId,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(contentType),
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantProductImageContent(
          merchantId,
          branchId,
          productId,
        ),
        data: form,
      );
      return EvidenceUploadResult.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MediaBindResult> bindProductImage({
    required String merchantId,
    required String branchId,
    required String productId,
    required String uploadReference,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.merchantProductImage(merchantId, branchId, productId),
        data: {'uploadReference': uploadReference},
      );
      return MediaBindResult.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> deleteProductImage({
    required String merchantId,
    required String branchId,
    required String productId,
  }) async {
    try {
      await _dio.delete(
        ApiEndpoints.merchantProductImage(merchantId, branchId, productId),
      );
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<Uint8List?> fetchProductImageBytes({
    required String merchantId,
    required String branchId,
    required String productId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.merchantProductImage(merchantId, branchId, productId),
        options: Options(responseType: ResponseType.bytes),
      );
      return _bytesFromResponse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw mapDioError(e);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<EvidenceUploadResult> uploadBranchCoverContent({
    required String merchantId,
    required String branchId,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(contentType),
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantBranchCoverContent(merchantId, branchId),
        data: form,
      );
      return EvidenceUploadResult.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MediaBindResult> bindBranchCover({
    required String merchantId,
    required String branchId,
    required String uploadReference,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.merchantBranchCover(merchantId, branchId),
        data: {'uploadReference': uploadReference},
      );
      return MediaBindResult.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> deleteBranchCover({
    required String merchantId,
    required String branchId,
  }) async {
    try {
      await _dio.delete(ApiEndpoints.merchantBranchCover(merchantId, branchId));
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<Uint8List?> fetchBranchCoverBytes({
    required String merchantId,
    required String branchId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.merchantBranchCover(merchantId, branchId),
        options: Options(responseType: ResponseType.bytes),
      );
      return _bytesFromResponse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw mapDioError(e);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  static Uint8List? _bytesFromResponse(dynamic data) {
    if (data == null) return null;
    if (data is Uint8List) {
      return data.isEmpty ? null : data;
    }
    if (data is List<int>) {
      if (data.isEmpty) return null;
      return Uint8List.fromList(data);
    }
    return null;
  }

  @override
  Future<EvidenceUploadResult> uploadBranchLogoContent({
    required String merchantId,
    required String branchId,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(contentType),
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantBranchLogoContent(merchantId, branchId),
        data: form,
      );
      return EvidenceUploadResult.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MediaBindResult> bindBranchLogo({
    required String merchantId,
    required String branchId,
    required String uploadReference,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.merchantBranchLogo(merchantId, branchId),
        data: {'uploadReference': uploadReference},
      );
      return MediaBindResult.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> deleteBranchLogo({
    required String merchantId,
    required String branchId,
  }) async {
    try {
      await _dio.delete(ApiEndpoints.merchantBranchLogo(merchantId, branchId));
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<Uint8List?> fetchBranchLogoBytes({
    required String merchantId,
    required String branchId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.merchantBranchLogo(merchantId, branchId),
        options: Options(responseType: ResponseType.bytes),
      );
      return _bytesFromResponse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw mapDioError(e);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantRatingSummary> ratingsSummary({
    required String merchantId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantRatingsSummary(merchantId),
      );
      return MerchantRatingSummary.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<MerchantSettlementSummary>> listSettlements({
    required String merchantId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.merchantSettlements(merchantId),
      );
      final raw = response.data;
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (e) => MerchantSettlementSummary.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantSalesSummary> salesSummary({
    required String merchantId,
    required ReportPeriodSelection period,
    String? branchId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantReportsSales(merchantId),
        queryParameters: {
          ...period.toQuery(),
          if (branchId != null) 'branchId': branchId,
        },
      );
      return MerchantSalesSummary.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantTopProducts> topProducts({
    required String merchantId,
    required ReportPeriodSelection period,
    String? branchId,
    TopProductSort sort = TopProductSort.orders,
    int limit = 5,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantReportsTopProducts(merchantId),
        queryParameters: {
          ...period.toQuery(),
          if (branchId != null) 'branchId': branchId,
          'sort': sort.apiValue,
          'limit': limit,
        },
      );
      return MerchantTopProducts.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantDailySummary> dailySummary({
    required String merchantId,
    String? date,
    String? branchId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantReportsDailySummary(merchantId),
        queryParameters: {
          if (date != null) 'date': date,
          if (branchId != null) 'branchId': branchId,
        },
      );
      return MerchantDailySummary.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<OpeningHoursSchedule> getOpeningHours({
    required String merchantId,
    required String branchId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantOpeningHours(merchantId, branchId),
      );
      return OpeningHoursSchedule.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<OpeningHoursSchedule> putOpeningHours({
    required String merchantId,
    required String branchId,
    required int expectedVersion,
    required List<OpeningDay> days,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.merchantOpeningHours(merchantId, branchId),
        data: {
          'expectedVersion': expectedVersion,
          'days': days.map((d) => d.toJson()).toList(),
        },
      );
      return OpeningHoursSchedule.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<OpeningHoursExceptionList> listOpeningHoursExceptions({
    required String merchantId,
    required String branchId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantOpeningHoursExceptions(merchantId, branchId),
      );
      return OpeningHoursExceptionList.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
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
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.merchantOpeningHoursException(merchantId, branchId, date),
        data: {
          'expectedVersion': expectedVersion,
          'closed': closed,
          'intervals': closed
              ? const <Map<String, dynamic>>[]
              : intervals.map((i) => i.toJson()).toList(),
          'label': label,
          'customerMessage': customerMessage,
        },
      );
      return OpeningHoursException.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> deleteOpeningHoursException({
    required String merchantId,
    required String branchId,
    required String date,
    required int expectedVersion,
  }) async {
    try {
      await _dio.delete(
        ApiEndpoints.merchantOpeningHoursException(merchantId, branchId, date),
        queryParameters: {'expectedVersion': expectedVersion},
      );
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<BranchAvailabilityState> getAvailability({
    required String merchantId,
    required String branchId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantAvailability(merchantId, branchId),
      );
      return BranchAvailabilityState.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
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
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.merchantAvailability(merchantId, branchId),
        data: {
          'expectedVersion': expectedVersion,
          'mode': mode,
          if (reasonCode != null) 'reasonCode': reasonCode,
          if (customerMessage != null) 'customerMessage': customerMessage,
          if (closedUntil != null) 'closedUntil': closedUntil,
        },
      );
      return BranchAvailabilityState.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<MerchantNotificationItem>> listNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.notificationsPath,
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final raw = response.data?['items'] ?? response.data?['notifications'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (e) =>
                MerchantNotificationItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<int> notificationsUnreadCount() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.notificationsUnreadCountPath,
      );
      return (response.data?['count'] as num?)?.toInt() ??
          (response.data?['unreadCount'] as num?)?.toInt() ??
          0;
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.notificationRead(notificationId),
      );
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<int> markAllNotificationsRead() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.notificationsReadAllPath,
      );
      return (response.data?['marked'] as num?)?.toInt() ?? 0;
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.deviceTokensPath,
        data: {'token': token, 'platform': platform},
      );
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> deactivateDeviceToken({required String token}) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.deviceTokensPath,
        data: {'token': token},
      );
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<MerchantTeam> getTeam({required String merchantId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantTeam(merchantId),
      );
      return MerchantTeam.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<TeamInvitationIssued> createTeamInvitation({
    required String merchantId,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantTeamInvitations(merchantId),
        data: {'phone': phone, 'role': role},
      );
      return TeamInvitationIssued.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<TeamInvitation> cancelTeamInvitation({
    required String merchantId,
    required String invitationId,
    required int expectedVersion,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantTeamInvitationCancel(merchantId, invitationId),
        data: {'expectedVersion': expectedVersion},
      );
      return TeamInvitation.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<TeamInvitationIssued> regenerateTeamInvitationCode({
    required String merchantId,
    required String invitationId,
    required int expectedVersion,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantTeamInvitationRegenerate(merchantId, invitationId),
        data: {'expectedVersion': expectedVersion},
      );
      return TeamInvitationIssued.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<TeamMember> updateTeamMemberRole({
    required String merchantId,
    required String memberId,
    required String role,
    required int expectedVersion,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.merchantTeamMember(merchantId, memberId),
        data: {'role': role, 'expectedVersion': expectedVersion},
      );
      return TeamMember.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> revokeTeamMember({
    required String merchantId,
    required String memberId,
    required int expectedVersion,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.merchantTeamMember(merchantId, memberId),
        queryParameters: {'expectedVersion': expectedVersion},
      );
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<MyTeamInvitation>> listMyTeamInvitations() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.merchantMyTeamInvitations,
      );
      final raw = response.data?['invitations'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => MyTeamInvitation.fromJson(Map<String, dynamic>.from(e)))
          .where((i) => i.id.isNotEmpty)
          .toList();
    } catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<TeamInvitationAccepted> acceptTeamInvitation({
    required String invitationId,
    required String acceptCode,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.merchantMyTeamInvitationAccept(invitationId),
        data: {'acceptCode': acceptCode},
      );
      return TeamInvitationAccepted.fromJson(response.data ?? {});
    } catch (e) {
      throw mapDioError(e);
    }
  }
}
