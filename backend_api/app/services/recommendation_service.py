from app.services.data_service import get_selection_options


def best_sell_recommendation(forecast: list[dict]) -> str:
    if not forecast:
        return "Not enough data to make a recommendation."

    best_point = max(forecast, key=lambda item: item["price"])
    return (
        f"Best selling window is around day {best_point['day']} "
        f"with an expected price of Rs {best_point['price']:.2f}."
    )


def recommend_crops_for_soil(
    ph: float,
    nitrogen: float,
    phosphorus: float,
    potassium: float,
    moisture: float,
    organic_matter: float,
) -> dict:
    options = get_selection_options()
    crop_names = [str(crop["name"]) for crop in options.get("crops", [])]
    if not crop_names:
        crop_names = ["Wheat", "Rice", "Maize", "Soybean", "Cotton", "Sugarcane"]

    scored: list[tuple[str, float]] = []
    for name in crop_names:
        lower = name.lower()
        score = 0.0
        if 6 <= ph <= 7.5 and ("wheat" in lower or "maize" in lower):
            score += 3.0
        if moisture >= 40 and "rice" in lower:
            score += 4.0
        if organic_matter >= 2 and ("tomato" in lower or "potato" in lower):
            score += 3.0
        if potassium >= 180 and "sugar" in lower:
            score += 2.5
        if nitrogen >= 35 and ("cotton" in lower or "maize" in lower or "wheat" in lower):
            score += 1.2
        if phosphorus >= 25 and ("rice" in lower or "soy" in lower or "tomato" in lower):
            score += 1.0
        score += max(0.0, 1.2 - abs(ph - 6.8) * 0.4)
        scored.append((name, score))

    scored.sort(key=lambda item: item[1], reverse=True)
    recommendations = [name for name, _ in scored[:4]]
    summary = (
        f"Soil pH {ph:.1f}, moisture {moisture:.0f}%, nitrogen {nitrogen:.0f}, "
        f"phosphorus {phosphorus:.0f}, potassium {potassium:.0f}, organic matter {organic_matter:.1f}%"
    )
    return {
        "recommendations": recommendations,
        "summary": summary,
        "soil_snapshot": {
            "ph": ph,
            "nitrogen": nitrogen,
            "phosphorus": phosphorus,
            "potassium": potassium,
            "moisture": moisture,
            "organic_matter": organic_matter,
        },
    }
