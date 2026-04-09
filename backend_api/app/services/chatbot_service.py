from __future__ import annotations

import re
from uuid import uuid4

from dotenv import load_dotenv

# Load environment variables from .env file before importing LLM service.
load_dotenv()

from app.services.data_service import get_selection_options
from app.services.prediction_service import generate_prediction
from app.services.llm_service import get_llm_response, is_llm_available

_LANGUAGE_ALIASES = {
    "en": "en",
    "as": "as",
    "bn": "bn",
    "brx": "brx",
    "doi": "doi",
    "gu": "gu",
    "hi": "hi",
    "kn": "kn",
    "ks": "ks",
    "kok": "kok",
    "mai": "mai",
    "ml": "ml",
    "mr": "mr",
    "ne": "ne",
    "or": "or",
    "pa": "pa",
    "sa": "sa",
    "sd": "sd",
    "ta": "ta",
    "te": "te",
    "ur": "ur",
    # Scripted language tags
    "mni-mtei": "mni-mtei",
    "mni_mtei": "mni-mtei",
    "sat-olck": "sat-olck",
    "sat_olck": "sat-olck",
    # Short forms (fallback)
    "mni": "mni-mtei",
    "sat": "sat-olck",
}

SUPPORTED_LANGUAGES = set(_LANGUAGE_ALIASES.values())
_LANGUAGE_NAMES = {
    "en": "English",
    "as": "Assamese",
    "bn": "Bengali",
    "brx": "Bodo",
    "doi": "Dogri",
    "gu": "Gujarati",
    "hi": "Hindi",
    "kn": "Kannada",
    "ks": "Kashmiri",
    "kok": "Konkani",
    "mai": "Maithili",
    "ml": "Malayalam",
    "mni-mtei": "Manipuri (Meitei)",
    "mr": "Marathi",
    "ne": "Nepali",
    "or": "Odia",
    "pa": "Punjabi",
    "sa": "Sanskrit",
    "sat-olck": "Santali",
    "sd": "Sindhi",
    "ta": "Tamil",
    "te": "Telugu",
    "ur": "Urdu",
}

_SESSIONS: dict[str, dict] = {}

