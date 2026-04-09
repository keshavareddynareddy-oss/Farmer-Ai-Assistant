import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCache {
  static const String _predictionCachePrefix = 'prediction_cache_';
  static const String _selectionOptionsCacheKey = 'selection_options_cache';
  static const String _cacheTimestampSuffix = '_timestamp';
  static const Duration _defaultCacheDuration = Duration(hours: 6);

  static Future<void> cachePrediction({
    required String cropId,
    required String market,
    required int forecastDays,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _predictionCacheKey(cropId, market, forecastDays);
    await prefs.setString(key, jsonEncode(data));
    await prefs.setInt(
      '$key$_cacheTimestampSuffix',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<Map<String, dynamic>?> getPrediction({
    required String cropId,
    required String market,
    required int forecastDays,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _predictionCacheKey(cropId, market, forecastDays);

    if (!_isCacheValid(prefs, key)) {
      return null;
    }

    final cached = prefs.getString(key);
    if (cached == null) return null;

    try {
      return jsonDecode(cached) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> cacheSelectionOptions(
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectionOptionsCacheKey, jsonEncode(data));
    await prefs.setInt(
      '$_selectionOptionsCacheKey$_cacheTimestampSuffix',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<Map<String, dynamic>?> getSelectionOptions() async {
    final prefs = await SharedPreferences.getInstance();

    if (!_isCacheValid(prefs, _selectionOptionsCacheKey)) {
      return null;
    }

    final cached = prefs.getString(_selectionOptionsCacheKey);
    if (cached == null) return null;

    try {
      return jsonDecode(cached) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static bool _isCacheValid(SharedPreferences prefs, String key) {
    final timestampMs = prefs.getInt('$key$_cacheTimestampSuffix');
    if (timestampMs == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return DateTime.now().difference(cacheTime) < _defaultCacheDuration;
  }

  static String _predictionCacheKey(
      String cropId, String market, int forecastDays) {
    return '$_predictionCachePrefix${cropId}_${market}_${forecastDays}days';
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) {
      return key.startsWith(_predictionCachePrefix) ||
          key == _selectionOptionsCacheKey;
    }).toList();

    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
