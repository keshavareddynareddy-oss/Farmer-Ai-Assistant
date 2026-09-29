import math
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import pandas as pd

from app.ml import predict, train_model
from app.ml.feature_engineering import build_features


class PredictionModelTests(unittest.TestCase):
    def test_lag_and_rolling_features_are_sorted_and_grouped_by_market(self):
        history = pd.DataFrame(
            {
                "crop_id": ["wheat", "rice", "wheat", "rice", "wheat", "rice"],
                "market": ["Delhi", "Patna", "Delhi", "Patna", "Delhi", "Patna"],
                "date": ["2025-01-01", "2025-01-01", "2025-01-03", "2025-01-03", "2025-01-02", "2025-01-02"],
                "price": [10, 100, 30, 300, 20, 200],
            }
        )

        features = build_features(history)
        wheat_middle = features.loc[features["price"] == 20].iloc[0]
        rice_middle = features.loc[features["price"] == 200].iloc[0]

        self.assertEqual(wheat_middle["price_lag_1"], 10)
        self.assertEqual(rice_middle["price_lag_1"], 100)
        self.assertEqual(wheat_middle["price_rolling_mean_3"], 10)
        self.assertEqual(rice_middle["price_rolling_mean_3"], 100)

        wheat_latest = features.loc[features["price"] == 30].iloc[0]
        rice_latest = features.loc[features["price"] == 300].iloc[0]
        self.assertEqual(wheat_latest["price_rolling_mean_3"], 15)
        self.assertEqual(rice_latest["price_rolling_mean_3"], 150)

    def test_trained_model_forecasts_when_training_data_has_market_metadata(self):
        training_data = pd.DataFrame(
            {
                "date": pd.date_range("2025-01-01", periods=6, freq="7D"),
                "price": [2400, 2420, 2410, 2450, 2470, 2460],
                "latitude": [28.6, 28.6, 28.6, 26.8, 26.8, 26.8],
                "longitude": [77.2, 77.2, 77.2, 80.9, 80.9, 80.9],
            }
        )

        with tempfile.TemporaryDirectory() as temporary_directory:
            model_path = Path(temporary_directory) / "price_predictor.pkl"
            with (
                patch.object(train_model, "load_dataset", return_value=training_data),
                patch.object(train_model, "MODEL_PATH", model_path),
                patch.object(
                    train_model,
                    "evaluate_model",
                    return_value={"observations": 1, "model_mae": 1.0, "persistence_mae": 2.0},
                ),
            ):
                saved = train_model.train_and_save_model()

            with (
                patch.object(predict, "MODEL_PATH", model_path),
                patch.object(predict, "_MODEL", None),
            ):
                forecast = predict.forecast_prices("wheat", 2460, 7)

        self.assertTrue(saved)
        self.assertEqual(len(forecast), 7)
        self.assertTrue(all(math.isfinite(item["price"]) for item in forecast))

    def test_model_is_not_saved_when_it_does_not_beat_persistence(self):
        training_data = pd.DataFrame(
            {
                "date": pd.date_range("2025-01-01", periods=6, freq="7D"),
                "price": [2400, 2420, 2410, 2450, 2470, 2460],
            }
        )

        with tempfile.TemporaryDirectory() as temporary_directory:
            model_path = Path(temporary_directory) / "price_predictor.pkl"
            with (
                patch.object(train_model, "load_dataset", return_value=training_data),
                patch.object(train_model, "MODEL_PATH", model_path),
                patch.object(
                    train_model,
                    "evaluate_model",
                    return_value={"observations": 1, "model_mae": 10.0, "persistence_mae": 5.0},
                ),
            ):
                saved = train_model.train_and_save_model()

            self.assertFalse(saved)
            self.assertFalse(model_path.exists())

    def test_unvalidated_artifact_uses_flat_persistence_fallback(self):
        fallback = predict._fallback_forecast("wheat", 2450, 3)
        missing_price_fallback = predict._fallback_forecast("wheat", 0, 2)

        self.assertEqual([item["price"] for item in fallback], [2450, 2450, 2450])
        self.assertEqual([item["price"] for item in missing_price_fallback], [0, 0])

    def test_missing_current_price_does_not_use_trained_model(self):
        model = unittest.mock.Mock()

        with patch.object(predict, "_load_model", return_value=model):
            forecast = predict.forecast_prices("wheat", 0, 2)

        self.assertEqual([item["price"] for item in forecast], [0, 0])
        model.predict.assert_not_called()

    def test_evaluation_holds_out_latest_observation_for_each_market(self):
        history = pd.DataFrame(
            {
                "crop_id": ["wheat", "rice", "wheat", "rice", "wheat", "rice"],
                "market": ["Delhi", "Patna", "Delhi", "Patna", "Delhi", "Patna"],
                "date": ["2025-01-01", "2025-01-01", "2025-01-03", "2025-01-03", "2025-01-02", "2025-01-02"],
                "price": [10, 100, 30, 300, 20, 200],
            }
        )

        evaluation = train_model.evaluate_model(history)

        self.assertEqual(evaluation["observations"], 2)
        self.assertTrue(math.isfinite(evaluation["model_mae"]))
        self.assertEqual(evaluation["persistence_mae"], 55)


if __name__ == "__main__":
    unittest.main()