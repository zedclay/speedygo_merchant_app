import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/features/access/data/geo_admin_consistency.dart';
import 'package:speedygo_merchant_app/features/access/data/geo_api.dart';
import 'package:speedygo_merchant_app/features/access/data/location_client.dart';
import 'package:speedygo_merchant_app/features/access/data/map_config.dart';
import 'package:speedygo_merchant_app/features/access/data/place_session_token.dart';
import 'package:speedygo_merchant_app/features/access/presentation/location_map_surface.dart';
import 'package:speedygo_merchant_app/features/store/presentation/merchant_branch_cover_thumb.dart';

class LocationPickResult {
  const LocationPickResult({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Full-screen map picker. Confirm returns [LocationPickResult]; back/cancel
/// pops `null` and must not mutate the registration draft.
class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.branchLabel,
    this.addressHint,
    this.wilayaCode,
    this.wilayaLabel,
    this.showBranchCover = true,
  });

  /// Previously confirmed coordinates, if any.
  final double? initialLatitude;
  final double? initialLongitude;
  final String? branchLabel;
  final String? addressHint;
  final String? wilayaCode;
  final String? wilayaLabel;

  /// When true, shows the bound branch cover (or a storefront placeholder) on
  /// the address card. Registration before a branch exists still gets the
  /// placeholder; no geocoding / owner footer / pickup hint.
  final bool showBranchCover;

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  LocationMapController? _map;
  final _search = TextEditingController();
  late LatLng _center;
  late bool _selectionReady;
  var _gpsBusy = false;
  var _searchBusy = false;
  String? _gpsMessage;
  String? _searchMessage;
  List<PlaceSuggestion> _suggestions = const [];
  Timer? _debounce;
  var _generation = 0;
  var _mapReady = false;
  var _placeSessionToken = PlaceSessionToken.create();
  String _lastQuery = '';

  bool get _hadConfirmedInitial {
    final lat = widget.initialLatitude;
    final lng = widget.initialLongitude;
    return lat != null &&
        lng != null &&
        lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  @override
  void initState() {
    super.initState();
    if (_hadConfirmedInitial) {
      _center = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _selectionReady = true;
    } else {
      _center = const LatLng(
        MerchantMapConfig.explorationLatitude,
        MerchantMapConfig.explorationLongitude,
      );
      // Exploration default must not be confirmable until user acts.
      _selectionReady = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _unfocusSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _recenterToWilaya() {
    if (!_mapReady) return;
    final target = GeoAdminConsistency.cameraForWilaya(widget.wilayaCode);
    unawaited(
      _map?.moveTo(
        target.latitude,
        target.longitude,
        MerchantMapConfig.explorationZoom,
      ),
    );
    setState(() {
      _center = target;
      _selectionReady = true;
      _generation += 1;
      _suggestions = const [];
      _placeSessionToken = PlaceSessionToken.create();
    });
  }

  void _onCameraIdle(double latitude, double longitude) {
    final next = LatLng(latitude, longitude);
    final moved =
        (next.latitude - _center.latitude).abs() > 1e-7 ||
        (next.longitude - _center.longitude).abs() > 1e-7;
    setState(() {
      _center = next;
      if (moved || _hadConfirmedInitial) {
        _selectionReady = true;
        _generation += 1;
        _suggestions = const [];
        _placeSessionToken = PlaceSessionToken.create();
      }
    });
  }

  Future<void> _useMyLocation() async {
    final generation = ++_generation;
    setState(() {
      _gpsBusy = true;
      _gpsMessage = null;
    });
    final client = ref.read(locationClientProvider);
    try {
      final access = await client.requestAccess();
      if (!mounted || generation != _generation) return;
      switch (access) {
        case LocationAccess.denied:
          setState(() {
            _gpsBusy = false;
            _gpsMessage = AppStrings.regLocationDenied;
          });
          return;
        case LocationAccess.deniedForever:
          setState(() {
            _gpsBusy = false;
            _gpsMessage = AppStrings.regLocationDeniedForever;
          });
          return;
        case LocationAccess.servicesDisabled:
          setState(() {
            _gpsBusy = false;
            _gpsMessage = AppStrings.regLocationServicesDisabled;
          });
          return;
        case LocationAccess.granted:
          break;
      }
      final fix = await client.readCurrent();
      if (!mounted || generation != _generation) return;
      final target = LatLng(fix.latitude, fix.longitude);
      await _map?.moveTo(
        target.latitude,
        target.longitude,
        MerchantMapConfig.confirmedZoom,
      );
      setState(() {
        _center = target;
        _selectionReady = true;
        _gpsBusy = false;
        _gpsMessage = AppStrings.regLocationGpsSuggestion;
      });
    } on LocationUnavailableException {
      if (!mounted || generation != _generation) return;
      setState(() {
        _gpsBusy = false;
        _gpsMessage = AppStrings.regLocationUnavailable;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _gpsBusy = false;
        _gpsMessage = AppStrings.regLocationUnavailable;
      });
    }
  }

  void _onSearchChanged(String raw) {
    if (!ref.read(mapRuntimeConfigProvider).placesLookupEnabled) {
      return;
    }
    _debounce?.cancel();
    final q = raw.trim();
    if (q.length < 2) {
      setState(() {
        _suggestions = const [];
        _searchMessage = null;
        _lastQuery = '';
      });
      return;
    }
    final generation = _generation;
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_runSearch(q, generation));
    });
  }

