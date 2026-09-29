import 'package:flutter/material.dart';
import 'package:crop_price_predictor/l10n/app_localizations.dart';

import '../../core/utils/helpers.dart';
import '../../models/dashboard_summary_model.dart';
import '../../models/prediction_model.dart';
import '../../models/soil_recommendation_model.dart';
import '../../services/api_service.dart';
import '../../services/app_locale_controller.dart';
import '../../services/auth_controller.dart';
import '../../services/location_service.dart';
import '../../l10n/l10n.dart';
import '../chatbot/chatbot_screen.dart';
import '../crop_selection/crop_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _HomeTab { dashboard, soil, prices, assistant, settings }

enum _FarmerJourney { plan, grow, sell }

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final LocationService _location = createLocationService();

  DashboardSummaryModel? _summary;
  Map<String, dynamic>? _dailyGuidance;
  Map<String, dynamic>? _cropWatchOverview;
  NearbyMarketPredictionModel? _sellSnapshot;
  DeviceLocation? _currentLocation;
  String? _error;
  bool _loading = true;

  final TextEditingController _phController =
      TextEditingController(text: '6.5');
  final TextEditingController _nitrogenController =
      TextEditingController(text: '40');
  final TextEditingController _phosphorusController =
      TextEditingController(text: '30');
  final TextEditingController _potassiumController =
      TextEditingController(text: '200');
  final TextEditingController _moistureController =
      TextEditingController(text: '35');
  final TextEditingController _organicMatterController =
      TextEditingController(text: '2.5');
  final TextEditingController _harvestQtyController =
      TextEditingController(text: '0');

  SoilRecommendationModel? _soilRecommendation;
  String? _soilError;
  bool _loadingSoil = false;

  final ValueNotifier<_HomeTab> _tab =
      ValueNotifier<_HomeTab>(_HomeTab.dashboard);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _phController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _moistureController.dispose();
    _organicMatterController.dispose();
    _harvestQtyController.dispose();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = AuthScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final locationResult = await _location.getCurrentLocation();
      final location = locationResult.location;
      final cropWatchOverview = (auth.user ?? '').trim().isNotEmpty
          ? await _api.fetchCropWatchOverview(
              username: auth.user!.trim(),
              latitude: location?.latitude,
              longitude: location?.longitude,
            )
          : <String, dynamic>{};

      final primaryWatch = (((cropWatchOverview['watches'] as List<dynamic>?) ??
                  const <dynamic>[])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
              .isNotEmpty)
          ? (((cropWatchOverview['watches'] as List<dynamic>?) ??
                  const <dynamic>[])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
              .first)
          : null;

      NearbyMarketPredictionModel? sellSnapshot;
      final cropId = primaryWatch?['crop_id']?.toString().trim() ?? '';
      if (cropId.isNotEmpty && location != null) {
        try {
          sellSnapshot = await _api.fetchNearbyMarketPredictions(
            cropId: cropId,
            latitude: location.latitude,
            longitude: location.longitude,
            forecastDays: 7,
            maxRadiusKm: 200,
          );
        } catch (_) {
          sellSnapshot = null;
        }
      }

      final results = await Future.wait([
        _api.fetchDashboardSummary(
          latitude: location?.latitude,
          longitude: location?.longitude,
        ),
        _api.fetchDailyGuidance(
          latitude: location?.latitude,
          longitude: location?.longitude,
          stage: primaryWatch?['stage']?.toString(),
          cropName: primaryWatch?['crop_name']?.toString(),
        ),
      ]);

      final summary = results[0] as DashboardSummaryModel;
      final dailyGuidance = results[1] as Map<String, dynamic>;

      if (!mounted) {
        return;
      }

      setState(() {
        _currentLocation = location;
        _summary = summary;
        _dailyGuidance = dailyGuidance;
        _cropWatchOverview = cropWatchOverview;
        _sellSnapshot = sellSnapshot;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _submitSoil() async {
    setState(() {
      _loadingSoil = true;
      _soilError = null;
    });

    try {
      final result = await _api.fetchSoilRecommendations(
        ph: double.tryParse(_phController.text) ?? 6.5,
        nitrogen: double.tryParse(_nitrogenController.text) ?? 0,
        phosphorus: double.tryParse(_phosphorusController.text) ?? 0,
        potassium: double.tryParse(_potassiumController.text) ?? 0,
        moisture: double.tryParse(_moistureController.text) ?? 0,
        organicMatter: double.tryParse(_organicMatterController.text) ?? 0,
        cropName: _currentTrackedCropName(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _soilRecommendation = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _soilError =
            '${AppLocalizations.of(context).errorUnableFetchSoil}: $error';
        _soilRecommendation = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSoil = false;
        });
      }
    }
  }

  String? _currentTrackedCropName() {
    final watches = _trackedWatches();
    if (watches.isEmpty) {
      return null;
    }
    return watches.first['crop_name']?.toString();
  }

  List<Map<String, dynamic>> _trackedWatches() {
    return (_cropWatchOverview?['watches'] as List<dynamic>? ??
            const <dynamic>[])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic>? _primaryWatch() {
    final watches = _trackedWatches();
    if (watches.isEmpty) {
      return null;
    }
    return watches.first;
  }

  int? _plantAgeDays(Map<String, dynamic>? watch) {
    final value = watch?['plant_age_days'];
    if (value == null) {
      return null;
    }
    return int.tryParse(value.toString());
  }

  int? _daysUntilHarvest(Map<String, dynamic>? watch) {
    final value = watch?['days_until_harvest'];
    if (value == null) {
      return null;
    }
    return int.tryParse(value.toString());
  }

  String _normalizeStage(String? stage) {
    switch ((stage ?? '').trim()) {
      case 'early_growth':
      case 'vegetative':
      case 'flowering':
      case 'pre_harvest':
      case 'ready_to_sell':
      case 'sold':
        return stage!.trim();
      default:
        return 'vegetative';
    }
  }

  NearbyMarketPredictionItem? _bestSellMarketItem() {
    final snapshot = _sellSnapshot;
    if (snapshot == null || snapshot.nearestMarkets.isEmpty) {
      return null;
    }
    return snapshot.nearestMarkets.reduce(
      (current, next) =>
          next.currentPrice > current.currentPrice ? next : current,
    );
  }

  IconData _weatherIcon(String iconKey) {
    switch (iconKey) {
      case 'sunny':
        return Icons.wb_sunny_outlined;
      case 'partly_cloudy':
        return Icons.wb_cloudy_outlined;
      case 'cloudy':
        return Icons.cloud_outlined;
      case 'rain':
        return Icons.grain_outlined;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'fog':
        return Icons.blur_on_rounded;
      case 'storm':
        return Icons.thunderstorm_outlined;
      case 'wind':
        return Icons.air_rounded;
      default:
        return Icons.cloud_outlined;
    }
  }

  Color _weatherColor(String iconKey) {
    switch (iconKey) {
      case 'sunny':
        return const Color(0xFFC58B2C);
      case 'partly_cloudy':
        return const Color(0xFF8A8A6A);
      case 'cloudy':
      case 'fog':
        return const Color(0xFF8C8A80);
      case 'rain':
        return const Color(0xFF6D8C6A);
      case 'snow':
        return const Color(0xFF7BA39C);
      case 'storm':
        return const Color(0xFF6A5646);
      case 'wind':
        return const Color(0xFF7B8F5C);
      default:
        return const Color(0xFF8C8A80);
    }
  }

  void _openJourney(_FarmerJourney journey) {
    switch (journey) {
      case _FarmerJourney.plan:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CropSelectionScreen(),
          ),
        );
        return;
      case _FarmerJourney.grow:
        _tab.value = _HomeTab.soil;
        return;
      case _FarmerJourney.sell:
        _tab.value = _HomeTab.prices;
        return;
    }
  }

  List<String> _todayGuidance(DashboardSummaryModel? summary) {
    final rawGuidance = _dailyGuidance?['guidance'];
    if (rawGuidance is List) {
      final items = rawGuidance
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
      if (items.isNotEmpty) {
        return items;
      }
    }

    return <String>[
      'Check your crop stage and open the planner before making any sowing decision.',
      'Review soil conditions before applying fertilizer or irrigation.',
      'Use the price tab to compare selling opportunities before taking produce to market.',
    ];
  }

  Widget _guidanceBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.egg_outlined, size: 18, color: Color(0xFF7A4E2D)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2E3A4A),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stagePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E2D2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF7A4E2D),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _adviceChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E7DA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2C9B4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF7A4E2D),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _marketPill(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E5D8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF7A4E2D),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _adviceLine({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2E3A4A),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sellSummaryText() {
    final snapshot = _sellSnapshot;
    if (snapshot == null || snapshot.nearestMarkets.isEmpty) {
      return 'No nearby market comparison is available yet. Open the sell flow to search mandis manually.';
    }

    final bestMarket = snapshot.nearestMarkets.reduce(
      (current, next) =>
          next.currentPrice > current.currentPrice ? next : current,
    );
    final distanceText = bestMarket.distanceKm == null
        ? 'nearby'
        : '${bestMarket.distanceKm!.toStringAsFixed(1)} km away';

    return 'Best nearby market: ${bestMarket.market} at ${Helpers.formatCurrency(bestMarket.currentPrice)} ($distanceText). ${bestMarket.recommendation}';
  }

  ({Color upper, Color lower, Color furrow}) _heroPalette({
    required String stage,
    required bool hasCrop,
    required bool readyToSell,
  }) {
    if (readyToSell) {
      return (
        upper: const Color(0xFF713E2C),
        lower: const Color(0xFFB9603D),
        furrow: const Color(0xFFFFD09A),
      );
    }

    if (!hasCrop) {
      return (
        upper: const Color(0xFF294F3B),
        lower: const Color(0xFF52764D),
        furrow: const Color(0xFFB8CE9D),
      );
    }

    switch (stage) {
      case 'early_growth':
        return (
          upper: const Color(0xFF244C3A),
          lower: const Color(0xFF397A52),
          furrow: const Color(0xFFB8D69D),
        );
      case 'flowering':
        return (
          upper: const Color(0xFF36553A),
          lower: const Color(0xFF7D8050),
          furrow: const Color(0xFFE3D08A),
        );
      case 'pre_harvest':
        return (
          upper: const Color(0xFF59452D),
          lower: const Color(0xFFA57938),
          furrow: const Color(0xFFF0D18B),
        );
      default:
        return (
          upper: const Color(0xFF28513C),
          lower: const Color(0xFF557345),
          furrow: const Color(0xFFC2D4A1),
        );
    }
  }

  double _harvestQuantity() {
    return double.tryParse(_harvestQtyController.text.trim()) ?? 0;
  }

  double _sellConfidenceScore() {
    final harvestQty = _harvestQuantity();
    if (harvestQty <= 0) {
      return 0;
    }

    final watch = _primaryWatch();
    final readyToSell = watch?['is_sell_ready'] == true;
    final stage = _normalizeStage(watch?['stage']?.toString());
    final daysToHarvest = _daysUntilHarvest(watch);
    final plantAgeDays = _plantAgeDays(watch);
    final snapshot = _sellSnapshot;
    double score = 35;

    if (readyToSell) {
      score += 25;
    } else if (stage == 'pre_harvest') {
      score += 18;
    } else if (stage == 'early_growth') {
      score += 2;
    } else if (stage == 'vegetative') {
      score += 8;
    } else if (stage == 'flowering') {
      score += 12;
    }

    if (daysToHarvest != null) {
      if (daysToHarvest <= 0) {
        score += 20;
      } else if (daysToHarvest <= 7) {
        score += 16;
      } else if (daysToHarvest <= 14) {
        score += 10;
      } else if (daysToHarvest <= 30) {
        score += 4;
      } else {
        score -= 4;
      }
    }

    if (plantAgeDays != null) {
      if (plantAgeDays < 14) {
        score -= 18;
      } else if (plantAgeDays < 45) {
        score -= 8;
      } else if (plantAgeDays < 75) {
        score += 6;
      } else {
        score += 12;
      }
    }

    if (snapshot != null && snapshot.nearestMarkets.isNotEmpty) {
      final prices =
          snapshot.nearestMarkets.map((item) => item.currentPrice).toList();
      final maxPrice = prices.reduce((a, b) => a > b ? a : b);
      final minPrice = prices.reduce((a, b) => a < b ? a : b);
      final spread = maxPrice - minPrice;

      if (spread >= 12) {
        score += 20;
      } else if (spread >= 6) {
        score += 10;
      } else {
        score += 5;
      }
    } else {
      score -= 10;
    }

    if (harvestQty >= 500) {
      score += 10;
    } else if (harvestQty >= 100) {
      score += 5;
    } else {
      score -= 5;
    }

    return score.clamp(0, 100).toDouble();
  }

  String _sellSignalText() {
    final snapshot = _sellSnapshot;
    final watch = _primaryWatch();
    final readyToSell = watch?['is_sell_ready'] == true;
    final stage = _normalizeStage(watch?['stage']?.toString());
    final daysToHarvest = _daysUntilHarvest(watch);
    final plantAgeDays = _plantAgeDays(watch);
    final harvestQty = _harvestQuantity();

    if (harvestQty <= 0) {
      return 'Add harvest quantity to unlock the sell signal.';
    }

    if (!readyToSell) {
      if (stage == 'pre_harvest' ||
          (daysToHarvest != null && daysToHarvest <= 14)) {
        return 'Wait';
      }
      if (stage == 'early_growth' ||
          (plantAgeDays != null && plantAgeDays < 45) ||
          (daysToHarvest != null && daysToHarvest > 14)) {
        return 'Wait';
      }
    }

    if (readyToSell && snapshot != null && snapshot.nearestMarkets.isNotEmpty) {
      return 'Sell now';
    }

    if (snapshot != null && snapshot.nearestMarkets.isNotEmpty) {
      final prices =
          snapshot.nearestMarkets.map((item) => item.currentPrice).toList();
      final maxPrice = prices.reduce((a, b) => a > b ? a : b);
      final minPrice = prices.reduce((a, b) => a < b ? a : b);
      if (maxPrice - minPrice >= 12) {
        return 'Sell now';
      }
    }

    return 'Wait';
  }

  Color _sellSignalColor() {
    final text = _sellSignalText();
    if (text == 'Sell now') {
      return const Color(0xFF2F6B3D);
    }
    if (text.startsWith('Add harvest quantity')) {
      return const Color(0xFF8A5A44);
    }
    return const Color(0xFF9A6A1F);
  }

  String _sellConfidenceLabel(double score) {
    if (score >= 75) {
      return 'Strong';
    }
    if (score >= 50) {
      return 'Moderate';
    }
    return 'Unclear';
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFCF7EF),
              Color(0xFFF6EBDD),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF726456),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing,
                  ],
                ],
              ),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.92), size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.74),
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  String _weatherWatchText(
      DashboardSummaryModel? summary, Map<String, dynamic>? watch) {
    final weather = summary?.weatherForecast;
    final stage = (watch?['stage'] ?? '').toString().toLowerCase();
    if (weather == null || weather.isEmpty) {
      if (stage == 'ready_to_sell') {
        return 'Weather data is limited right now, so confirm local transport conditions before taking produce to market.';
      }
      return 'Weather data is limited right now, so confirm local conditions before field work.';
    }

    final first = weather.first;
    final iconKey = first.iconKey.toLowerCase();
    final condition = first.condition.toLowerCase();
    if (iconKey == 'rain' || condition.contains('rain')) {
      if (stage == 'flowering' || stage == 'pre_harvest') {
        return 'Rain is likely soon, which can affect flowering or harvest timing, so plan field work carefully.';
      }
      return 'Rain is likely soon, so delay spraying and protect harvested produce from moisture.';
    }
    if (iconKey == 'storm' ||
        iconKey == 'wind' ||
        condition.contains('storm')) {
      if (stage == 'ready_to_sell') {
        return 'Wind or storm risk is present, so avoid moving harvested produce until travel is safe.';
      }
      return 'Wind or storm risk is present, so secure loose materials and avoid spraying today.';
    }
    if (iconKey == 'sunny') {
      if (stage == 'early_growth' || stage == 'vegetative') {
        return 'Dry weather is likely, so check irrigation timing and protect the crop from moisture stress.';
      }
      return 'Dry weather is likely, so check irrigation timing and field moisture before working.';
    }
    if (iconKey == 'fog') {
      return 'Low visibility weather is expected, so plan travel and field work carefully.';
    }
    return 'Weather looks mostly stable, but keep watching changes before major field work.';
  }

  String _soilWatchText(Map<String, dynamic>? watch) {
    final ph = double.tryParse(_phController.text) ?? 6.5;
    final nitrogen = double.tryParse(_nitrogenController.text) ?? 0;
    final phosphorus = double.tryParse(_phosphorusController.text) ?? 0;
    final potassium = double.tryParse(_potassiumController.text) ?? 0;
    final moisture = double.tryParse(_moistureController.text) ?? 0;
    final organicMatter = double.tryParse(_organicMatterController.text) ?? 0;
    final stage = (watch?['stage'] ?? '').toString().toLowerCase();

    final parts = <String>[];
    if (ph < 6) {
      parts.add(
          'Soil looks acidic, so avoid over-fertilizing until pH is reviewed.');
    } else if (ph > 7.5) {
      parts.add(
          'Soil looks alkaline, so nutrient uptake may be reduced for some crops.');
    } else {
      parts.add('Soil pH is in a workable range for many crops.');
    }

    if (moisture < 25) {
      parts.add(
          'Moisture is low, so irrigation planning should be checked soon.');
    } else if (moisture > 65) {
      parts.add(
          'Moisture is high, so drainage and disease risk should be watched.');
    } else {
      parts.add('Moisture is moderate, which is usually easier to manage.');
    }

    if (nitrogen < 25 || phosphorus < 20 || potassium < 120) {
      parts.add(
          'One or more nutrients look low, so use the soil tab before fertilizer decisions.');
    }

    if (organicMatter < 2) {
      parts.add(
          'Organic matter is low, so soil health support may be needed over time.');
    }

    if (stage == 'flowering' && moisture < 35) {
      parts.add(
          'Flowering crops are more sensitive to dry soil, so watch moisture closely this week.');
    }
    if (stage == 'ready_to_sell') {
      parts.add(
          'The crop is close to selling, so avoid unnecessary soil stress and field damage now.');
    }

    return parts.join(' ');
  }

  List<String> _cropSpecificSoilAdvice(Map<String, dynamic>? watch) {
    final cropName = (watch?['crop_name'] ?? '').toString().toLowerCase();
    final stage = (watch?['stage'] ?? '').toString().toLowerCase();
    final advice = <String>[];

    if (cropName.contains('rice') || cropName.contains('paddy')) {
      advice.add(
          'Rice and paddy crops usually prefer steadier moisture, so avoid letting the field dry for long.');
      if (stage == 'early_growth' || stage == 'vegetative') {
        advice.add(
            'During early growth, keep weed pressure and water balance under close watch.');
      }
    } else if (cropName.contains('wheat')) {
      advice.add(
          'Wheat benefits from balanced nutrition and moderate moisture during active growth.');
      if (stage == 'flowering' || stage == 'pre_harvest') {
        advice.add(
            'At flowering or grain fill, avoid heat and water stress where possible.');
      }
    } else if (cropName.contains('maize') || cropName.contains('corn')) {
      advice.add(
          'Maize responds well to timely nitrogen support and enough moisture before tasseling.');
      if ((double.tryParse(_nitrogenController.text) ?? 0) < 35) {
        advice.add(
            'Nitrogen looks a little low for maize, so review top-dressing timing.');
      }
    } else if (cropName.contains('cotton')) {
      advice.add(
          'Cotton usually needs careful moisture balance and should not stay waterlogged.');
      if ((double.tryParse(_moistureController.text) ?? 0) > 60) {
        advice.add(
            'Moisture looks high for cotton, so drainage and disease risk should be watched.');
      }
    } else if (cropName.contains('tomato') || cropName.contains('potato')) {
      advice.add(
          'Vegetable crops like tomato and potato benefit from steady moisture and strong disease monitoring.');
      if ((double.tryParse(_organicMatterController.text) ?? 0) < 2) {
        advice.add(
            'Organic matter is low, so soil structure support may help these crops.');
      }
    } else if (cropName.contains('soy')) {
      advice.add(
          'Soybean usually benefits from well-drained soil and balanced phosphorus support.');
    }

    return advice;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.buttonRefresh,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F1E9),
              Color(0xFFF9F7F1),
              Color(0xFFEAF3E4),
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _load,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null && _summary == null)
                    ? ListView(
                        key: const ValueKey('error'),
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 120),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: Text(l10n.buttonRetry),
                          ),
                        ],
                      )
                    : SafeArea(
                        key: const ValueKey('content'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: ValueListenableBuilder<_HomeTab>(
                            valueListenable: _tab,
                            builder: (context, tab, _) {
                              return IndexedStack(
                                index: tab.index,
                                children: [
                                  _dashboardPage(),
                                  _soilPage(),
                                  _pricesPage(),
                                  _assistantPage(),
                                  _settingsPage(),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<_HomeTab>(
        valueListenable: _tab,
        builder: (context, tab, _) {
          return NavigationBar(
            selectedIndex: tab.index,
            onDestinationSelected: (index) {
              _tab.value = _HomeTab.values[index];
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                label: l10n.navDashboard,
              ),
              NavigationDestination(
                icon: const Icon(Icons.eco_outlined),
                label: l10n.navSoil,
              ),
              NavigationDestination(
                icon: const Icon(Icons.show_chart_rounded),
                label: l10n.navPrices,
              ),
              NavigationDestination(
                icon: const Icon(Icons.smart_toy_outlined),
                label: l10n.navAssistant,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                label: l10n.navSettings,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dashboardPage() {
    final l10n = AppLocalizations.of(context);
    final summary = _summary;
    final cropWatch = _cropWatchOverview;
    final watches =
        (cropWatch?['watches'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    final primaryWatch = watches.isNotEmpty ? watches.first : null;
    final stage = _normalizeStage(primaryWatch?['stage']?.toString());
    final stageLabel = (primaryWatch?['crop_stage_label'] ??
            primaryWatch?['stage'] ??
            'No crop track')
        .toString();
    final readyToSell = (primaryWatch?['is_sell_ready'] as bool?) == true;
    final heroTitle = primaryWatch == null
        ? 'Farmer command center'
        : '${primaryWatch['crop_name'] ?? 'Your crop'} in focus';
    final heroSubtitle = primaryWatch == null
        ? 'Plan what to sow, watch the season, and choose the right time to sell.'
        : 'Your crop, weather, and market guidance in one daily view.';
    final heroPalette = _heroPalette(
      stage: stage,
      hasCrop: primaryWatch != null,
      readyToSell: readyToSell,
    );
    const stageLegend = [
      ('early_growth', 'Early growth'),
      ('vegetative', 'Vegetative'),
      ('flowering', 'Flowering'),
      ('pre_harvest', 'Pre-harvest'),
      ('ready_to_sell', 'Ready to sell'),
    ];

    return ListView(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeInOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [heroPalette.upper, heroPalette.lower],
              ),
              boxShadow: [
                BoxShadow(
                  color: heroPalette.upper.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FarmBackdropPainter(
                      furrowColor: heroPalette.furrow,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 54,
                            height: 54,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFFFFE7C6)
                                            .withValues(alpha: 0.45),
                                        const Color(0xFFD9B48F)
                                            .withValues(alpha: 0.18),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.58, 1.0],
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.grass_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  heroTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  heroSubtitle,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.76),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _heroStat(
                            label: 'Crop stage',
                            value: stageLabel,
                            icon: Icons.timeline_outlined,
                          ),
                          _heroStat(
                            label: 'Best crop',
                            value: summary?.bestCropName ?? l10n.valueUnknown,
                            icon: Icons.local_florist_outlined,
                          ),
                          _heroStat(
                            label: 'Markets tracked',
                            value: '${summary?.marketsTracked ?? 0}',
                            icon: Icons.storefront_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _openJourney(_FarmerJourney.plan),
                            icon: const Icon(Icons.edit_note_rounded),
                            label: const Text('Plan crop'),
                          ),
                          FilledButton.icon(
                            onPressed: () => _openJourney(_FarmerJourney.grow),
                            icon: const Icon(Icons.nature_people_outlined),
                            label: const Text('Crop care'),
                          ),
                          FilledButton.icon(
                            onPressed: () => _openJourney(_FarmerJourney.sell),
                            icon: const Icon(Icons.storefront_outlined),
                            label: const Text('Sell now'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _sectionCard(
          title: 'Today\'s guidance',
          subtitle:
              'Simple actions to help with planning, crop care, and selling today.',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E7DA),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_todayGuidance(summary).length} tips',
              style: const TextStyle(
                color: Color(0xFF7A4E2D),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          children:
              _todayGuidance(summary).take(3).map(_guidanceBullet).toList(),
        ),
        const SizedBox(height: 18),
        _sectionCard(
          title: 'Weather + soil watch',
          subtitle:
              'A quick check before you irrigate, spray, fertilize, or plan a market trip.',
          children: [
            _adviceLine(
              icon: Icons.cloud_outlined,
              iconColor: const Color(0xFF7A4E2D),
              text: _weatherWatchText(summary, primaryWatch),
            ),
            _adviceLine(
              icon: Icons.water_drop_outlined,
              iconColor: const Color(0xFF4F6B3C),
              text: _soilWatchText(primaryWatch),
            ),
            const SizedBox(height: 6),
            if (_cropSpecificSoilAdvice(primaryWatch).isNotEmpty)
              Wrap(
                children: _cropSpecificSoilAdvice(primaryWatch)
                    .take(3)
                    .map(_adviceChip)
                    .toList(),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _openJourney(_FarmerJourney.grow),
              child: const Text('Open crop care and soil check'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _sectionCard(
          title: 'Crop stage tracker',
          subtitle:
              'The current crop stage, time remaining, and next action for your tracked crop.',
          trailing: _stagePill(stageLabel),
          children: [
            if (primaryWatch == null)
              const Text(
                'No crop watch is saved yet. Add one from the crop watch flow to see season tracking here.',
                style: TextStyle(color: Color(0xFF617080), height: 1.45),
              )
            else ...[
              Row(
                children: [
                  _adviceChip(
                      'Plant age: ${_plantAgeDays(primaryWatch)?.toString() ?? 'N/A'} days'),
                  _adviceChip(
                      'To harvest: ${_daysUntilHarvest(primaryWatch)?.toString() ?? 'N/A'}'),
                  _adviceChip('Sell ready: ${readyToSell ? 'yes' : 'no'}'),
                ],
              ),
              const SizedBox(height: 6),
              ...((primaryWatch['advisories'] as List<dynamic>? ??
                      const <dynamic>[])
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .take(2)
                  .map(
                    (item) => _adviceLine(
                      icon: Icons.info_outline,
                      iconColor: const Color(0xFF7A4E2D),
                      text:
                          '${item['title'] ?? 'Update'}: ${item['summary'] ?? ''}',
                    ),
                  )),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stageLegend
                    .map(
                      (entry) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: entry.$1 == stage
                              ? const Color(0xFFE8D4B1)
                              : const Color(0xFFF6EBDD),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFD9C3A1)),
                        ),
                        child: Text(
                          entry.$2,
                          style: TextStyle(
                            color: Colors.brown.shade700,
                            fontSize: 12,
                            fontWeight: entry.$1 == stage
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        _sectionCard(
          title: 'Sell-time snapshot',
          subtitle:
              'A quick view of market strength before you move produce to the mandi.',
          trailing: const Icon(
            Icons.storefront_outlined,
            color: Color(0xFF8A5A44),
          ),
          children: [
            _adviceLine(
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFF8A5A44),
              text:
                  'Best crop signal now: ${summary?.bestCropName ?? l10n.valueUnknown} at ${summary == null ? l10n.valueNA : Helpers.formatCurrency(summary.bestCropPrice)}.',
            ),
            _adviceLine(
              icon: Icons.calendar_today_outlined,
              iconColor: const Color(0xFF6F7B4A),
              text:
                  'Use the price tab to compare nearby mandis and choose the strongest sell window.',
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _harvestQtyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Estimated harvest quantity',
                hintText: 'e.g. 1200',
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                filled: true,
                fillColor: const Color(0xFFF4E7CF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFD9C3A1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFD9C3A1)),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _sellSignalColor().withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: _sellSignalColor().withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    _sellSignalText(),
                    style: TextStyle(
                      color: _sellSignalColor(),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Signal updates from harvest quantity, readiness, and nearby market spread.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8EFE0),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD9C3A1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 18,
                        color: Color(0xFF8A5A44),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Inventory summary',
                        style: TextStyle(
                          color: Colors.brown.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _adviceChip(
                          'Total harvest: ${_harvestQuantity().toStringAsFixed(0)}'),
                      _adviceChip(
                          'Stock left: ${_harvestQuantity().toStringAsFixed(0)}'),
                      _adviceChip(
                        'Estimated market value: ${() {
                          final bestMarket = _bestSellMarketItem();
                          if (bestMarket == null) {
                            return l10n.valueNA;
                          }
                          return Helpers.formatCurrency(
                              bestMarket.currentPrice * _harvestQuantity());
                        }()}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _sellConfidenceScore() / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE7D5B8),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_sellSignalColor()),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sell confidence: ${_sellConfidenceLabel(_sellConfidenceScore())} (${_sellConfidenceScore().toStringAsFixed(0)}%)',
                    style: TextStyle(
                      color: Colors.brown.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_sellSnapshot != null &&
                _sellSnapshot!.nearestMarkets.isNotEmpty) ...[
              const SizedBox(height: 2),
              Wrap(
                children: _sellSnapshot!.nearestMarkets
                    .take(3)
                    .map(
                      (item) => _marketPill(
                        '${item.market} • ${Helpers.formatCurrency(item.currentPrice)}',
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 6),
              _adviceLine(
                icon: Icons.map_outlined,
                iconColor: const Color(0xFF8A5A44),
                text: _sellSummaryText(),
              ),
            ],
            TextButton(
              onPressed: () => _openJourney(_FarmerJourney.sell),
              child: const Text('Open sell guidance'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: l10n.metricCropsTracked,
              value: '${summary?.cropsTracked ?? 0}',
              icon: Icons.grass_rounded,
            ),
            _MetricCard(
              label: l10n.metricMarketsTracked,
              value: '${summary?.marketsTracked ?? 0}',
              icon: Icons.storefront_outlined,
            ),
            _MetricCard(
              label: l10n.metricBestCrop,
              value: summary?.bestCropName ?? l10n.valueUnknown,
              icon: Icons.trending_up_rounded,
              helper: summary == null
                  ? null
                  : Helpers.formatCurrency(summary.bestCropPrice),
            ),
            _MetricCard(
              label: l10n.metricLatestDatasetDate,
              value: summary?.latestDate ?? l10n.valueNA,
              icon: Icons.event_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFCF7EF),
                  Color(0xFFF6EBDD),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SubtleRowTexturePainter(
                          color: Color(0x1A7A4E2D),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeWeatherTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        summary?.weatherSource == 'fallback'
                            ? l10n.homeWeatherFallbackNote
                            : l10n.homeWeatherLiveNote,
                        style: const TextStyle(
                            color: Color(0xFF726456), height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      ...?summary?.weatherForecast.map(
                        (day) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            _weatherIcon(day.iconKey),
                            color: _weatherColor(day.iconKey),
                          ),
                          title: Text('${day.label}  ${day.condition}'),
                          trailing: Text('${day.tempMaxC}/${day.tempMinC}C'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _soilPage() {
    final l10n = AppLocalizations.of(context);
    final recommendation = _soilRecommendation;

    return ListView(
      children: [
        Text(
          l10n.homeSoilTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.homeSoilSubtitle,
          style: const TextStyle(color: Color(0xFF617080), height: 1.5),
        ),
        const SizedBox(height: 18),
        Card(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFCF7EF),
                  Color(0xFFF6EBDD),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _soilField(_phController, l10n.soilPh),
                  const SizedBox(height: 10),
                  _soilField(_nitrogenController, l10n.soilNitrogen),
                  const SizedBox(height: 10),
                  _soilField(_phosphorusController, l10n.soilPhosphorus),
                  const SizedBox(height: 10),
                  _soilField(_potassiumController, l10n.soilPotassium),
                  const SizedBox(height: 10),
                  _soilField(_moistureController, l10n.soilMoisture),
                  const SizedBox(height: 10),
                  _soilField(_organicMatterController, l10n.soilOrganicMatter),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loadingSoil ? null : _submitSoil,
                      child: Text(
                        _loadingSoil
                            ? l10n.soilSubmitting
                            : l10n.soilGetRecommendations,
                      ),
                    ),
                  ),
                  if (_soilError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _soilError!,
                      style: const TextStyle(color: Color(0xFFB42318)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (recommendation != null) ...[
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.soilBackendResult,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  if (recommendation.summary.isNotEmpty)
                    Text(recommendation.summary),
                  if (recommendation.recommendations.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...recommendation.recommendations
                        .map((item) => Text('• $item')),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _pricesPage() {
    final l10n = AppLocalizations.of(context);

    return ListView(
      children: [
        Text(
          l10n.priceAdvisorTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.priceAdvisorSubtitle,
          style: const TextStyle(color: Color(0xFF617080), height: 1.5),
        ),
        const SizedBox(height: 18),
        Card(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFDF7EE),
                  Color(0xFFF5E6D5),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CropSelectionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.show_chart_rounded),
                    label: Text(l10n.navPrices),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _assistantPage() {
    final l10n = AppLocalizations.of(context);

    return ListView(
      children: [
        Text(
          l10n.assistantTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.assistantSubtitle,
          style: const TextStyle(color: Color(0xFF617080), height: 1.5),
        ),
        const SizedBox(height: 18),
        Card(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFCF7EF),
                  Color(0xFFF6EBDD),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChatbotScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.smart_toy_outlined),
                label: Text(l10n.navAssistant),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingsPage() {
    final l10n = AppLocalizations.of(context);
    final localeController = AppLocaleScope.of(context);
    final authController = AuthScope.of(context);

    return ListView(
      children: [
        Text(
          l10n.titleSettings,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFCF7EF),
                  Color(0xFFF6EBDD),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Signed in as: ${authController.user ?? '-'}'),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: authController.working
                        ? null
                        : () => authController.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFCF7EF),
                  Color(0xFFF6EBDD),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.labelLanguage,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.labelLanguageHelp,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AppLanguage>(
                    initialValue: localeController.language,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: L10n.supportedLanguages
                        .map(
                          (language) => DropdownMenuItem<AppLanguage>(
                            value: language,
                            child: Text(
                              '${language.nativeName} (${language.englishName})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      localeController.setLanguage(value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFCF7EF),
                  Color(0xFFF6EBDD),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.titleBackendSnapshot,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                      '${l10n.metricCropsTracked}: ${_summary?.cropsTracked ?? 0}'),
                  Text(
                      '${l10n.metricMarketsTracked}: ${_summary?.marketsTracked ?? 0}'),
                  Text(
                      '${l10n.metricLatestDatasetDate}: ${_summary?.latestDate ?? l10n.valueNA}'),
                  Text(
                      '${l10n.metricBestCrop}: ${_summary?.bestCropName ?? l10n.valueUnknown}'),
                  const SizedBox(height: 12),
                  Text(
                    _currentLocation != null
                        ? l10n.messageLocationConnected
                        : l10n.messageLocationUnavailable,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _load,
                    child: Text(l10n.buttonRefresh),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _soilField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _FarmBackdropPainter extends CustomPainter {
  const _FarmBackdropPainter({required this.furrowColor});

  final Color furrowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final furrowPaint = Paint()
      ..color = furrowColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (var row = 0; row < 5; row++) {
      final baseY = size.height * (0.58 + row * 0.09);
      final rowPath = Path()
        ..moveTo(-12, baseY)
        ..quadraticBezierTo(
          size.width * 0.28,
          baseY - size.height * 0.08,
          size.width * 0.56,
          baseY,
        )
        ..quadraticBezierTo(
          size.width * 0.78,
          baseY + size.height * 0.05,
          size.width + 12,
          baseY - size.height * 0.01,
        );
      canvas.drawPath(rowPath, furrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FarmBackdropPainter oldDelegate) =>
      oldDelegate.furrowColor != furrowColor;
}

class _SubtleRowTexturePainter extends CustomPainter {
  const _SubtleRowTexturePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    for (var i = 0; i < 4; i++) {
      final baseY = size.height * (0.18 + i * 0.17);
      final path = Path()
        ..moveTo(-8, baseY)
        ..quadraticBezierTo(
          size.width * 0.24,
          baseY - 8,
          size.width * 0.5,
          baseY + 3,
        )
        ..quadraticBezierTo(
          size.width * 0.78,
          baseY + 15,
          size.width + 8,
          baseY + 2,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.helper,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFDF8F0),
                Color(0xFFF3E7DA),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: const Color(0xFF7A4E2D)),
                const SizedBox(height: 14),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(label),
                if (helper != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    helper!,
                    style: const TextStyle(color: Color(0xFF617080)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
