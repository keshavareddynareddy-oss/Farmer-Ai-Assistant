import pandas as pd


def normalize_column_names(frame: pd.DataFrame) -> pd.DataFrame:
    renamed = frame.copy()
    renamed.columns = [column.strip().lower().replace(" ", "_") for column in frame.columns]
    return renamed
