import unittest
from unittest.mock import patch

import pandas as pd
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.api.prediction_routes import router
from app.ml import predict
from app.services import prediction_service


class PredictionRouteTests(unittest.TestCase):
    def setUp(self):
        app = FastAPI()
        app.include_router(router, prefix="/api")
        self.client = TestClient(app)

    def test_predict_uses_latest_price_for_requested_crop_and_market(self):
        dataset = pd.DataFrame(
            {
                "crop_id": ["wheat", "rice", "wheat", "wheat"],
                "crop_name": ["Wheat", "Rice", "Wheat", "Wheat"],
                "market": ["Target Market", "Target Market", "Other Market", "Target Market"],
                "date": ["2026-09-28", "2026-09-30", "2026-09-29", "2026-09-25"],
                "price": [1250, 4100, 2800, 1100],
            }
        )

        with (
            patch.object(prediction_service, "load_dataset", return_value=dataset),
            patch.object(prediction_service, "_load_model", return_value=None),
            patch.object(predict, "_load_model", return_value=None),
        ):
            response = self.client.post(
                "/api/predict",
                json={"crop_id": "wheat", "market": "Target Market", "forecast_days": 2},
            )

        self.assertEqual(response.status_code, 200)
        result = response.json()
        self.assertEqual(result["crop_name"], "Wheat")
        self.assertEqual(result["market"], "Target Market")
        self.assertEqual(result["current_price"], 1250.0)
        self.assertEqual([item["price"] for item in result["forecast"]], [1250.0, 1250.0])

    def test_predict_returns_zero_fallback_when_crop_market_has_no_history(self):
        dataset = pd.DataFrame(
            {
                "crop_id": ["wheat", "rice"],
                "crop_name": ["Wheat", "Rice"],
                "market": ["Other Market", "Target Market"],
                "date": ["2026-09-28", "2026-09-29"],
                "price": [1250, 4100],
            }
        )

        with (
            patch.object(prediction_service, "load_dataset", return_value=dataset),
            patch.object(prediction_service, "_load_model", return_value=None),
            patch.object(predict, "_load_model", return_value=None),
        ):
            response = self.client.post(
                "/api/predict",
                json={"crop_id": "wheat", "market": "Target Market", "forecast_days": 2},
            )

        self.assertEqual(response.status_code, 200)
        result = response.json()
        self.assertEqual(result["current_price"], 0.0)
        self.assertEqual([item["price"] for item in result["forecast"]], [0.0, 0.0])


if __name__ == "__main__":
    unittest.main()