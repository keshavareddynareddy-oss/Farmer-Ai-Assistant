class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class LocationResult {
  const LocationResult({
    this.location,
    this.errorMessage,
  });

  const LocationResult.success(DeviceLocation location)
      : this(location: location);

  const LocationResult.failure(String errorMessage)
      : this(errorMessage: errorMessage);

  final DeviceLocation? location;
  final String? errorMessage;
}

abstract class LocationService {
  Future<LocationResult> getCurrentLocation();
}
