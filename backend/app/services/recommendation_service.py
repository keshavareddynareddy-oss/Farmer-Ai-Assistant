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
    crop_name: str | None = None,
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

    crop_lower = (crop_name or "").strip().lower()
    crop_advice: list[str] = []
    if crop_lower:
        if "rice" in crop_lower or "paddy" in crop_lower:
            crop_advice.append("Rice and paddy crops usually need steadier moisture, so avoid letting the field dry for long.")
            if moisture < 40:
                crop_advice.append("Moisture looks low for rice, so irrigation should be checked soon.")
        elif "wheat" in crop_lower:
            crop_advice.append("Wheat generally responds well to balanced nutrition and moderate moisture, especially during active growth.")
            if ph < 6.2 or ph > 7.8:
                crop_advice.append("Wheat prefers a near-neutral pH, so soil pH may need attention.")
        elif "maize" in crop_lower or "corn" in crop_lower:
            crop_advice.append("Maize benefits from timely nitrogen support and enough moisture before tasseling.")
            if nitrogen < 35:
                crop_advice.append("Nitrogen looks a bit low for maize, so review top-dressing timing.")
        elif "cotton" in crop_lower:
            crop_advice.append("Cotton usually needs careful moisture balance and should not stay waterlogged.")
            if moisture > 60:
                crop_advice.append("Moisture looks high for cotton, so drainage and disease risk should be watched.")
        elif "tomato" in crop_lower or "potato" in crop_lower:
            crop_advice.append("Vegetable crops like tomato and potato benefit from steady moisture and strong disease monitoring.")
            if organic_matter < 2:
                crop_advice.append("Organic matter is low, so soil structure support may help these crops.")
        elif "soy" in crop_lower:
            crop_advice.append("Soybean usually benefits from well-drained soil and balanced phosphorus support.")
            if phosphorus < 25:
                crop_advice.append("Phosphorus looks low for soybean, so nutrient planning may be useful.")

    return {
        "recommendations": recommendations,
        "summary": summary,
        "crop_advice": crop_advice,
        "crop_name": crop_name or "",
        "soil_snapshot": {
            "ph": ph,
            "nitrogen": nitrogen,
            "phosphorus": phosphorus,
            "potassium": potassium,
            "moisture": moisture,
            "organic_matter": organic_matter,
        },
    }
