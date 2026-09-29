import 'package:flutter/material.dart';
import 'package:crop_price_predictor/l10n/app_localizations.dart';

import '../../core/utils/helpers.dart';
import '../../models/crop_model.dart';
import '../../models/prediction_model.dart';
import '../../services/api_service.dart';
import '../recommendation/best_sell_screen.dart';
import 'widgets/price_chart.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({
    super.key,
    required this.crop,
  });

  final CropModel crop;

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _daysController =
      TextEditingController(text: '7');

  Future<PredictionModel>? _predictionFuture;

  int _forecastDays() {
    return (int.tryParse(_daysController.text) ?? 7).clamp(1, 90);
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  void _loadPrediction() {
    final days = _forecastDays();
    setState(() {
      _predictionFuture = _apiService.fetchPrediction(
        cropId: widget.crop.id,
        market: widget.crop.market,
        forecastDays: days,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.crop.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _daysController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.fieldForecastDays,
              hintText: l10n.cropSelectionForecastHelper,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadPrediction,
            child: Text(l10n.predictionButtonPredictPrice),
          ),
          const SizedBox(height: 20),
          if (_predictionFuture != null)
            FutureBuilder<PredictionModel>(
              future: _predictionFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        '${l10n.predictionErrorFailed}: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final prediction = snapshot.data;
                if (prediction == null) {
                  return const SizedBox.shrink();
                }

                return Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: ConstrainedBox(
                      key: ValueKey(prediction),
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (prediction.market.isNotEmpty)
                                    Text(
                                      '${l10n.fieldMarket}: ${prediction.market}',
                                      textAlign: TextAlign.center,
                                    ),
                                  if (prediction.market.isNotEmpty)
                                    const SizedBox(height: 12),
                                  Text(
                                    '${l10n.labelCurrentPrice}: ${Helpers.formatCurrency(prediction.currentPrice)}',
                                    textAlign: TextAlign.center,
                                  ),
                                  if (prediction.modelVersion != null &&
                                      prediction.modelVersion!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Model: ${prediction.modelVersion}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Text(
                                    prediction.recommendation,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          PriceChart(points: prediction.forecast),
                          if (prediction.predictionSource ==
                              'fallback_estimate') ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.predictionFallbackNotice,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () async {
                              String? backendRecommendation;
                              try {
                                backendRecommendation = await _apiService
                                    .fetchBestSellRecommendation(
                                  cropId: widget.crop.id,
                                  market: prediction.market,
                                  forecastDays: _forecastDays(),
                                );
                              } catch (_) {
                                backendRecommendation = null;
                              }

                              if (!context.mounted) {
                                return;
                              }

                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => BestSellScreen(
                                    prediction: prediction,
                                    recommendationText: backendRecommendation,
                                  ),
                                ),
                              );
                            },
                            child:
                                Text(l10n.predictionButtonViewRecommendation),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
