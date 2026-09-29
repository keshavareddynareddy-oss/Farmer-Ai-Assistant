import requests
import os
from dotenv import load_dotenv

load_dotenv()

OPENWEATHER_API_KEY = os.environ.get("OPENWEATHER_API_KEY", "").strip()
ALLOW_MOCK_WEATHER = os.environ.get("ALLOW_MOCK_WEATHER", "true").lower() in {
    "1",
    "true",
    "yes",
}
from typing import Dict, Any, Optional

class WeatherService:
    def __init__(self, api_key: str = "your_openweather_api_key"):
        self.api_key = api_key
        self.base_url = "https://api.openweathermap.org/data/2.5"

    def get_weather(self, latitude: float, longitude: float) -> Optional[Dict[str, Any]]:
        """Get current weather data for given coordinates."""
        try:
            url = f"{self.base_url}/weather"
            params = {
                "lat": latitude,
                "lon": longitude,
                "appid": self.api_key,
                "units": "metric"
            }
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            return {
                "temperature": data["main"]["temp"],
                "humidity": data["main"]["humidity"],
                "description": data["weather"][0]["description"],
                "wind_speed": data["wind"]["speed"],
                "rainfall": data.get("rain", {}).get("1h", 0),
                "pressure": data["main"]["pressure"]
            }
        except Exception as e:
            print(f"Error fetching weather: {e}")
            return None

    def get_forecast(self, latitude: float, longitude: float, days: int = 7) -> Optional[Dict[str, Any]]:
        """Get weather forecast for given coordinates."""
        try:
            url = f"{self.base_url}/forecast"
            params = {
                "lat": latitude,
                "lon": longitude,
                "appid": self.api_key,
                "units": "metric",
                "cnt": days * 8  # 8 forecasts per day
            }
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            forecast = []
            for item in data["list"][:days*8:8]:  # Every 8th item for daily
                forecast.append({
                    "date": item["dt_txt"].split(" ")[0],
                    "temp_min": item["main"]["temp_min"],
                    "temp_max": item["main"]["temp_max"],
                    "humidity": item["main"]["humidity"],
                    "description": item["weather"][0]["description"],
                    "rainfall": item.get("rain", {}).get("3h", 0)
                })
            return {"forecast": forecast}
        except Exception as e:
            print(f"Error fetching forecast: {e}")
            return None

# For demo purposes, return mock data if API key not set
def get_mock_weather(latitude: float, longitude: float) -> Dict[str, Any]:
    return {
        "temperature": 25.5,
        "humidity": 65,
        "description": "clear sky",
        "wind_speed": 3.2,
        "rainfall": 0,
        "pressure": 1013
    }

def get_mock_forecast(latitude: float, longitude: float, days: int = 7) -> Dict[str, Any]:
    import datetime
    forecast = []
    base_date = datetime.date.today()
    for i in range(days):
        date = base_date + datetime.timedelta(days=i)
        forecast.append({
            "date": str(date),
            "temp_min": 20 + i % 5,
            "temp_max": 30 + i % 5,
            "humidity": 60 + i % 20,
            "description": "partly cloudy",
            "rainfall": 0 if i % 3 != 0 else 2.5
        })
    return {"forecast": forecast}

weather_service = WeatherService(api_key=OPENWEATHER_API_KEY)

def get_current_weather(latitude: float, longitude: float) -> Optional[Dict[str, Any]]:
    if weather_service.api_key:
        return weather_service.get_weather(latitude, longitude)
    return get_mock_weather(latitude, longitude) if ALLOW_MOCK_WEATHER else None

def get_weather_forecast(latitude: float, longitude: float, days: int = 7) -> Optional[Dict[str, Any]]:
    if weather_service.api_key:
        return weather_service.get_forecast(latitude, longitude, days)
    return get_mock_forecast(latitude, longitude, days) if ALLOW_MOCK_WEATHER else None