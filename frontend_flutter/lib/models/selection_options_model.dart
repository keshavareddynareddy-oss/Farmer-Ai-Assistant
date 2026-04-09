import 'crop_model.dart';

class MarketOption {
  const MarketOption({
    required this.market,
    required this.currentPrice,
    required this.lastUpdated,
    this.latitude,
    this.longitude,
    this.district = '',
    this.state = '',
    this.distanceKm,
  });

  final String market;
  final double currentPrice;
  final String lastUpdated;
  final double? latitude;
  final double? longitude;
  final String district;
  final String state;
  final double? distanceKm;

  factory MarketOption.fromJson(Map<String, dynamic> json) {
    return MarketOption(
      market: json['market'] as String,
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0,
      lastUpdated: json['last_updated'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}

class SelectionOptionsModel {
  const SelectionOptionsModel({
    required this.crops,
    required this.marketOptions,
  });

  final List<CropModel> crops;
  final Map<String, List<MarketOption>> marketOptions;

  factory SelectionOptionsModel.fromJson(Map<String, dynamic> json) {
    final marketOptionsJson =
        json['market_options'] as Map<String, dynamic>? ?? {};

    return SelectionOptionsModel(
      crops: (json['crops'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => CropModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      marketOptions: marketOptionsJson.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map(
                  (item) => MarketOption.fromJson(item as Map<String, dynamic>))
              .toList(),
        ),
      ),
    );
  }
}
