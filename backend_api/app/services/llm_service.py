"""
LLM-based agriculture chatbot service using Google Gemini API.
Provides intelligent responses to farmer queries about crops, markets, and farming practices.
"""

import json
import os

from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()

# Initialize Google Gemini client
gemini_api_key = os.getenv("GOOGLE_GEMINI_API_KEY", "")
gemini_model = os.getenv("GEMINI_MODEL", "models/gemini-2.0-flash")
if gemini_api_key:
    _client = genai.Client(api_key=gemini_api_key)
else:
    _client = None


def _resolve_model_name(raw_model: str) -> str:
    model_name = (raw_model or "").strip()
    if model_name.startswith("models/"):
        return model_name.split("/", 1)[1]
    return model_name or "gemini-2.0-flash"

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

_LANGUAGE_ALIASES = {
    "mni": "mni-mtei",
    "mni-mtei": "mni-mtei",
    "mni_mtei": "mni-mtei",
    "sat": "sat-olck",
    "sat-olck": "sat-olck",
    "sat_olck": "sat-olck",
}

AGRICULTURE_SYSTEM_PROMPT = """You are an expert agricultural consultant helping Indian farmers. 
Your expertise includes:
- Crop selection and seasonal planning
- Soil health and nutrient management
- Pest and disease prevention
- Optimal selling times for maximum profit
- Market price trends and predictions
- Weather impact on crop yields
- Sustainable farming practices

Guidelines:
- Be concise and practical (max 250 words)
- Provide actionable advice
- Consider regional farming contexts
- Mention specific crops when relevant
- Always prioritize farmer profitability
- Be encouraging and supportive
- If you lack specific data, suggest using the app's price predictor feature
- Do not invent facts, prices, dates, weather, or market outcomes.
- If the provided context is insufficient, say that you cannot confirm the answer.
- Prefer short, direct answers grounded in the supplied crop, market, weather, or soil context.

Respond in the target language specified for the conversation. If the target language is one of the supported Indian languages, keep the response entirely in that language and script.

Return a strict JSON object with this shape:
{"reply": string, "suggestions": [string, string, string]}

Do not wrap the JSON in markdown fences or add any extra text outside the JSON object."""


def _normalise_language_tag(value: str | None) -> str:
    if not value:
        return "en"

    tag = value.strip().replace("_", "-").lower()
    return _LANGUAGE_ALIASES.get(tag, tag)


def _parse_structured_response(text: str) -> tuple[str, list[str]]:
    stripped = text.strip()
    if not stripped.startswith("{"):
        return stripped, []

    try:
        payload = json.loads(stripped)
    except json.JSONDecodeError:
        return stripped, []

    reply = str(payload.get("reply", "")).strip()
    suggestions = payload.get("suggestions", [])
    if not isinstance(suggestions, list):
        suggestions = []

    cleaned_suggestions = [str(item).strip() for item in suggestions if str(item).strip()]
    return reply or stripped, cleaned_suggestions[:3]


def get_llm_response(
    message: str,
    language: str = "en",
    context: dict | None = None,
) -> dict:
    """
    Get agriculture-focused response from Google Gemini API.
    
    Args:
        message: User question or statement
        language: Language code (en, hi, ta, etc.)
        context: Additional context like crop_name, market, etc.
    
    Returns:
        {
            "reply": str,           # Assistant's response
            "suggestions": list[str], # Follow-up suggestions
            "success": bool,        # Whether call succeeded
        }
    """
    
    if _client is None:
        return _create_error_response(
            "LLM service not configured. Please set GOOGLE_GEMINI_API_KEY environment variable."
        )

    resolved_language = _normalise_language_tag(language)
    language_name = _LANGUAGE_NAMES.get(resolved_language, _LANGUAGE_NAMES["en"])
    
    # Build enriched prompt with context
    enriched_message = _build_enriched_message(message, context)
    full_prompt = (
        f"{AGRICULTURE_SYSTEM_PROMPT}\n\n"
        f"Target language: {language_name} ({resolved_language})\n"
        f"User: {enriched_message}"
    )
    
    try:
        response = _client.models.generate_content(
            model=_resolve_model_name(gemini_model),
            contents=full_prompt,
            config=types.GenerateContentConfig(
                temperature=0.2,
                max_output_tokens=300,
            ),
        )
        
        response_text = getattr(response, "text", "") or ""
        reply, suggestions = _parse_structured_response(response_text)
        if not reply:
            reply = response_text
        if not suggestions:
            suggestions = _generate_suggestions(language, context)
        
        return {
            "reply": reply,
            "suggestions": suggestions,
            "success": True,
        }
    
    except Exception as e:
        error_msg = f"Unexpected error: {str(e)}"
        return _create_error_response(error_msg)


