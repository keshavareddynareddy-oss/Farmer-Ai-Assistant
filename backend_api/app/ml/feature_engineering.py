import pandas as pd


def build_features(frame: pd.DataFrame) -> pd.DataFrame:
    engineered = frame.copy()

    if "date" in engineered.columns:
        engineered["date"] = pd.to_datetime(engineered["date"])
        engineered["month"] = engineered["date"].dt.month
        engineered["day_of_year"] = engineered["date"].dt.dayofyear

    if "price" in engineered.columns:
        engineered["price_lag_1"] = engineered["price"].shift(1)
        engineered["price_rolling_mean_3"] = engineered["price"].rolling(3).mean()

    return engineered.fillna(method="bfill").fillna(0)
