from pathlib import Path

import joblib
import pandas as pd
from sklearn.ensemble import RandomForestRegressor

from app.ml.feature_engineering import PREDICTION_FEATURE_COLUMNS, build_features
from app.services.data_service import load_dataset

MODEL_PATH = Path(__file__).resolve().parents[1] / "models" / "price_predictor.pkl"


def _prepare_training_rows(frame: pd.DataFrame) -> pd.DataFrame:
    if "price" not in frame.columns:
        raise ValueError("Dataset must contain a price column for training.")

    features = build_features(frame)
    missing_columns = [column for column in PREDICTION_FEATURE_COLUMNS if column not in features.columns]
    if missing_columns:
        raise ValueError(f"Training data is missing required features: {', '.join(missing_columns)}")

    training_rows = features.dropna(subset=list(PREDICTION_FEATURE_COLUMNS))
    if training_rows.empty:
        raise ValueError("Training data must contain prior prices for at least one observation.")
    return training_rows


def evaluate_model(frame: pd.DataFrame) -> dict[str, float | int]:
    if "date" not in frame.columns:
        raise ValueError("Dataset must contain dates for chronological evaluation.")

    features = build_features(frame)
    training_rows = _prepare_training_rows(frame)
    eligible_rows = features.loc[training_rows.index]
    series_columns = [column for column in ("crop_id", "market") if column in eligible_rows.columns]

    if series_columns:
        validation_rows = eligible_rows.groupby(
            series_columns,
            sort=False,
            dropna=False,
        ).tail(1)
        validation_indices = validation_rows.index
        fitting_rows = eligible_rows.loc[~eligible_rows.index.isin(validation_indices)]
    else:
        holdout_size = max(1, len(eligible_rows) // 5)
        validation_rows = eligible_rows.tail(holdout_size)
        fitting_rows = eligible_rows.iloc[:-holdout_size]

    if fitting_rows.empty or validation_rows.empty:
        raise ValueError("Chronological evaluation requires prior training and holdout observations.")

    model = RandomForestRegressor(n_estimators=100, random_state=42)
    model.fit(fitting_rows[list(PREDICTION_FEATURE_COLUMNS)], fitting_rows["price"])
    predictions = model.predict(validation_rows[list(PREDICTION_FEATURE_COLUMNS)])
    actual_prices = validation_rows["price"].to_numpy()
    baseline_prices = validation_rows["price_lag_1"].to_numpy()
    model_mae = sum(abs(actual - predicted) for actual, predicted in zip(actual_prices, predictions)) / len(
        actual_prices
    )
    persistence_mae = sum(
        abs(actual - baseline) for actual, baseline in zip(actual_prices, baseline_prices)
    ) / len(actual_prices)

    return {
        "observations": len(actual_prices),
        "model_mae": float(model_mae),
        "persistence_mae": float(persistence_mae),
    }


def train_and_save_model(
    frame: pd.DataFrame | None = None,
    evaluation: dict[str, float | int] | None = None,
) -> bool:
    if frame is None:
        frame = load_dataset()

    if evaluation is None:
        evaluation = evaluate_model(frame)
    if evaluation["model_mae"] >= evaluation["persistence_mae"]:
        return False

    training_rows = _prepare_training_rows(frame)

    model = RandomForestRegressor(n_estimators=100, random_state=42)
    model.fit(training_rows[list(PREDICTION_FEATURE_COLUMNS)], training_rows["price"])
    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump({"model": model, "evaluation": evaluation}, MODEL_PATH)
    return True


if __name__ == "__main__":
    dataset = load_dataset()
    evaluation = evaluate_model(dataset)
    print(
        f"Chronological holdout ({evaluation['observations']} observations): "
        f"model MAE={evaluation['model_mae']:.2f}; "
        f"persistence MAE={evaluation['persistence_mae']:.2f}"
    )
    saved = train_and_save_model(dataset, evaluation)
    if not saved:
        print("Model was not saved because it did not outperform the persistence baseline.")
