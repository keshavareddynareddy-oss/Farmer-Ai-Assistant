from pathlib import Path

import joblib
from sklearn.ensemble import RandomForestRegressor

from app.ml.feature_engineering import build_features
from app.services.data_service import load_dataset

MODEL_PATH = Path(__file__).resolve().parents[1] / "models" / "price_predictor.pkl"


def train_and_save_model() -> None:
    frame = load_dataset()
    if "price" not in frame.columns:
        raise ValueError("Dataset must contain a price column for training.")

    features = build_features(frame)
    numeric_columns = [
        column
        for column in features.select_dtypes(include=["number"]).columns
        if column != "price"
    ]

    if not numeric_columns:
        raise ValueError("No numeric feature columns are available for training.")

    model = RandomForestRegressor(n_estimators=100, random_state=42)
    model.fit(features[numeric_columns], features["price"])
    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, MODEL_PATH)


if __name__ == "__main__":
    train_and_save_model()
