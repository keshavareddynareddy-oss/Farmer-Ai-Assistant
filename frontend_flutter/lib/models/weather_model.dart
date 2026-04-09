class WeatherModel {
  final double temperature;
  final int humidity;
  final String description;
  final double windSpeed;
  final double rainfall;
  final int pressure;

  WeatherModel({
    required this.temperature,
    required this.humidity,
    required this.description,
    required this.windSpeed,
    required this.rainfall,
    required this.pressure,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: json['temperature']?.toDouble() ?? 0.0,
      humidity: json['humidity'] ?? 0,
      description: json['description'] ?? '',
      windSpeed: json['wind_speed']?.toDouble() ?? 0.0,
      rainfall: json['rainfall']?.toDouble() ?? 0.0,
      pressure: json['pressure'] ?? 0,
    );
  }
}

class WeatherForecastItem {
  final String date;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final String description;
  final double rainfall;

  WeatherForecastItem({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.description,
    required this.rainfall,
  });

  factory WeatherForecastItem.fromJson(Map<String, dynamic> json) {
    return WeatherForecastItem(
      date: json['date'] ?? '',
      tempMin: json['temp_min']?.toDouble() ?? 0.0,
      tempMax: json['temp_max']?.toDouble() ?? 0.0,
      humidity: json['humidity'] ?? 0,
      description: json['description'] ?? '',
      rainfall: json['rainfall']?.toDouble() ?? 0.0,
    );
  }
}

class WeatherForecastModel {
  final List<WeatherForecastItem> forecast;

  WeatherForecastModel({required this.forecast});

  factory WeatherForecastModel.fromJson(Map<String, dynamic> json) {
    final forecastList = json['forecast'] as List<dynamic>? ?? [];
    return WeatherForecastModel(
      forecast: forecastList
          .map((item) => WeatherForecastItem.fromJson(item))
          .toList(),
    );
  }
}
