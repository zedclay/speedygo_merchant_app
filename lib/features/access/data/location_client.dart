import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speedygo_merchant_app/core/errors/app_exception.dart';

enum LocationAccess { granted, denied, deniedForever, servicesDisabled }

class DeviceLocation {
  const DeviceLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocationUnavailableException extends UnexpectedException {
  const LocationUnavailableException()
    : super(
        'La position n’est pas disponible pour le moment.',
        code: 'LOCATION_UNAVAILABLE',
      );
}

abstract class LocationClient {
  /// Call only after an explicit user action (“Utiliser ma position”).
  Future<LocationAccess> requestAccess();

  Future<DeviceLocation> readCurrent();
}

class GeolocatorLocationClient implements LocationClient {
  @override
  Future<LocationAccess> requestAccess() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return LocationAccess.servicesDisabled;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
          return LocationAccess.denied;
        case LocationPermission.deniedForever:
          return LocationAccess.deniedForever;
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return LocationAccess.granted;
        case LocationPermission.unableToDetermine:
          return LocationAccess.denied;
      }
    } on MissingPluginException {
      throw const LocationUnavailableException();
    }
  }

  @override
  Future<DeviceLocation> readCurrent() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on MissingPluginException {
      throw const LocationUnavailableException();
    } on TimeoutException {
      throw const LocationUnavailableException();
    } on LocationServiceDisabledException {
      throw const LocationUnavailableException();
    }
  }
}

final locationClientProvider = Provider<LocationClient>((ref) {
  return GeolocatorLocationClient();
});
