import 'package:geolocator/geolocator.dart';

import 'location_service_base.dart';

LocationService createLocationService() => NativeLocationService();

class NativeLocationService implements LocationService {
  @override
  Future<LocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult.failure(
          'Location services are turned off on this device.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(
          'Location permission was denied.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(
          'Location permission is permanently denied.',
        );
      }

      final position = await Geolocator.getCurrentPosition();
      return LocationResult.success(
        DeviceLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (error) {
      return LocationResult.failure(error.toString());
    }
  }
}
