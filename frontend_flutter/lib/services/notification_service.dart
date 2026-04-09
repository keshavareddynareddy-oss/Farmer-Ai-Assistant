import '../models/selection_options_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class NotificationService {
  final ApiService _apiService;
  final AuthService _authService;

  NotificationService({ApiService? apiService, AuthService? authService})
      : _apiService = apiService ?? ApiService(),
        _authService = authService ?? AuthService();

  Future<String?> _currentUsername() async {
    final value = await _authService.loadSignedInUser();
    final username = value?.trim();
    if (username == null || username.isEmpty) {
      return null;
    }
    return username;
  }

  Future<List<PriceAlert>> getAlerts() async {
    final username = await _currentUsername();
    if (username == null) {
      return const <PriceAlert>[];
    }

    final rows = await _apiService.fetchAlerts(username: username);

    final alerts = <PriceAlert>[];
    for (final row in rows) {
      try {
        alerts.add(PriceAlert.fromJson(row));
      } catch (_) {
        continue;
      }
    }

    return alerts;
  }

  Future<void> saveAlert(PriceAlert alert) async {
    final username = await _currentUsername();
    if (username == null) {
      throw Exception('You must be signed in to save alerts.');
    }

    await _apiService.saveAlert(
      username: username,
      alert: alert.toJson(),
    );
  }

  Future<void> removeAlert(String id) async {
    final username = await _currentUsername();
    if (username == null) {
      throw Exception('You must be signed in to remove alerts.');
    }

    await _apiService.deleteAlert(
      username: username,
      alertId: id,
    );
  }

  Future<List<TriggeredPriceAlert>> checkAlerts({
    double? latitude,
    double? longitude,
    double? maxRadiusKm,
  }) async {
    final alerts = await getAlerts();
    if (alerts.isEmpty) {
      return const <TriggeredPriceAlert>[];
    }

    late final SelectionOptionsModel options;
    try {
      options = await _apiService.fetchSelectionOptions(
        latitude: latitude,
        longitude: longitude,
        maxRadiusKm: maxRadiusKm,
      );
    } catch (_) {
      return const <TriggeredPriceAlert>[];
    }

    final triggered = <TriggeredPriceAlert>[];

    for (final alert in alerts) {
      final resolvedCropId = alert.cropId.trim().isNotEmpty
          ? alert.cropId.trim()
          : _slugify(alert.cropName);
      if (resolvedCropId.isEmpty) {
        continue;
      }

      final marketOptions = options.marketOptions[resolvedCropId];
      if (marketOptions == null || marketOptions.isEmpty) {
        continue;
      }

      final resolvedMarket = alert.market.trim();
      final MarketOption marketOption = resolvedMarket.isEmpty
          ? marketOptions.first
          : marketOptions.firstWhere(
              (option) => option.market == resolvedMarket,
              orElse: () => marketOptions.first,
            );

      final currentPrice = marketOption.currentPrice;
      final shouldTrigger =
          (alert.isAbove && currentPrice >= alert.targetPrice) ||
              (!alert.isAbove && currentPrice <= alert.targetPrice);
      if (!shouldTrigger) {
        continue;
      }

      triggered.add(
        TriggeredPriceAlert(
          alert: alert.copyWith(
            cropId: resolvedCropId,
            market: marketOption.market,
          ),
          currentPrice: currentPrice,
          lastUpdated: marketOption.lastUpdated,
        ),
      );
    }

    return triggered;
  }
}

class PriceAlert {
  final String id;
  final String cropId;
  final String cropName;
  final String market;
  final double targetPrice;
  final bool isAbove; // true for price above target, false for below
  final DateTime createdAt;

  PriceAlert({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.market,
    required this.targetPrice,
    required this.isAbove,
    required this.createdAt,
  });

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    final rawCropName =
        (json['cropName'] ?? json['crop_name'] ?? '') as Object?;
    final cropName = rawCropName.toString().trim();

    final rawCropId = (json['cropId'] ?? json['crop_id'] ?? '') as Object?;
    final cropId = rawCropId.toString().trim();

    final rawMarket = (json['market'] ?? '') as Object?;
    final market = rawMarket.toString().trim();

    final rawId = (json['id'] ?? '') as Object?;
    final id = rawId.toString().trim().isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : rawId.toString().trim();

    final rawCreatedAt = (json['createdAt'] ?? json['created_at']) as Object?;
    DateTime createdAt;
    try {
      createdAt = rawCreatedAt == null
          ? DateTime.now()
          : DateTime.parse(rawCreatedAt.toString());
    } catch (_) {
      createdAt = DateTime.now();
    }

    final rawTargetPrice =
        (json['targetPrice'] ?? json['target_price']) as Object?;
    final targetPrice = rawTargetPrice is num
        ? rawTargetPrice.toDouble()
        : double.tryParse(rawTargetPrice?.toString() ?? '') ?? 0.0;

    final rawIsAbove = (json['isAbove'] ?? json['is_above']) as Object?;
    final isAbove = rawIsAbove is bool
        ? rawIsAbove
        : (rawIsAbove?.toString().toLowerCase() == 'true');

    return PriceAlert(
      id: id,
      cropId: cropId.isNotEmpty ? cropId : _slugify(cropName),
      cropName: cropName,
      market: market,
      targetPrice: targetPrice,
      isAbove: isAbove,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cropId': cropId,
      'cropName': cropName,
      'market': market,
      'targetPrice': targetPrice,
      'isAbove': isAbove,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PriceAlert copyWith({
    String? id,
    String? cropId,
    String? cropName,
    String? market,
    double? targetPrice,
    bool? isAbove,
    DateTime? createdAt,
  }) {
    return PriceAlert(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      market: market ?? this.market,
      targetPrice: targetPrice ?? this.targetPrice,
      isAbove: isAbove ?? this.isAbove,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get description {
    final label = cropName.trim().isNotEmpty ? cropName.trim() : cropId.trim();
    final marketSuffix = market.trim().isEmpty ? '' : ' in ${market.trim()}';
    return '$label$marketSuffix price ${isAbove ? 'above' : 'below'} ₹${targetPrice.toStringAsFixed(0)}';
  }
}

class TriggeredPriceAlert {
  const TriggeredPriceAlert({
    required this.alert,
    required this.currentPrice,
    required this.lastUpdated,
  });

  final PriceAlert alert;
  final double currentPrice;
  final String lastUpdated;
}

String _slugify(String value) {
  final trimmed = value.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return '';
  }

  final slug = trimmed.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return slug.replaceAll(RegExp(r'^-+|-+$'), '');
}