  bool get _searchCanRetry =>
      _lastQuery.length >= 2 &&
      (_searchMessage == AppStrings.locationSearchFailed ||
          _searchMessage == AppStrings.locationSearchUnavailable);

  Future<void> _runSearch(String q, int generation) async {
    if (!ref.read(mapRuntimeConfigProvider).placesLookupEnabled) {
      return;
    }
    setState(() {
      _searchBusy = true;
      _lastQuery = q;
      _searchMessage = AppStrings.locationSearchLoading;
    });
    try {
      final hits = await ref.read(merchantGeoClientProvider).autocomplete(
            q: q,
            language: AppStrings.isArabic ? 'ar' : 'fr',
            sessionToken: _placeSessionToken,
          );
      if (!mounted || generation != _generation) return;
      setState(() {
        _searchBusy = false;
        _suggestions = hits;
        _searchMessage = hits.isEmpty ? AppStrings.locationSearchEmpty : null;
      });
    } on GeocodingNotConfiguredException {
      if (!mounted || generation != _generation) return;
      setState(() {
        _searchBusy = false;
        _suggestions = const [];
        _searchMessage = AppStrings.locationSearchUnavailable;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _searchBusy = false;
        _suggestions = const [];
        _searchMessage = AppStrings.locationSearchFailed;
      });
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion hit) async {
    if (!ref.read(mapRuntimeConfigProvider).placesLookupEnabled) {
      return;
    }
    final generation = ++_generation;
    _search.text = hit.text;
    setState(() {
      _suggestions = const [];
      _searchBusy = true;
      _searchMessage = AppStrings.locationSearchLoading;
    });
    try {
      final details = await ref.read(merchantGeoClientProvider).placeDetails(
            placeId: hit.placeId,
            language: AppStrings.isArabic ? 'ar' : 'fr',
            sessionToken: _placeSessionToken,
          );
      if (!mounted || generation != _generation) return;
      final target = LatLng(details.latitude, details.longitude);
      await _map?.moveTo(
        target.latitude,
        target.longitude,
        MerchantMapConfig.confirmedZoom,
      );
      setState(() {
        _center = target;
        _selectionReady = true;
        _searchBusy = false;
        _searchMessage = null;
      });
      if (details.formattedAddress != null &&
          details.formattedAddress!.isNotEmpty) {
        _search.text = details.formattedAddress!;
      }
    } on GeocodingNotConfiguredException {
      if (!mounted || generation != _generation) return;
      setState(() {
        _searchBusy = false;
        _searchMessage = AppStrings.locationSearchUnavailable;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _searchBusy = false;
        _searchMessage = AppStrings.locationSearchFailed;
      });
    } finally {
      _placeSessionToken = PlaceSessionToken.create();
    }
  }

  void _confirm() {
    if (!_selectionReady) return;
    final lat = _center.latitude;
    final lng = _center.longitude;
    if (!lat.isFinite ||
        !lng.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180 ||
        (lat == 0 && lng == 0)) {
      return;
    }
    Navigator.of(context)
        .pop(LocationPickResult(latitude: lat, longitude: lng));
  }

  @override
  Widget build(BuildContext context) {
    final label = (widget.branchLabel ?? '').trim();
    final address = (widget.addressHint ?? '').trim();
    final wilayaLabel = (widget.wilayaLabel ?? '').trim();
    final mismatch = !GeoAdminConsistency.pinMatchesWilaya(
      wilayaCode: widget.wilayaCode,
      latitude: _center.latitude,
      longitude: _center.longitude,
    );
    final runtime = ref.watch(mapRuntimeConfigProvider);
    final lookups = runtime.placesLookupEnabled;
    final mode = runtime.mode;
    final searchMessage = !lookups
        ? (mode == MapRenderMode.osmDev
              ? AppStrings.locationSearchDisabledOnDevMap
              : AppStrings.locationMapUnavailable)
        : _searchMessage;

    return Scaffold(
      key: const Key('merchant-location-picker'),
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: AppColors.surface.withValues(alpha: 0.94),
              elevation: 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        IconButton(
                          key: const Key('merchant-location-back'),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            AppStrings.regLocationPickerTitle,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      key: const Key('merchant-location-search'),
                      controller: _search,
                      enabled: lookups,
                      onChanged: _onSearchChanged,
                      onTapOutside: (_) => _unfocusSearch(),
                      decoration: InputDecoration(
                        hintText: AppStrings.locationSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchBusy
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  if (searchMessage != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            searchMessage,
                            key: const Key('merchant-location-search-message'),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          if (_searchCanRetry)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                key: const Key('merchant-location-search-retry'),
                                onPressed: _searchBusy
                                    ? null
                                    : () => unawaited(
                                        _runSearch(_lastQuery, _generation),
                                      ),
                                child: Text(AppStrings.retry),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (lookups && _suggestions.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final hit = _suggestions[index];
                          return ListTile(
                            key: Key('merchant-location-suggestion-$index'),
                            dense: true,
                            title: Text(hit.text),
                            onTap: () => unawaited(_selectSuggestion(hit)),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sheetMax = (constraints.maxHeight * 0.38).clamp(
                    88.0,
                    240.0,
                  );
                  return Column(
                    children: [
                      Expanded(
                        child: mode == MapRenderMode.unavailable
                            ? const ColoredBox(
                                key: Key('merchant-location-map-unavailable'),
                                color: Color(0xFFE8EEF4),
                                child: SizedBox.expand(),
                              )
                            : Stack(
                          children: [
                            LocationMapSurface(
                              key: const Key('merchant-location-map'),
                              mode: mode,
                              useStub: ref.watch(locationMapStubProvider),
                              initialLatitude: _center.latitude,
                              initialLongitude: _center.longitude,
                              initialZoom: _hadConfirmedInitial
                                  ? MerchantMapConfig.confirmedZoom
                                  : MerchantMapConfig.explorationZoom,
                              onReady: () =>
                                  setState(() => _mapReady = true),
                              onCameraIdle: _onCameraIdle,
                              onInteraction: _unfocusSearch,
                              onCreated: (controller) => _map = controller,
                            ),
                            IgnorePointer(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 36),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              const BorderRadius.only(
                                                topLeft: Radius.circular(20),
                                                topRight: Radius.circular(20),
                                                bottomRight: Radius.circular(
                                                  20,
                                                ),
                                              ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.storefront,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      Container(
                                        width: 3,
                                        height: 14,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Column(
                                children: [
                                  Material(
                                    color: AppColors.surface,
                                    elevation: 4,
                                    borderRadius: BorderRadius.circular(12),
                                    child: IconButton(
                                      key: const Key(
                                        'merchant-location-use-gps',
                                      ),
                                      tooltip: AppStrings.regLocationUseGps,
                                      onPressed: _gpsBusy
                                          ? null
                                          : _useMyLocation,
                                      icon: _gpsBusy
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.my_location,
                                              color: AppColors.primary,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Material(
                                    color: AppColors.surface,
                                    elevation: 4,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Column(
                                      children: [
                                        IconButton(
                                          onPressed: !_mapReady
                                              ? null
                                              : () => unawaited(
                                                    _map?.zoomBy(1),
                                                  ),
                                          icon: const Icon(Icons.add),
                                        ),
                                        IconButton(
                                          onPressed: !_mapReady
                                              ? null
                                              : () => unawaited(
                                                    _map?.zoomBy(-1),
                                                  ),
                                          icon: const Icon(Icons.remove),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: sheetMax),
                        child: Material(
                          color: AppColors.surface,
                          elevation: 6,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (mismatch && wilayaLabel.isNotEmpty) ...[
                                  Text(
                                    AppStrings.locationWilayaPinMismatch(
                                      wilayaLabel,
                                    ),
                                    key: const Key(
                                      'merchant-location-mismatch',
                                    ),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.error),
                                  ),
                                  TextButton(
                                    key: const Key(
                                      'merchant-location-recenter-wilaya',
                                    ),
                                    onPressed: _recenterToWilaya,
                                    child: Text(
                                      AppStrings.locationRecenterWilaya(
                                        wilayaLabel,
                                      ),
                                    ),
                                  ),
                                ],
                                if (label.isNotEmpty || address.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      key: const Key(
                                        'merchant-location-address-card',
                                      ),
                                      children: [
                                        if (widget.showBranchCover) ...[
                                          const MerchantBranchCoverThumb(
                                            key: Key(
                                              'merchant-location-cover-thumb',
                                            ),
                                            size: 48,
                                            borderRadius: 10,
                                            framed: false,
                                            placeholder: Icon(
                                              Icons.storefront,
                                              color: AppColors.primary,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (label.isNotEmpty)
                                                Text(
                                                  label,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              if (address.isNotEmpty)
                                                Text(
                                                  address,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: AppColors
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                              Text(
                                                _selectionReady
                                                    ? AppStrings
                                                          .locationPointConfirmed
                                                    : AppStrings
                                                          .regLocationMoveHint,
                                                key: const Key(
                                                  'merchant-location-draft-coords',
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: AppColors
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_gpsMessage != null)
                                  Text(
                                    _gpsMessage!,
                                    key: const Key(
                                      'merchant-location-gps-message',
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                  ),
                                if (!_selectionReady)
                                  Text(
                                    AppStrings.regLocationMoveHint,
                                    key: const Key(
                                      'merchant-location-move-hint',
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                  ),
                                if (mode == MapRenderMode.unavailable)
                                  Text(
                                    AppStrings.locationMapUnavailable,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                  ),
                                if (mode == MapRenderMode.google)
                                  const Text(
                                    'Google Maps',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      color: Color(0xFF5E5E5E),
                                    ),
                                  ),
                                if (mode == MapRenderMode.osmDev)
                                  Text(
                                    AppStrings.locationMapTilesDev,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: AppColors.surface,
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: MerchantPrimaryButton(
                            key: const Key('merchant-location-confirm'),
                            label: AppStrings.regLocationConfirm,
                            icon: Icons.check_circle_outline,
                            onPressed:
                                mode != MapRenderMode.unavailable &&
                                    _selectionReady &&
                                    _mapReady
                                ? _confirm
                                : null,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
