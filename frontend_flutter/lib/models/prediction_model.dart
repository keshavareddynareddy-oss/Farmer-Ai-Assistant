class PredictionPoint {
  const PredictionPoint({
    required this.day,
    required this.price,
  });

  final int day;
  final double price;

  factory PredictionPoint.fromJson(Map<String, dynamic> json) {
    return PredictionPoint(
      day: json['day'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }
}

class PredictionModel {
  const PredictionModel({
    required this.cropName,
    required this.market,
    required this.currentPrice,
    required this.forecast,
    required this.recommendation,
    this.modelVersion,
  });

  final String cropName;
  final String market;
  final double currentPrice;
  final List<PredictionPoint> forecast;
  final String recommendation;
  final String? modelVersion;

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      cropName: json['crop_name'] as String,
      market: json['market'] as String? ?? '',
      currentPrice: (json['current_price'] as num).toDouble(),
      forecast: (json['forecast'] as List<dynamic>)
          .map((item) => PredictionPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      recommendation: json['recommendation'] as String,
      modelVersion: json['model_version'] as String?,
    );
  }
}

class NearbyMarketPredictionPoint {
  const NearbyMarketPredictionPoint({
    required this.day,
    required this.price,
  });

  final int day;
  final double price;

  factory NearbyMarketPredictionPoint.fromJson(Map<String, dynamic> json) {
    return NearbyMarketPredictionPoint(
      day: json['day'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }
}

class NearbyMarketPredictionItem {
  const NearbyMarketPredictionItem({
    required this.market,
    required this.currentPrice,
    this.lastUpdated,
    this.distanceKm,
    required this.forecast,
    required this.recommendation,
  });

  final String market;
  final double currentPrice;
  final String? lastUpdated;
  final double? distanceKm;
  final List<NearbyMarketPredictionPoint> forecast;
  final String recommendation;

  factory NearbyMarketPredictionItem.fromJson(Map<String, dynamic> json) {
    return NearbyMarketPredictionItem(
      market: json['market'] as String,
      currentPrice: (json['current_price'] as num).toDouble(),
      lastUpdated: json['last_updated'] as String?,
      distanceKm: json['distance_km'] == null
          ? null
          : (json['distance_km'] as num).toDouble(),
      forecast: (json['forecast'] as List<dynamic>)
          .map((item) => NearbyMarketPredictionPoint.fromJson(
              item as Map<String, dynamic>))
          .toList(),
      recommendation: json['recommendation'] as String,
    );
  }
}

class NearbyMarketPredictionModel {
  const NearbyMarketPredictionModel({
    required this.cropName,
    required this.cropId,
    required this.nearestMarkets,
  });

  final String cropName;
  final String cropId;
  final List<NearbyMarketPredictionItem> nearestMarkets;

  factory NearbyMarketPredictionModel.fromJson(Map<String, dynamic> json) {
    return NearbyMarketPredictionModel(
      cropName: json['crop_name'] as String,
      cropId: json['crop_id'] as String,
      nearestMarkets: (json['nearest_markets'] as List<dynamic>)
          .map((item) =>
              NearbyMarketPredictionItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
