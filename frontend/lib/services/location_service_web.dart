import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'location_service_base.dart';

LocationService createLocationService() => WebLocationService();

class WebLocationService implements LocationService {
  @override
  Future<LocationResult> getCurrentLocation() async {
    if (!_isSecureContext()) {
      return const LocationResult.failure(
        'Browser location requires HTTPS or localhost.',
      );
    }

    final geolocation = web.window.navigator.geolocation;
    final completer = Completer<LocationResult>();

    try {
      geolocation.getCurrentPosition(
        (web.GeolocationPosition position) {
          completer.complete(
            LocationResult.success(
              DeviceLocation(
                latitude: position.coords.latitude,
                longitude: position.coords.longitude,
              ),
            ),
          );
        }.toJS,
        (web.GeolocationPositionError error) {
          completer.complete(
            LocationResult.failure(_messageForBrowserError(error)),
          );
        }.toJS,
        web.PositionOptions(
          enableHighAccuracy: true,
          timeout: const Duration(seconds: 12).inMilliseconds,
          maximumAge: 0,
        ),
      );
    } catch (_) {
      return const LocationResult.failure(
        'This browser does not allow geolocation for this page.',
      );
    }

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => const LocationResult.failure(
        'Location request timed out. Please try again.',
      ),
    );
  }

  bool _isSecureContext() {
    final protocol = web.window.location.protocol;
    final host = web.window.location.hostname;
    return web.window.isSecureContext ||
        protocol == 'https:' ||
        host == 'localhost' ||
        host == '127.0.0.1';
  }

  String _messageForBrowserError(web.GeolocationPositionError error) {
    switch (error.code) {
      case 1:
        return 'Location permission was denied by the browser.';
      case 2:
        return 'Unable to determine the current device location.';
      case 3:
        return 'Location request timed out. Please try again.';
      default:
        return error.message.isEmpty
            ? 'Location is unavailable in this browser.'
            : error.message;
    }
  }
}
