from __future__ import annotations

from app.database.db import get_connection
from app.services.data_service import load_dataset


def _clean_username(username: str) -> str:
    return username.strip().lower()


def list_alerts(username: str) -> list[dict]:
    clean_username = _clean_username(username)
    if not clean_username:
        return []

    with get_connection() as connection:
        rows = connection.execute(
            """
            SELECT id, crop_id, crop_name, market, target_price, is_above, created_at
            FROM price_alerts
            WHERE username = ?
            ORDER BY datetime(created_at) DESC
            """,
            (clean_username,),
        ).fetchall()

    try:
        prices = load_dataset()
    except Exception:
        prices = None

    alerts = []
    for row in rows:
        crop_id = row["crop_id"] or ""
        market = row["market"] or ""
        current_price = None
        if prices is not None and not prices.empty:
            matches = prices
            if crop_id:
                matches = matches[matches["crop_id"] == crop_id]
            if market:
                matches = matches[matches["market"] == market]
            if not matches.empty:
                current_price = float(matches.sort_values("date").iloc[-1]["price"])

        target_price = float(row["target_price"])
        triggered = (
            current_price is not None
            and current_price >= target_price
            if bool(row["is_above"])
            else current_price is not None and current_price <= target_price
        )
        alerts.append(
            {
                "id": row["id"],
                "crop_id": crop_id,
                "crop_name": row["crop_name"],
                "market": market,
                "target_price": target_price,
                "is_above": bool(row["is_above"]),
                "current_price": current_price,
                "triggered": triggered,
                "created_at": row["created_at"],
            }
        )
    return alerts


def upsert_alert(
    *,
    username: str,
    alert_id: str,
    crop_id: str,
    crop_name: str,
    market: str,
    target_price: float,
    is_above: bool,
    created_at: str,
) -> dict:
    clean_username = _clean_username(username)
    if not clean_username:
        raise ValueError("Username is required")
    if not alert_id.strip():
        raise ValueError("Alert id is required")
    if not crop_name.strip():
        raise ValueError("Crop name is required")

    with get_connection() as connection:
        connection.execute(
            """
            INSERT INTO price_alerts(
                id, username, crop_id, crop_name, market, target_price, is_above, created_at, updated_at
            )
            VALUES(?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            ON CONFLICT(id) DO UPDATE SET
                username = excluded.username,
                crop_id = excluded.crop_id,
                crop_name = excluded.crop_name,
                market = excluded.market,
                target_price = excluded.target_price,
                is_above = excluded.is_above,
                created_at = excluded.created_at,
                updated_at = CURRENT_TIMESTAMP
            """,
            (
                alert_id.strip(),
                clean_username,
                crop_id.strip(),
                crop_name.strip(),
                market.strip(),
                float(target_price),
                1 if is_above else 0,
                created_at.strip(),
            ),
        )

    return {
        "id": alert_id.strip(),
        "crop_id": crop_id.strip(),
        "crop_name": crop_name.strip(),
        "market": market.strip(),
        "target_price": float(target_price),
        "is_above": bool(is_above),
        "created_at": created_at.strip(),
    }


def remove_alert(username: str, alert_id: str) -> bool:
    clean_username = _clean_username(username)
    clean_alert_id = alert_id.strip()
    if not clean_username or not clean_alert_id:
        return False

    with get_connection() as connection:
        cursor = connection.execute(
            "DELETE FROM price_alerts WHERE username = ? AND id = ?",
            (clean_username, clean_alert_id),
        )
        return cursor.rowcount > 0
