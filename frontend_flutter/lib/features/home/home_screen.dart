import 'package:flutter/material.dart';
import 'package:crop_price_predictor/l10n/app_localizations.dart';

import '../../core/utils/helpers.dart';
import '../../models/dashboard_summary_model.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final LocationService _location = createLocationService();

  DashboardSummaryModel? _summary;
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

  SoilRecommendationModel? _soilRecommendation;
  String? _soilError;
  bool _loadingSoil = false;

  final ValueNotifier<_HomeTab> _tab = ValueNotifier<_HomeTab>(_HomeTab.dashboard);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _moistureController.dispose();
    _organicMatterController.dispose();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final locationResult = await _location.getCurrentLocation();
      final location = locationResult.location;
      final summary = await _api.fetchDashboardSummary(
        latitude: location?.latitude,
        longitude: location?.longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentLocation = location;
        _summary = summary;
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
        _soilError = '${AppLocalizations.of(context).errorUnableFetchSoil}: $error';
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

  String _dateLine(BuildContext context) {
    return MaterialLocalizations.of(context).formatFullDate(DateTime.now());
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
        return const Color(0xFFFFB400);
      case 'partly_cloudy':
        return const Color(0xFF7E9BB8);
      case 'cloudy':
      case 'fog':
        return const Color(0xFF93A3BE);
      case 'rain':
        return const Color(0xFF5D9BFF);
      case 'snow':
        return const Color(0xFF68B7FF);
      case 'storm':
        return const Color(0xFF6A63D8);
      case 'wind':
        return const Color(0xFF22CBB0);
      default:
        return const Color(0xFF93A3BE);
    }
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
      body: RefreshIndicator(
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

    return ListView(
      children: [
        Text(
          _dateLine(context),
          style: const TextStyle(color: Color(0xFF617080)),
        ),
        const SizedBox(height: 10),
        Text(
          _currentLocation != null
              ? l10n.messageLocationConnected
              : l10n.messageLocationUnavailable,
          style: const TextStyle(color: Color(0xFF617080), height: 1.5),
        ),
        if (_currentLocation != null) ...[
          const SizedBox(height: 6),
          Text(
            '${l10n.homeApproxLocation}: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}',
            style: const TextStyle(color: Color(0xFF617080), fontSize: 12),
          ),
        ],
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
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
                  style: const TextStyle(color: Color(0xFF617080), height: 1.5),
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
                      _loadingSoil ? l10n.soilSubmitting : l10n.soilGetRecommendations,
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
        const SizedBox(height: 18),
        Card(
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
                  value: localeController.language,
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
        const SizedBox(height: 18),
        Card(
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
                Text('${l10n.metricCropsTracked}: ${_summary?.cropsTracked ?? 0}'),
                Text('${l10n.metricMarketsTracked}: ${_summary?.marketsTracked ?? 0}'),
                Text('${l10n.metricLatestDatasetDate}: ${_summary?.latestDate ?? l10n.valueNA}'),
                Text('${l10n.metricBestCrop}: ${_summary?.bestCropName ?? l10n.valueUnknown}'),
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
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
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
    );
  }
}
