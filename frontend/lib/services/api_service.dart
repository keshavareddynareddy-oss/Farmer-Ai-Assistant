import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/cache/local_cache.dart';
import '../core/constants/api_constants.dart';
import '../models/chat_model.dart';
import '../models/crop_model.dart';
import '../models/dashboard_summary_model.dart';
import '../models/prediction_model.dart';
import '../models/selection_options_model.dart';
import '../models/soil_recommendation_model.dart';
import '../models/weather_model.dart';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _authorizedHeaders({bool json = false}) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('backend_auth_token');
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<SelectionOptionsModel> fetchSelectionOptions({
    double? latitude,
    double? longitude,
    double? maxRadiusKm,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.selectionOptionsEndpoint}',
    ).replace(
      queryParameters: {
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        if (maxRadiusKm != null) 'max_radius_km': maxRadiusKm.toString(),
      },
    );

    try {
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch selection options');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      await LocalCache.cacheSelectionOptions(body);
      return SelectionOptionsModel.fromJson(body);
    } catch (e) {
      final cached = await LocalCache.getSelectionOptions();
      if (cached != null) {
        return SelectionOptionsModel.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<DashboardSummaryModel> fetchDashboardSummary({
    double? latitude,
    double? longitude,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.dashboardSummaryEndpoint}',
    ).replace(
      queryParameters: {
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      },
    );
    final response = await _client.get(
      uri,
      headers: await _authorizedHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch dashboard summary');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return DashboardSummaryModel.fromJson(body);
  }

  Future<Map<String, dynamic>> fetchDailyGuidance({
    double? latitude,
    double? longitude,
    String? stage,
    String? cropName,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/api/daily-guidance',
    ).replace(
      queryParameters: {
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        if (stage != null && stage.trim().isNotEmpty) 'stage': stage.trim(),
        if (cropName != null && cropName.trim().isNotEmpty)
          'crop_name': cropName.trim(),
      },
    );
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch daily guidance');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchCropWatchOverview({
    required String username,
    double? latitude,
    double? longitude,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.cropWatchOverviewEndpoint}',
    ).replace(
      queryParameters: {
        'username': username,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      },
    );
    final response = await _client.get(
      uri,
      headers: await _authorizedHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch crop watch overview');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<CropModel>> fetchCrops() async {
    final uri =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cropsEndpoint}');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch crops');
    }

    final body = jsonDecode(response.body) as List<dynamic>;
    return body
        .map((item) => CropModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PredictionModel> fetchPrediction({
    required String cropId,
    required String market,
    required int forecastDays,
  }) async {
    final uri =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.predictEndpoint}');
    final payload = {
      'crop_id': cropId,
      'market': market,
      'forecast_days': forecastDays,
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch prediction');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      await LocalCache.cachePrediction(
        cropId: cropId,
        market: market,
        forecastDays: forecastDays,
        data: body,
      );
      return PredictionModel.fromJson(body);
    } catch (e) {
      final cached = await LocalCache.getPrediction(
        cropId: cropId,
        market: market,
        forecastDays: forecastDays,
      );
      if (cached != null) {
        return PredictionModel.fromJson(cached);
      }
      rethrow;
    }
  }

  Future<String> fetchBestSellRecommendation({
    required String cropId,
    required String market,
    required int forecastDays,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.recommendEndpoint}',
    );

    final response = await _client.post(
      uri,
      headers: await _authorizedHeaders(json: true),
      body: jsonEncode({
        'crop_id': cropId,
        'market': market,
        'forecast_days': forecastDays,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch recommendation');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['recommendation'] as String? ?? '';
  }

  Future<NearbyMarketPredictionModel> fetchNearbyMarketPredictions({
    required String cropId,
    required double latitude,
    required double longitude,
    required int forecastDays,
    double? maxRadiusKm,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.predictNearbyEndpoint}',
    );
    final payload = {
      'crop_id': cropId,
      'latitude': latitude,
      'longitude': longitude,
      'forecast_days': forecastDays,
      if (maxRadiusKm != null) 'max_radius_km': maxRadiusKm,
    };

    final response = await _client.post(
      uri,
      headers: await _authorizedHeaders(json: true),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch nearby market predictions');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return NearbyMarketPredictionModel.fromJson(body);
  }

  Future<SoilRecommendationModel> fetchSoilRecommendations({
    required double ph,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double moisture,
    required double organicMatter,
    String? cropName,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.soilRecommendationsEndpoint}',
    );
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ph': ph,
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'moisture': moisture,
        'organic_matter': organicMatter,
        if (cropName != null && cropName.trim().isNotEmpty)
          'crop_name': cropName.trim(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch soil recommendations');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return SoilRecommendationModel.fromJson(body);
  }

  Future<ChatResponseModel> sendChatMessage({
    required String message,
    required String sessionId,
    required String language,
    Map<String, dynamic>? context,
  }) async {
    final uri =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatEndpoint}');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'session_id': sessionId,
        'language': language,
        if (context != null) 'context': context,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send chat message');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatResponseModel.fromJson(body);
  }

  Future<WeatherModel> fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.weatherCurrentEndpoint}',
    ).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch weather');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return WeatherModel.fromJson(body);
  }

  Future<WeatherForecastModel> fetchWeatherForecast({
    required double latitude,
    required double longitude,
    int days = 7,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.weatherForecastEndpoint}',
    ).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'days': days.toString(),
      },
    );
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch weather forecast');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return WeatherForecastModel.fromJson(body);
  }

  Future<Map<String, dynamic>> saveCropWatch({
    required String username,
    String id = '',
    required String cropName,
    String cropId = '',
    required String sowingDate,
    String expectedHarvestDate = '',
    String market = '',
    String status = 'growing',
    String notes = '',
  }) async {
    final uri =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cropWatchEndpoint}');
    final response = await _client.post(
      uri,
      headers: await _authorizedHeaders(json: true),
      body: jsonEncode({
        'id': id,
        'username': username,
        'crop_id': cropId,
        'crop_name': cropName,
        'sowing_date': sowingDate,
        'expected_harvest_date': expectedHarvestDate,
        'market': market,
        'status': status,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      final body = response.body.isNotEmpty
          ? response.body
          : 'Failed to save crop watch';
      throw Exception(body);
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteCropWatch({
    required String username,
    required String watchId,
  }) async {
    final uri = Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.cropWatchEndpoint}/$watchId')
        .replace(queryParameters: {'username': username});
    final response = await _client.delete(
      uri,
      headers: await _authorizedHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove crop watch');
    }
  }

  Future<String> signIn({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/auth/sign-in');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sign in');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['token'] as String?;
    if (token != null && token.isNotEmpty) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('backend_auth_token', token);
    }
    return body['username'] as String? ?? username.trim();
  }

  Future<String> register({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/auth/register');
    final response = await _client.post(
      uri,
      headers: await _authorizedHeaders(json: true),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      final body =
          response.body.isNotEmpty ? response.body : 'Failed to register';
      throw Exception(body);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['token'] as String?;
    if (token != null && token.isNotEmpty) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('backend_auth_token', token);
    }
    return body['username'] as String? ?? username.trim();
  }

  Future<String> createFirebaseSession({required String idToken}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/auth/firebase-session');
    final response = await _client.post(
      uri,
      headers: await _authorizedHeaders(json: true),
      body: jsonEncode({'id_token': idToken}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to establish backend session');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Backend did not return an authentication token');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('backend_auth_token', token);
    return body['username'] as String? ?? '';
  }

  Future<void> signOut({required String username}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/auth/sign-out');
    final response = await _client.post(
      uri,
      headers: await _authorizedHeaders(json: true),
      body: jsonEncode({'username': username}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sign out');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('backend_auth_token');
  }

  Future<bool> hasSession({required String username}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/auth/session').replace(
      queryParameters: {'username': username},
    );
    final response =
        await _client.get(uri, headers: await _authorizedHeaders());

    if (response.statusCode != 200) {
      return false;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['exists'] as bool? ?? false;
  }

  Future<List<Map<String, dynamic>>> fetchAlerts({
    required String username,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/alerts').replace(
      queryParameters: {'username': username},
    );
    final response =
        await _client.get(uri, headers: await _authorizedHeaders());

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch alerts');
    }

    final body = jsonDecode(response.body) as List<dynamic>;
    return body
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> saveAlert({
    required String username,
    required Map<String, dynamic> alert,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/alerts');
    final response = await _client.post(
      uri,
      headers: await _authorizedHeaders(json: true),
      body: jsonEncode({
        ...alert,
        'username': username,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save alert');
    }
  }

  Future<void> deleteAlert({
    required String username,
    required String alertId,
  }) async {
    final uri =
        Uri.parse('${ApiConstants.baseUrl}/api/alerts/$alertId').replace(
      queryParameters: {'username': username},
    );
    final response =
        await _client.delete(uri, headers: await _authorizedHeaders());

    if (response.statusCode != 200) {
      throw Exception('Failed to remove alert');
    }
  }
}