_TEXT = {
    "en": {
        "welcome": "I can help with crops, mandis, price forecasts, and the best time to sell.",
        "help": "Ask me about available crops, markets for a crop, or the best selling time for wheat in Delhi.",
        "crops_intro": "Here are some crops I can help with",
        "more_crops": "and {count} more.",
        "ask_crop": "Tell me the crop name and I will list the available mandis.",
        "markets_intro": "Available mandis for {crop}",
        "market_line": "{market}: Rs {price:.2f} (updated {date})",
        "prediction_intro": "For {crop} in {market}, the current price is about Rs {current_price:.2f}.",
        "prediction_best": "The best selling window looks close to day {day} with an expected price near Rs {price:.2f}.",
        "fallback": "I can help you explore crops, mandis, and selling windows. Try asking about available crops or the best time to sell a crop.",
        "unknown_crop": "I could not match that crop yet. Try using the crop name shown in the app list.",
        "language_set": "I will continue in {language}.",
        "prompt_follow_up": "You can also ask for markets, forecasts, or selling recommendations.",
        "suggest_crops": "Show available crops",
        "suggest_markets": "Markets for wheat",
        "suggest_prediction": "Best time to sell wheat in Delhi",
        "greeting": "Hello! {welcome}",
    },
    "hi": {
        "welcome": "Main fasal, mandi, keemat ke andaze aur bechne ke sahi samay mein madad kar sakta hoon.",
        "help": "Aap mujhse uplabdh faslein, kisi fasal ki mandiyan, ya Delhi mein wheat bechne ka sahi samay pooch sakte hain.",
        "crops_intro": "Main in faslon mein madad kar sakta hoon",
        "more_crops": "aur {count} faslein bhi hain.",
        "ask_crop": "Fasal ka naam batayiye, main uplabdh mandiyan bata dunga.",
        "markets_intro": "{crop} ke liye uplabdh mandiyan",
        "market_line": "{market}: Rs {price:.2f} (update {date})",
        "prediction_intro": "{market} mein {crop} ki maujooda keemat lagbhag Rs {current_price:.2f} hai.",
        "prediction_best": "Bechne ka behtar samay lagbhag din {day} ke aas-paas dikh raha hai, jahan keemat kareeb Rs {price:.2f} ho sakti hai.",
        "fallback": "Main fasal, mandi aur bechne ki sahi window samjhane mein madad kar sakta hoon. Uplabdh faslein ya kisi fasal ki keemat poochkar shuru kariye.",
        "unknown_crop": "Main abhi us fasal ko pehchan nahi paaya. App mein dikh rahe fasal naam ka istemal karke poochhiye.",
        "language_set": "Main aage {language} mein jawab dunga.",
        "prompt_follow_up": "Aap mandi, purvanuman ya bechne ki salah bhi pooch sakte hain.",
        "suggest_crops": "Uplabdh faslein dikhao",
        "suggest_markets": "Wheat ki mandiyan",
        "suggest_prediction": "Delhi mein wheat bechne ka sahi samay",
        "greeting": "Namaste! {welcome}",
    },
    "ta": {
        "welcome": "Naan payirgal, sandhaigal, vilai munnarivippu matrum virkka sirandha neram patri uthavi seiya mudiyum.",
        "help": "Kidaikkum payirgal, oru payirukana sandhaigal, allathu Delhi-il wheat virkka nalla neram ponra kelvigalai kelungal.",
        "crops_intro": "Naan uthavi seiya koodiya sila payirgal",
        "more_crops": "melum {count} payirgal ullana.",
        "ask_crop": "Payir peyarai sollungal, atharku kidaikkum sandhaigalai kaattugiren.",
        "markets_intro": "{crop}kku kidaikkum sandhaigal",
        "market_line": "{market}: Rs {price:.2f} (update {date})",
        "prediction_intro": "{market} sandhaiyil {crop} in tharpoathaiya vilai sumar Rs {current_price:.2f}.",
        "prediction_best": "Sumaaraaga naal {day} arugil virkka nalla vaayppu ulladhu; appodhu vilai Rs {price:.2f} varai irukkalam.",
        "fallback": "Payirgal, sandhaigal, matrum virpanai neram patri naan uthavi seiya mudiyum. Kidaikkum payirgal allathu oru payirukana sandhaigal patri kelungal.",
        "unknown_crop": "Andha payirai naan innum porutham seiya mudiyavillai. App-il irukkum payir peyarai payanpaduthi paarungal.",
        "language_set": "Ini naan {language} mozhiyil pathilalippen.",
        "prompt_follow_up": "Sandhaigal, munnarivippu, allathu virpanai parindurai patriyum ketkalam.",
        "suggest_crops": "Kidaikkum payirgal",
        "suggest_markets": "Wheat sandhaigal",
        "suggest_prediction": "Delhi-il wheat virkka nalla neram",
        "greeting": "Vanakkam! {welcome}",
    },
    "te": {
        "welcome": "Nenu pantalu, mandilu, dhara anchanalu mariyu ammadaniki saraina samayam gurinchi sahayam cheyagalanu.",
        "help": "Andubaatulo unna pantalu, oka pantaku unna mandilu, leda Delhi lo wheat ammadaniki manchi samayam lanti prashnalu adagandi.",
        "crops_intro": "Nenu sahayam cheyagalige konni pantalu ivi",
        "more_crops": "inka {count} pantalu unnayi.",
        "ask_crop": "Panta peru cheppandi, andubaatulo unna mandilanu chebuta.",
        "markets_intro": "{crop} kosam andubaatulo unna mandilu",
        "market_line": "{market}: Rs {price:.2f} (update {date})",
        "prediction_intro": "{market} market-lo {crop} prastuta dhara sumaaru Rs {current_price:.2f}.",
        "prediction_best": "Ammadaniki manchi samayam daggara daggara day {day} vadda kanipistondi; appudu dhara Rs {price:.2f} varaku undochu.",
        "fallback": "Pantalu, mandilu, amme samayam gurinchi nenu sahayam cheyagalanu. Andubaatulo unna pantalu leda oka panta dhara gurinchi adigi prarambhinchandi.",
        "unknown_crop": "Aa pantanu nenu inka gurthinchalekapoyanu. App-lo kanipinche panta peruto adagandi.",
        "language_set": "Ika nundi nenu {language} lo samadhanam istanu.",
        "prompt_follow_up": "Mandilu, anchanalu, leda ammaka sifarasu gurinchi kooda adagavachu.",
        "suggest_crops": "Andubaatulo unna pantalu",
        "suggest_markets": "Wheat mandilu",
        "suggest_prediction": "Delhi lo wheat ammadaniki manchi samayam",
        "greeting": "Namaskaram! {welcome}",
    },
}


def _normalise(value: str) -> str:
    pieces: list[str] = []
    for ch in value.casefold():
        pieces.append(ch if ch.isalnum() else " ")
    return " ".join("".join(pieces).split())


def _get_text(language: str, key: str, **kwargs) -> str:
    template = _TEXT.get(language, _TEXT["en"]).get(key, "")
    return template.format(**kwargs)


def _normalise_language_tag(value: str | None) -> str | None:
    if not value:
        return None
    return value.strip().replace("_", "-").lower()

