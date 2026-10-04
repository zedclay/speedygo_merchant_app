import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/core/constants/app_strings.dart';
import 'package:speedygo_merchant_app/core/widgets/merchant_primary_button.dart';
import 'package:speedygo_merchant_app/features/access/data/location_client.dart';
import 'package:speedygo_merchant_app/features/access/data/map_config.dart';
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
    this.showBranchCover = true,
  });

  /// Previously confirmed coordinates, if any.
  final double? initialLatitude;
  final double? initialLongitude;
  final String? branchLabel;
  final String? addressHint;

  /// When true, shows the bound branch cover (or a storefront placeholder) on
  /// the address card. Registration before a branch exists still gets the
  /// placeholder; no geocoding / owner footer / pickup hint.
  final bool showBranchCover;

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  final _mapController = MapController();
  late LatLng _center;
  late bool _selectionReady;
  var _gpsBusy = false;
  String? _gpsMessage;
  var _mapReady = false;

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
    _mapController.dispose();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd ||
        event is MapEventMove ||
        event is MapEventFlingAnimationEnd) {
      final next = event.camera.center;
      final moved =
          (next.latitude - _center.latitude).abs() > 1e-7 ||
          (next.longitude - _center.longitude).abs() > 1e-7;
      setState(() {
        _center = next;
        if (moved || _hadConfirmedInitial) {
          _selectionReady = true;
        }
      });
    }
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _gpsBusy = true;
      _gpsMessage = null;
    });
    final client = ref.read(locationClientProvider);
    try {
      final access = await client.requestAccess();
      if (!mounted) return;
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
      if (!mounted) return;
      final target = LatLng(fix.latitude, fix.longitude);
      _mapController.move(target, MerchantMapConfig.confirmedZoom);
      setState(() {
        _center = target;
        _selectionReady = true;
        _gpsBusy = false;
        _gpsMessage = AppStrings.regLocationGpsSuggestion;
      });
    } on LocationUnavailableException {
      if (!mounted) return;
      setState(() {
        _gpsBusy = false;
        _gpsMessage = AppStrings.regLocationUnavailable;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gpsBusy = false;
        _gpsMessage = AppStrings.regLocationUnavailable;
      });
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
        lng > 180) {
      return;
    }
    Navigator.of(context)
        .pop(LocationPickResult(latitude: lat, longitude: lng));
  }

  @override
  Widget build(BuildContext context) {
    final label = (widget.branchLabel ?? '').trim();
    final address = (widget.addressHint ?? '').trim();

    return Scaffold(
      key: const Key('merchant-location-picker'),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _hadConfirmedInitial
                  ? MerchantMapConfig.confirmedZoom
                  : MerchantMapConfig.explorationZoom,
              minZoom: 5,
              maxZoom: 19,
              onMapReady: () => setState(() => _mapReady = true),
              onMapEvent: _onMapEvent,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: MerchantMapConfig.tileUrlTemplate,
                userAgentPackageName: MerchantMapConfig.userAgentPackageName,
                maxNativeZoom: 19,
                tileProvider: NetworkTileProvider(
                  cachingProvider: const DisabledMapCachingProvider(),
                ),
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(MerchantMapConfig.osmAttribution),
                ],
              ),
            ],
          ),
          // Centered pin (map moves under pin).
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
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
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
                    Container(width: 3, height: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Material(
                  color: AppColors.surface.withValues(alpha: 0.94),
                  elevation: 1,
                  child: Padding(
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
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Material(
                          color: AppColors.surface,
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: IconButton(
                            key: const Key('merchant-location-use-gps'),
                            tooltip: AppStrings.regLocationUseGps,
                            onPressed: _gpsBusy ? null : _useMyLocation,
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
                                    : () => _mapController.move(
                                        _center,
                                        (_mapController.camera.zoom + 1).clamp(
                                          5,
                                          19,
                                        ),
                                      ),
                                icon: const Icon(Icons.add),
                              ),
                              IconButton(
                                onPressed: !_mapReady
                                    ? null
                                    : () => _mapController.move(
                                        _center,
                                        (_mapController.camera.zoom - 1).clamp(
                                          5,
                                          19,
                                        ),
                                      ),
                                icon: const Icon(Icons.remove),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (label.isNotEmpty || address.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Material(
                      key: const Key('merchant-location-address-card'),
                      color: AppColors.surface,
                      elevation: 6,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            if (widget.showBranchCover) ...[
                              MerchantBranchCoverThumb(
                                key: const Key('merchant-location-cover-thumb'),
                                size: 64,
                                borderRadius: 10,
                                framed: false,
                                placeholder: const Icon(
                                  Icons.storefront,
                                  color: AppColors.primary,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (label.isNotEmpty)
                                    Text(
                                      label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  if (address.isNotEmpty)
                                    Text(
                                      address,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                    ),
                                  // Prefer the address line when present; keep
                                  // coordinates for a11y / debug only then.
                                  if (address.isEmpty)
                                    Text(
                                      '${_center.latitude.toStringAsFixed(5)}, '
                                      '${_center.longitude.toStringAsFixed(5)}',
                                      key: const Key(
                                        'merchant-location-draft-coords',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                    )
                                  else
                                    Semantics(
                                      label:
                                          '${_center.latitude.toStringAsFixed(5)}, '
                                          '${_center.longitude.toStringAsFixed(5)}',
                                      child: const SizedBox(
                                        key: Key(
                                          'merchant-location-draft-coords',
                                        ),
                                        width: 0,
                                        height: 0,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.edit_location_alt_outlined,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Material(
                  color: AppColors.surface,
                  elevation: 8,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_gpsMessage != null) ...[
                            Text(
                              _gpsMessage!,
                              key: const Key('merchant-location-gps-message'),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (!_selectionReady)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                AppStrings.regLocationMoveHint,
                                key: const Key('merchant-location-move-hint'),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          MerchantPrimaryButton(
                            key: const Key('merchant-location-confirm'),
                            label: AppStrings.regLocationConfirm,
                            icon: Icons.check_circle_outline,
                            onPressed: _selectionReady ? _confirm : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
