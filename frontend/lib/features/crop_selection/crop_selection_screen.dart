import 'package:flutter/material.dart';
import 'package:crop_price_predictor/l10n/app_localizations.dart';

import '../../core/utils/helpers.dart';
import '../../models/crop_model.dart';
import '../../models/prediction_model.dart';
import '../../models/selection_options_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../prediction/widgets/price_chart.dart';
import '../recommendation/best_sell_screen.dart';

class CropSelectionScreen extends StatefulWidget {
  const CropSelectionScreen({super.key});

  @override
  State<CropSelectionScreen> createState() => _CropSelectionScreenState();
}

class _CropSelectionScreenState extends State<CropSelectionScreen> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = createLocationService();

  final TextEditingController _daysController =
      TextEditingController(text: '7');
  final TextEditingController _marketSearchController = TextEditingController();

  static const double _minRadiusKm = 25;
  static const double _maxRadiusKm = 300;

  late Future<SelectionOptionsModel> _selectionFuture;
  CropModel? _selectedCrop;
  MarketOption? _selectedMarket;
  String? _typedMarketName;

  PredictionModel? _prediction;
  String? _predictionError;

  DeviceLocation? _currentLocation;
  String? _locationErrorMessage;
  bool _resolvingLocation = false;
  double _selectedRadiusKm = 150;
  bool _loadingPrediction = false;

  @override
  void initState() {
    super.initState();
    _selectionFuture = _fetchSelectionOptions();
    _resolveLocation();
  }

  @override
  void dispose() {
    _daysController.dispose();
    _marketSearchController.dispose();
    super.dispose();
  }

  Future<SelectionOptionsModel> _fetchSelectionOptions() {
    return _apiService.fetchSelectionOptions(
      latitude: _currentLocation?.latitude,
      longitude: _currentLocation?.longitude,
      maxRadiusKm: _currentLocation == null ? null : _selectedRadiusKm,
    );
  }

  Future<void> _reloadSelectionOptions() async {
    setState(() {
      _selectionFuture = _fetchSelectionOptions();
      _prediction = null;
      _predictionError = null;
      _selectedMarket = null;
    });
  }

  Future<void> _refresh() async {
    await _resolveLocation();
    if (!mounted) {
      return;
    }
    await _reloadSelectionOptions();
  }

  Future<void> _resolveLocation() async {
    setState(() {
      _resolvingLocation = true;
      _locationErrorMessage = null;
    });

    final result = await _locationService.getCurrentLocation();
    if (!mounted) {
      return;
    }

    setState(() {
      _currentLocation = result.location;
      _locationErrorMessage = result.errorMessage;
      _resolvingLocation = false;
      _selectionFuture = _fetchSelectionOptions();
    });
  }

  Future<void> _loadPrediction() async {
    final crop = _selectedCrop;
    final market = _selectedMarket?.market ?? _typedMarketName;

    if (crop == null || market == null || market.trim().isEmpty) {
      setState(() {
        _predictionError =
            AppLocalizations.of(context).cropSelectionErrorSelectCropMarket;
      });
      return;
    }

    final days = (int.tryParse(_daysController.text) ?? 7).clamp(1, 90);

    setState(() {
      _loadingPrediction = true;
      _predictionError = null;
      _prediction = null;
    });

    try {
      final prediction = await _apiService.fetchPrediction(
        cropId: crop.id,
        market: market,
        forecastDays: days,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _prediction = prediction;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _predictionError =
            '${AppLocalizations.of(context).predictionErrorFailed}: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingPrediction = false;
        });
      }
    }
  }

  String _locationMessage(AppLocalizations l10n) {
    if (_resolvingLocation) {
      return l10n.cropSelectionDetectingLocation;
    }

    if (_currentLocation != null) {
      return '${l10n.cropSelectionShowingMandisWithin} ${_selectedRadiusKm.round()} ${l10n.cropSelectionKm} ${l10n.cropSelectionOfCurrentLocation}';
    }

    final error = _locationErrorMessage?.trim();
    if (error != null && error.isNotEmpty) {
      return '${l10n.cropSelectionNearbyFilteringUnavailable}: $error';
    }

    return l10n.cropSelectionLocationPermissionHelp;
  }

  String _cropEmoji(CropModel crop) {
    final name = crop.name.toLowerCase();
    if (name.contains('wheat')) return '🌾';
    if (name.contains('rice')) return '🍚';
    if (name.contains('corn') || name.contains('maize')) return '🌽';
    if (name.contains('potato')) return '🥔';
    if (name.contains('onion')) return '🧅';
    if (name.contains('tomato')) return '🍅';
    if (name.contains('cotton')) return '🧵';
    if (name.contains('sugar')) return '🍬';
    return '🌱';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navDashboard),
        actions: [
          IconButton(
            onPressed: _reloadSelectionOptions,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.buttonRefresh,
          ),
        ],
      ),
      body: FutureBuilder<SelectionOptionsModel>(
        future: _selectionFuture,
        builder: (context, snapshot) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: snapshot.connectionState == ConnectionState.waiting
                  ? ListView(
                      key: const ValueKey('loading'),
                      children: const [
                        SizedBox(height: 220),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : snapshot.hasError
                      ? ListView(
                          key: const ValueKey('error'),
                          padding: const EdgeInsets.all(24),
                          children: [
                            const SizedBox(height: 140),
                            Text(
                              '${l10n.cropSelectionLoadingOptionsError}: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : () {
                          final options = snapshot.data;
                          if (options == null || options.crops.isEmpty) {
                            return ListView(
                              key: const ValueKey('empty'),
                              children: [
                                const SizedBox(height: 220),
                                Center(child: Text(l10n.cropSelectionNoCrops)),
                              ],
                            );
                          }

                          _selectedCrop ??= options.crops.first;
                          final crop = _selectedCrop!;
                          final markets = options.marketOptions[crop.id] ??
                              const <MarketOption>[];

                          final query =
                              _marketSearchController.text.trim().toLowerCase();
                          final filteredMarkets = query.isEmpty
                              ? markets
                              : markets.where((marketOption) {
                                  final pieces = <String>[
                                    marketOption.market,
                                    marketOption.district,
                                    marketOption.state,
                                  ]
                                      .where((part) => part.isNotEmpty)
                                      .join(' ')
                                      .toLowerCase();
                                  return pieces.contains(query);
                                }).toList();

                          return ListView(
                            key: const ValueKey('content'),
                            padding: const EdgeInsets.all(16),
                            children: [
                              Card(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 250),
                                          child: Text(
                                            _cropEmoji(crop),
                                            key: ValueKey(crop.id),
                                            style:
                                                const TextStyle(fontSize: 30),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l10n.cropSelectionHeroTitle,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                crop.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                l10n.cropSelectionHeroSubtitle,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.cropSelectionSelectCropTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        l10n.cropSelectionSelectCropSubtitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: options.crops.map((item) {
                                          final selected =
                                              _selectedCrop?.id == item.id;
                                          return ChoiceChip(
                                            label: Text(
                                                '${_cropEmoji(item)}  ${item.name}'),
                                            selected: selected,
                                            onSelected: (_) {
                                              setState(() {
                                                _selectedCrop = item;
                                                _selectedMarket = null;
                                                _typedMarketName = null;
                                                _prediction = null;
                                                _predictionError = null;
                                                _marketSearchController.clear();
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.cropSelectionChooseMarketTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _locationMessage(l10n),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${l10n.cropSelectionRadius}: ${_selectedRadiusKm.round()} ${l10n.cropSelectionKm}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _resolvingLocation
                                                ? null
                                                : _resolveLocation,
                                            child: Text(
                                              _resolvingLocation
                                                  ? l10n.cropSelectionLocating
                                                  : l10n
                                                      .cropSelectionUseMyLocation,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Slider(
                                        value: _selectedRadiusKm,
                                        min: _minRadiusKm,
                                        max: _maxRadiusKm,
                                        divisions:
                                            ((_maxRadiusKm - _minRadiusKm) / 25)
                                                .round(),
                                        label:
                                            '${_selectedRadiusKm.round()} ${l10n.cropSelectionKm}',
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedRadiusKm = value;
                                          });
                                        },
                                        onChangeEnd: (_) {
                                          if (_currentLocation != null) {
                                            _reloadSelectionOptions();
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _marketSearchController,
                                        decoration: InputDecoration(
                                          labelText: l10n
                                              .cropSelectionSearchMarketLabel,
                                          hintText: l10n
                                              .cropSelectionSearchMarketHint,
                                          prefixIcon: const Icon(Icons.search),
                                        ),
                                        onChanged: (_) {
                                          setState(() {
                                            final value =
                                                _marketSearchController.text
                                                    .trim();
                                            _typedMarketName =
                                                value.isEmpty ? null : value;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      if (markets.isEmpty)
                                        Text(
                                          l10n.cropSelectionNoMarketPrices,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        )
                                      else if (filteredMarkets.isEmpty)
                                        Text(
                                          '${l10n.cropSelectionNoMatchingMarketsPrefix} "${_marketSearchController.text.trim()}". ${l10n.cropSelectionNoMatchingMarketsSuffix}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        )
                                      else
                                        Column(
                                          children: filteredMarkets
                                              .map((marketOption) {
                                            final selected =
                                                _selectedMarket?.market ==
                                                    marketOption.market;
                                            final subtitlePieces = <String>[
                                              if (marketOption
                                                  .district.isNotEmpty)
                                                marketOption.district,
                                              if (marketOption.state.isNotEmpty)
                                                marketOption.state,
                                              if (marketOption.distanceKm !=
                                                  null)
                                                '${marketOption.distanceKm!.toStringAsFixed(1)} ${l10n.cropSelectionKmAway}',
                                              if (marketOption
                                                  .lastUpdated.isNotEmpty)
                                                '${l10n.cropSelectionLatestUpdate}: ${marketOption.lastUpdated}',
                                            ];
                                            return ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              title: Text(marketOption.market),
                                              subtitle: subtitlePieces.isEmpty
                                                  ? null
                                                  : Text(subtitlePieces
                                                      .join(' • ')),
                                              trailing: Text(
                                                Helpers.formatCurrency(
                                                    marketOption.currentPrice),
                                              ),
                                              selected: selected,
                                              onTap: () {
                                                setState(() {
                                                  _selectedMarket =
                                                      marketOption;
                                                  _typedMarketName = null;
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      if (_typedMarketName != null &&
                                          _typedMarketName!.trim().isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                            '${l10n.cropSelectionTypedMarket}: ${_typedMarketName!.trim()}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                    fontStyle:
                                                        FontStyle.italic),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.fieldForecastDays,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _daysController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: l10n.fieldForecastDays,
                                          helperText:
                                              l10n.cropSelectionForecastHelper,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton(
                                          onPressed: _loadingPrediction
                                              ? null
                                              : _loadPrediction,
                                          child: Text(
                                            _loadingPrediction
                                                ? l10n.cropSelectionPredicting
                                                : l10n
                                                    .cropSelectionGenerateForecast,
                                          ),
                                        ),
                                      ),
                                      if (_predictionError != null) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          _predictionError!,
                                          style: const TextStyle(
                                              color: Color(0xFFB42318)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                child: _prediction == null
                                    ? const SizedBox.shrink(
                                        key: ValueKey('no-prediction'))
                                    : Card(
                                        key: const ValueKey('prediction'),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${_prediction!.cropName} • ${_prediction!.market}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${l10n.labelCurrentPrice}: ${Helpers.formatCurrency(_prediction!.currentPrice)}',
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                _prediction!.recommendation,
                                              ),
                                              const SizedBox(height: 16),
                                              PriceChart(
                                                  points:
                                                      _prediction!.forecast),
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute<void>(
                                                        builder: (_) =>
                                                            BestSellScreen(
                                                                prediction:
                                                                    _prediction!),
                                                      ),
                                                    );
                                                  },
                                                  child: Text(l10n
                                                      .cropSelectionRecommendationDetails),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }(),
            ),
          );
        },
      ),
    );
  }
}
