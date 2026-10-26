import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:speedygo_merchant_app/app/theme/app_theme.dart';
import 'package:speedygo_merchant_app/features/access/data/map_config.dart';

abstract class LocationMapController {
  Future<void> moveTo(double latitude, double longitude, double zoom);
  Future<void> zoomBy(double delta);
}

class LocationMapSurface extends StatefulWidget {
  const LocationMapSurface({
    super.key,
    required this.mode,
    required this.useStub,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.initialZoom,
    required this.onReady,
    required this.onCameraIdle,
    required this.onInteraction,
    required this.onCreated,
  });

  final MapRenderMode mode;
  final bool useStub;
  final double initialLatitude;
  final double initialLongitude;
  final double initialZoom;
  final VoidCallback onReady;
  final void Function(double latitude, double longitude) onCameraIdle;
  final VoidCallback onInteraction;
  final void Function(LocationMapController controller) onCreated;

  @override
  State<LocationMapSurface> createState() => _LocationMapSurfaceState();
}

class _LocationMapSurfaceState extends State<LocationMapSurface> {
  @override
  Widget build(BuildContext context) {
    if (widget.useStub) {
      return _StubMap(
        onReady: widget.onReady,
        onCreated: widget.onCreated,
        onCameraIdle: widget.onCameraIdle,
      );
    }
    switch (widget.mode) {
      case MapRenderMode.google:
        return _GoogleMapSurface(
          initialLatitude: widget.initialLatitude,
          initialLongitude: widget.initialLongitude,
          initialZoom: widget.initialZoom,
          onReady: widget.onReady,
          onCameraIdle: widget.onCameraIdle,
          onInteraction: widget.onInteraction,
          onCreated: widget.onCreated,
        );
      case MapRenderMode.osmDev:
        return _OsmMapSurface(
          initialLatitude: widget.initialLatitude,
          initialLongitude: widget.initialLongitude,
          initialZoom: widget.initialZoom,
          onReady: widget.onReady,
          onCameraIdle: widget.onCameraIdle,
          onInteraction: widget.onInteraction,
          onCreated: widget.onCreated,
        );
      case MapRenderMode.unavailable:
        return const SizedBox.expand();
    }
  }
}

class LocationFixedPin extends StatelessWidget {
  const LocationFixedPin({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
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
                ),
                child: const Icon(Icons.place, color: Colors.white, size: 22),
              ),
              Container(width: 3, height: 14, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _StubController implements LocationMapController {
  _StubController(this._onIdle);

  final void Function(double latitude, double longitude) _onIdle;

  @override
  Future<void> moveTo(double latitude, double longitude, double zoom) async {
    _onIdle(latitude, longitude);
  }

  @override
  Future<void> zoomBy(double delta) async {}
}

class _StubMap extends StatefulWidget {
  const _StubMap({
    required this.onReady,
    required this.onCreated,
    required this.onCameraIdle,
  });

  final VoidCallback onReady;
  final void Function(LocationMapController controller) onCreated;
  final void Function(double latitude, double longitude) onCameraIdle;

  @override
  State<_StubMap> createState() => _StubMapState();
}

class _StubMapState extends State<_StubMap> {
  @override
  void initState() {
    super.initState();
    final controller = _StubController(widget.onCameraIdle);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.onCreated(controller);
      widget.onReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE8EEF4),
      child: SizedBox.expand(),
    );
  }
}

class _GoogleController implements LocationMapController {
  gmaps.GoogleMapController? inner;

  @override
  Future<void> moveTo(double latitude, double longitude, double zoom) async {
    final map = inner;
    if (map == null) {
      return;
    }
    await map.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: gmaps.LatLng(latitude, longitude),
          zoom: zoom,
        ),
      ),
    );
  }

  @override
  Future<void> zoomBy(double delta) async {
    final map = inner;
    if (map == null) {
      return;
    }
    await map.animateCamera(gmaps.CameraUpdate.zoomBy(delta));
  }
}

class _GoogleMapSurface extends StatefulWidget {
  const _GoogleMapSurface({
    required this.initialLatitude,
    required this.initialLongitude,
    required this.initialZoom,
    required this.onReady,
    required this.onCameraIdle,
    required this.onInteraction,
    required this.onCreated,
  });

  final double initialLatitude;
  final double initialLongitude;
  final double initialZoom;
  final VoidCallback onReady;
  final void Function(double latitude, double longitude) onCameraIdle;
  final VoidCallback onInteraction;
  final void Function(LocationMapController controller) onCreated;

  @override
  State<_GoogleMapSurface> createState() => _GoogleMapSurfaceState();
}

class _GoogleMapSurfaceState extends State<_GoogleMapSurface> {
  final _controller = _GoogleController();
  late gmaps.LatLng _last;

  @override
  void initState() {
    super.initState();
    _last = gmaps.LatLng(widget.initialLatitude, widget.initialLongitude);
  }

  @override
  Widget build(BuildContext context) {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: _last,
        zoom: widget.initialZoom,
      ),
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      indoorViewEnabled: false,
      rotateGesturesEnabled: false,
      liteModeEnabled: false,
      onMapCreated: (controller) {
        _controller.inner = controller;
        widget.onCreated(_controller);
        widget.onReady();
      },
      onCameraMove: (position) {
        _last = position.target;
        widget.onInteraction();
      },
      onCameraIdle: () {
        widget.onCameraIdle(_last.latitude, _last.longitude);
      },
      onTap: (_) => widget.onInteraction(),
    );
  }
}

class _OsmController implements LocationMapController {
  _OsmController(this._map);

  final MapController _map;

  @override
  Future<void> moveTo(double latitude, double longitude, double zoom) async {
    _map.move(LatLng(latitude, longitude), zoom);
  }

  @override
  Future<void> zoomBy(double delta) async {
    _map.move(_map.camera.center, (_map.camera.zoom + delta).clamp(5, 19));
  }
}

class _OsmMapSurface extends StatefulWidget {
  const _OsmMapSurface({
    required this.initialLatitude,
    required this.initialLongitude,
    required this.initialZoom,
    required this.onReady,
    required this.onCameraIdle,
    required this.onInteraction,
    required this.onCreated,
  });

  final double initialLatitude;
  final double initialLongitude;
  final double initialZoom;
  final VoidCallback onReady;
  final void Function(double latitude, double longitude) onCameraIdle;
  final VoidCallback onInteraction;
  final void Function(LocationMapController controller) onCreated;

  @override
  State<_OsmMapSurface> createState() => _OsmMapSurfaceState();
}

class _OsmMapSurfaceState extends State<_OsmMapSurface> {
  final _map = MapController();
  var _readySent = false;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: LatLng(widget.initialLatitude, widget.initialLongitude),
        initialZoom: widget.initialZoom,
        minZoom: 5,
        maxZoom: 19,
        onMapReady: () {
          if (_readySent) {
            return;
          }
          _readySent = true;
          widget.onCreated(_OsmController(_map));
          widget.onReady();
        },
        onMapEvent: (event) {
          if (event is MapEventMove) {
            widget.onInteraction();
          }
          if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
            final next = event.camera.center;
            widget.onCameraIdle(next.latitude, next.longitude);
          }
        },
        onTap: (tapPosition, point) => widget.onInteraction(),
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
    );
  }
}