def _resolve_language(message: str, preferred_language: str | None) -> str:
    preferred = _normalise_language_tag(preferred_language)
    if preferred and preferred in _LANGUAGE_ALIASES:
        return _LANGUAGE_ALIASES[preferred]

    # Best-effort script detection.
    if re.search(r"[\u0A00-\u0A7F]", message):
        return "pa"  # Gurmukhi
    if re.search(r"[\u0A80-\u0AFF]", message):
        return "gu"  # Gujarati
    if re.search(r"[\u0980-\u09FF]", message):
        return "bn"  # Bengali/Assamese
    if re.search(r"[\u0900-\u097F]", message):
        return "hi"  # Devanagari (Hindi/Marathi/etc.)
    if re.search(r"[\u0B00-\u0B7F]", message):
        return "or"  # Odia
    if re.search(r"[\u0B80-\u0BFF]", message):
        return "ta"  # Tamil
    if re.search(r"[\u0C00-\u0C7F]", message):
        return "te"  # Telugu
    if re.search(r"[\u0C80-\u0CFF]", message):
        return "kn"  # Kannada
    if re.search(r"[\u0D00-\u0D7F]", message):
        return "ml"  # Malayalam
    if re.search(r"[\u0600-\u06FF]", message):
        return "ur"  # Arabic script (Urdu/Sindhi)
    if re.search(r"[\uABC0-\uABFF]", message):
        return "mni-mtei"  # Meitei Mayek
    if re.search(r"[\u1C50-\u1C7F]", message):
        return "sat-olck"  # Ol Chiki

    return "en"

def _find_crop(message: str, crops: list[dict]) -> dict | None:
    normalised_message = _normalise(message)
    for crop in crops:
        aliases = {_normalise(str(crop["id"])), _normalise(str(crop["name"]))}
        if any(alias and alias in normalised_message for alias in aliases):
            return crop
    return None


def _find_market(message: str, market_names: set[str]) -> str | None:
    normalised_message = _normalise(message)
    for market in sorted(market_names, key=len, reverse=True):
        if _normalise(market) in normalised_message:
            return market
    return None


def _extract_days(message: str) -> int:
    match = re.search(r"\b(\d{1,2})\b", message)
    if not match:
        return 7

    days = int(match.group(1))
    return max(1, min(days, 30))


def _contains_phrase(normalised_message: str, keywords: list[str]) -> bool:
    token_set = set(normalised_message.split())
    for keyword in keywords:
        normalised_keyword = _normalise(keyword)
        if not normalised_keyword:
            continue
        if " " in normalised_keyword:
            if normalised_keyword in normalised_message:
                return True
        elif normalised_keyword in token_set:
            return True
    return False


def _detect_intent(message: str) -> str:
    normalised_message = _normalise(message)
    intent_map = {
        "greeting": [
            "hi",
            "hello",
            "hey",
            "namaste",
            "vanakkam",
            "namaskaram",
        ],
        "help": [
            "help",
            "what can you do",
            "kaise",
            "uthavi",
            "sahayam",
            "madad",
        ],
        "crops": [
            "crop",
            "crops",
            "available",
            "fasal",
            "payir",
            "panta",
            "chasa",
            "phasal",
        ],
        "markets": ["market", "markets", "mandi", "bazar", "sandhai", "haat"],
        "prediction": [
            "price",
            "predict",
            "forecast",
            "sell",
            "best",
            "recommend",
            "keemat",
            "bech",
            "vilai",
            "virkka",
            "dhara",
            "amma",
        ],
    }

    for intent, keywords in intent_map.items():
        if _contains_phrase(normalised_message, keywords):
            return intent
    return "fallback"


def _build_suggestions(language: str) -> list[str]:
    return [
        _get_text(language, "suggest_crops"),
        _get_text(language, "suggest_markets"),
        _get_text(language, "suggest_prediction"),
    ]


def _reply_with_crops(language: str, crops: list[dict]) -> str:
    crop_names = [str(crop["name"]) for crop in crops[:8]]
    text = f"{_get_text(language, 'crops_intro')}: {', '.join(crop_names)}."
    remaining = len(crops) - len(crop_names)
    if remaining > 0:
        text = f"{text} {_get_text(language, 'more_crops', count=remaining)}"
    return text


def _reply_with_markets(language: str, crop: dict, market_options: list[dict]) -> str:
    if not market_options:
        return _get_text(language, "ask_crop")

    lines = [_get_text(language, "markets_intro", crop=crop["name"]) + ":"]
    for market in market_options[:5]:
        lines.append(
            _get_text(
                language,
                "market_line",
                market=market["market"],
                price=float(market.get("current_price", 0)),
                date=market.get("last_updated") or "-",
            )
        )
    return " ".join(lines)