def _build_enriched_message(message: str, context: dict | None) -> str:
    """Add context to the user's message for better responses."""
    
    if not context:
        return message
    
    context_lines = []
    
    crop = context.get("crop_name", "").strip()
    if crop:
        context_lines.append(f"Crop: {crop}")
    
    market = context.get("market", "").strip()
    if market:
        context_lines.append(f"Market/Region: {market}")
    
    topic = context.get("topic", "").strip()
    if topic:
        topic_map = {
            "pest-control": "pest and disease management",
            "soil-health": "soil health and nutrient management",
            "sell-timing": "best time to sell crops for profit",
        }
        topic_name = topic_map.get(topic, topic)
        context_lines.append(f"Topic: {topic_name}")
    
    if context_lines:
        context_prefix = "Context: " + " | ".join(context_lines) + "\n\n"
        return context_prefix + message
    
    return message


def _generate_suggestions(language: str, context: dict | None) -> list[str]:
    """Generate contextual follow-up suggestions."""
    resolved_language = _normalise_language_tag(language)
    suggestions_map = {
        "en": {
            "default": ["Tell me more", "Market prices", "Seasonal advice"],
            "pest": ["Prevention methods", "Organic solutions", "Market impact"],
            "soil": ["Nutrient balance", "Water management", "Crop rotation"],
            "sell": ["Price trends", "Market locations", "Storage tips"],
        },
        "hi": {
            "default": ["और बताइए", "बाजार भाव", "मौसमी सलाह"],
            "pest": ["रोकथाम विधियाँ", "जैविक समाधान", "बाजार प्रभाव"],
            "soil": ["पोषक संतुलन", "जल प्रबंधन", "फसल चक्र"],
            "sell": ["मूल्य प्रवृत्तियाँ", "बाजार स्थान", "भंडारण सुझाव"],
        },
        "ta": {
            "default": ["மேலும் சொல்ல", "விலை தகவல்", "பருவ ஆலோசனை"],
            "pest": ["தடுப்பு முறைகள்", "இயற்கை தீர்வுகள்", "சந்தை தாக்கம்"],
            "soil": ["ஊட்டச்சத்து சமநிலை", "நீர் வளiran்", "பயிர் சுழற்சி"],
            "sell": ["விலை போக்கு", "சந்தை இருப்பிடங்கள்", "சேமிப்பு குறிப்புகள்"],
        },
    }
    
    lang_sugg = suggestions_map.get(resolved_language, suggestions_map["en"])
    topic = context.get("topic", "") if context else ""
    
    if topic in lang_sugg:
        return lang_sugg[topic]
    
    return lang_sugg.get("default", ["Tell me more", "Next steps", "More help"])


def _create_error_response(error_message: str) -> dict:
    """Create a standardized error response."""
    return {
        "reply": error_message,
        "suggestions": ["Try another question", "Check connection", "Go back"],
        "success": False,
    }


def is_llm_available() -> bool:
    """Check if LLM service is properly configured."""
    return _client is not None
