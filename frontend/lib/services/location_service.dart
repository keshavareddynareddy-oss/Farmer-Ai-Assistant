import 'location_service_base.dart';
import 'location_service_native.dart'
    if (dart.library.html) 'location_service_web.dart' as implementation;

export 'location_service_base.dart';

LocationService createLocationService() =>
    implementation.createLocationService();