def _reply_with_prediction(language: str, crop: dict, market: str, days: int) -> str:
    prediction = generate_prediction(
        crop_id=str(crop["id"]),
        market=market,
        forecast_days=days,
    )
    best_point = max(prediction["forecast"], key=lambda item: item["price"])
    intro = _get_text(
        language,
        "prediction_intro",
        crop=prediction["crop_name"],
        market=prediction["market"],
        current_price=float(prediction["current_price"]),
    )
    best = _get_text(
        language,
        "prediction_best",
        day=int(best_point["day"]),
        price=float(best_point["price"]),
    )
    return f"{intro} {best}"


def chat_with_assistant(
    message: str,
    session_id: str | None = None,
    language: str | None = None,
    context: dict | None = None,
) -> dict:
    resolved_language = _resolve_language(message, language)
    session_key = session_id or f"chat-{uuid4().hex[:12]}"
    session = _SESSIONS.setdefault(
        session_key,
        {
            "last_crop": None,
            "last_market": None,
            "last_language": resolved_language,
            "messages": [],
        },
    )

    selection_options = get_selection_options()
    crops = selection_options.get("crops", [])
    market_options_map = selection_options.get("market_options", {})
    market_names = {
        market["market"]
        for options in market_options_map.values()
        for market in options
        if market.get("market")
    }

    crop = _find_crop(message, crops)
    if not crop and context:
        context_crop_id = context.get("crop_id")
        crop = next((item for item in crops if item["id"] == context_crop_id), None)
    if not crop:
        crop = session.get("last_crop")

    market = _find_market(message, market_names)
    if not market and context:
        market = context.get("market")
    if not market:
        market = session.get("last_market")

    session["last_language"] = resolved_language
    if crop:
        session["last_crop"] = crop
    if market:
        session["last_market"] = market

    message_lower = message.lower().strip()
    intent = _detect_intent(message)

    confidence = "verified"

    if any(
        token in message_lower
        for token in [
            "language",
            "english",
            "hindi",
            "tamil",
            "telugu",
            "bengali",
            "assamese",
            "urdu",
            "marathi",
            "gujarati",
            "punjabi",
            "odia",
            "bodo",
            "dogri",
            "kashmiri",
            "konkani",
            "maithili",
            "malayalam",
            "manipuri",
            "meitei",
            "nepali",
            "sanskrit",
            "santali",
            "sindhi",
        ]
    ):
        reply = _get_text(
            resolved_language,
            "language_set",
            language=_LANGUAGE_NAMES.get(resolved_language, resolved_language),
        )
    elif intent == "greeting":
        reply = _get_text(
            resolved_language,
            "greeting",
            welcome=_get_text(resolved_language, "welcome"),
        )
    elif intent == "help":
        reply = f"{_get_text(resolved_language, 'welcome')} {_get_text(resolved_language, 'help')}"
    elif intent == "crops":
        reply = _reply_with_crops(resolved_language, crops)
    elif intent == "markets":
        if not crop:
            reply = _get_text(resolved_language, "ask_crop")
        else:
            reply = _reply_with_markets(
                resolved_language,
                crop,
                market_options_map.get(str(crop["id"]), []),
            )
    elif intent == "prediction":
        if not crop:
            reply = _get_text(resolved_language, "unknown_crop")
        else:
            if not market:
                crop_markets = market_options_map.get(str(crop["id"]), [])
                market = crop_markets[0]["market"] if crop_markets else ""
                session["last_market"] = market

            if market:
                reply = _reply_with_prediction(
                    resolved_language,
                    crop,
                    market,
                    _extract_days(message),
                )
            else:
                reply = _reply_with_markets(
                    resolved_language,
                    crop,
                    market_options_map.get(str(crop["id"]), []),
                )
    else:
        if is_llm_available() and crop and market:
            llm_result = get_llm_response(
                message=message,
                language=resolved_language,
                context={
                    **(context or {}),
                    "crop_name": str(crop["name"]),
                    "crop_id": str(crop["id"]),
                    "market": str(market),
                },
            )
            if llm_result.get("success") and llm_result.get("reply"):
                reply = str(llm_result.get("reply", "")).strip()
                suggestions = llm_result.get("suggestions", _build_suggestions(resolved_language))
                session["messages"].append({"role": "user", "content": message})
                session["messages"].append({"role": "assistant", "content": reply})
                return {
                    "session_id": session_key,
                    "language": resolved_language,
                    "reply": reply,
                    "suggestions": suggestions,
                    "confidence": "grounded",
                    "source": "llm",
                }

        confidence = "uncertain"
        reply = f"{_get_text(resolved_language, 'fallback')} {_get_text(resolved_language, 'prompt_follow_up')}"

    session["messages"].append({"role": "user", "content": message})
    session["messages"].append({"role": "assistant", "content": reply})

    return {
        "session_id": session_key,
        "language": resolved_language,
        "reply": reply,
        "suggestions": _build_suggestions(resolved_language),
        "confidence": confidence,
        "source": "rule-based",
    }
