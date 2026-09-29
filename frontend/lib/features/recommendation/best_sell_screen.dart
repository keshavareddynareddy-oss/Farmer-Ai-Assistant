import 'package:flutter/material.dart';
import 'package:crop_price_predictor/l10n/app_localizations.dart';

import '../../core/utils/helpers.dart';
import '../../models/prediction_model.dart';

class BestSellScreen extends StatelessWidget {
  const BestSellScreen({
    super.key,
    required this.prediction,
    this.recommendationText,
  });

  final PredictionModel prediction;
  final String? recommendationText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bestPoint = prediction.forecast.reduce(
      (current, next) => next.price > current.price ? next : current,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recommendationTitleBestSellTime)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      l10n.recommendationTitleRecommendedWindow,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${l10n.recommendationLabelCrop}: ${prediction.cropName}',
                      textAlign: TextAlign.center,
                    ),
                    if (prediction.market.isNotEmpty)
                      Text(
                        '${l10n.recommendationLabelMarket}: ${prediction.market}',
                        textAlign: TextAlign.center,
                      ),
                    Text(
                      '${l10n.recommendationLabelTargetDay}: ${l10n.labelDay} ${bestPoint.day}',
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${l10n.recommendationLabelExpectedPrice}: ${Helpers.formatCurrency(bestPoint.price)}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      (recommendationText != null &&
                              recommendationText!.trim().isNotEmpty)
                          ? recommendationText!
                          : prediction.recommendation,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
