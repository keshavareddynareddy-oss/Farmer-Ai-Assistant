class DashboardTrendSeries {
  const DashboardTrendSeries({
    required this.cropId,
    required this.cropName,
    required this.points,
  });

  final String cropId;
  final String cropName;
  final List<double> points;

  factory DashboardTrendSeries.fromJson(Map<String, dynamic> json) {
    return DashboardTrendSeries(
      cropId: json['crop_id'] as String? ?? '',
      cropName: json['crop_name'] as String? ?? 'Unknown',
      points: (json['points'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => (item as num).toDouble())
          .toList(),
    );
  }
}

class WeatherForecastDay {
  const WeatherForecastDay({
    required this.label,
    required this.condition,
    required this.iconKey,
    required this.tempMaxC,
    required this.tempMinC,
  });

  final String label;
  final String condition;
  final String iconKey;
  final int tempMaxC;
  final int tempMinC;

  factory WeatherForecastDay.fromJson(Map<String, dynamic> json) {
    return WeatherForecastDay(
      label: json['label'] as String? ?? '',
      condition: json['condition'] as String? ?? 'Weather',
      iconKey: json['icon_key'] as String? ?? 'cloudy',
      tempMaxC: (json['temp_max_c'] as num?)?.toInt() ?? 0,
      tempMinC: (json['temp_min_c'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.cropsTracked,
    required this.marketsTracked,
    required this.bestCropName,
    required this.bestCropId,
    required this.bestCropPrice,
    required this.latestDate,
    required this.trendLabels,
    required this.trendSeries,
    required this.weatherForecast,
    required this.weatherSource,
  });

  final int cropsTracked;
  final int marketsTracked;
  final String bestCropName;
  final String bestCropId;
  final double bestCropPrice;
  final String latestDate;
  final List<String> trendLabels;
  final List<DashboardTrendSeries> trendSeries;
  final List<WeatherForecastDay> weatherForecast;
  final String weatherSource;

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final trend = json['price_trend'] as Map<String, dynamic>? ?? {};
    final weather = json['weather'] as Map<String, dynamic>? ?? {};

    return DashboardSummaryModel(
      cropsTracked: json['crops_tracked'] as int? ?? 0,
      marketsTracked: json['markets_tracked'] as int? ?? 0,
      bestCropName: json['best_crop_name'] as String? ?? 'Unknown',
      bestCropId: json['best_crop_id'] as String? ?? '',
      bestCropPrice: (json['best_crop_price'] as num?)?.toDouble() ?? 0,
      latestDate: json['latest_date'] as String? ?? '',
      trendLabels: (trend['labels'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item as String)
          .toList(),
      trendSeries: (trend['series'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) =>
              DashboardTrendSeries.fromJson(item as Map<String, dynamic>))
          .toList(),
      weatherForecast:
          (weather['forecast'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) =>
                  WeatherForecastDay.fromJson(item as Map<String, dynamic>))
              .toList(),
      weatherSource: weather['source'] as String? ?? 'fallback',
    );
  }
}
