import pandas as pd

PREDICTION_FEATURE_COLUMNS = (
    "month",
    "day_of_year",
    "price_lag_1",
    "price_rolling_mean_3",
)


def build_features(frame: pd.DataFrame) -> pd.DataFrame:
    engineered = frame.copy()
    series_columns = [column for column in ("crop_id", "market") if column in engineered.columns]

    if "date" in engineered.columns:
        engineered["date"] = pd.to_datetime(engineered["date"])
        engineered = engineered.sort_values([*series_columns, "date"], kind="stable")
        engineered["month"] = engineered["date"].dt.month
        engineered["day_of_year"] = engineered["date"].dt.dayofyear
    elif series_columns:
        engineered = engineered.sort_values(series_columns, kind="stable")

    if "price" in engineered.columns:
        if series_columns:
            grouped_prices = engineered.groupby(series_columns, sort=False, dropna=False)["price"]
            lagged_prices = grouped_prices.shift(1)
            engineered["price_lag_1"] = lagged_prices
            engineered["price_rolling_mean_3"] = grouped_prices.transform(
                lambda prices: prices.shift(1).rolling(3, min_periods=1).mean()
            )
        else:
            lagged_prices = engineered["price"].shift(1)
            engineered["price_lag_1"] = lagged_prices
            engineered["price_rolling_mean_3"] = lagged_prices.rolling(3, min_periods=1).mean()

    return engineered
