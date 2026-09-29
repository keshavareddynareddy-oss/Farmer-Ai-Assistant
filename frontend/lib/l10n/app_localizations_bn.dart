// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'এগ্রিমাণ্ডি প্রাইস এআই';

  @override
  String get navDashboard => 'ড্যাশবোর্ড';

  @override
  String get navSoil => 'মাটি';

  @override
  String get navPrices => 'দাম';

  @override
  String get navAssistant => 'সহায়ক';

  @override
  String get navSettings => 'সেটিংস';

  @override
  String get labelLanguage => 'ভাষা';

  @override
  String get labelLanguageHelp => 'অ্যাপের ভাষা বাছুন (সহায়কের জন্যও).';

  @override
  String get buttonRetry => 'আবার চেষ্টা';

  @override
  String get buttonRefresh => 'রিফ্রেশ';

  @override
  String get buttonSend => 'পাঠান';

  @override
  String get buttonSending => 'পাঠানো হচ্ছে…';

  @override
  String get hintAskAssistant =>
      'ফসল, মান্ডি, পূর্বাভাস বা বিক্রির সেরা সময় জিজ্ঞেস করুন…';

  @override
  String get titleSettings => 'সেটিংস ও স্ট্যাটাস';

  @override
  String get titleBackendSnapshot => 'ব্যাকএন্ড স্ন্যাপশট';

  @override
  String get metricCropsTracked => 'ট্র্যাক করা ফসল';

  @override
  String get metricMarketsTracked => 'ট্র্যাক করা বাজার';

  @override
  String get metricLatestDatasetDate => 'সর্বশেষ ডেটাসেট তারিখ';

  @override
  String get metricBestCrop => 'সেরা ফসল';

  @override
  String get messageLocationConnected =>
      'লোকেশন সংযুক্ত। নিকটবর্তী মান্ডি ও আবহাওয়া ডেটা আপনার এলাকার ভিত্তিতে।';

  @override
  String get messageLocationUnavailable =>
      'লোকেশন পাওয়া যায়নি। সম্পূর্ণ বাজার তালিকা ও বিকল্প আবহাওয়া প্রসঙ্গ দেখানো হচ্ছে।';

  @override
  String get messageAssistantOffline =>
      'এখন ব্যাকএন্ড সহায়কের সাথে সংযোগ করা যাচ্ছে না।';

  @override
  String get homeNoTrendData => 'No trend data available.';

  @override
  String get cropSelectionTapToChoose => 'Tap to choose';

  @override
  String get homeBestCrop => 'Best crop';

  @override
  String get errorUnableFetchSoil => 'Unable to fetch soil recommendations';

  @override
  String get buttonGenerateForecast => 'Generate forecast';

  @override
  String get cropSelectionGenerateForecast => 'Generate forecast';

  @override
  String get homePriceTrendSubtitle =>
      'Latest average mandi prices for the strongest crops in the dataset.';

  @override
  String get labelCurrentPrice => 'Current price';

  @override
  String get fieldForecastDays => 'Forecast days';

  @override
  String get assistantTitle => 'Assistant';

  @override
  String get chatbotTitle => 'Farm assistant';

  @override
  String get cropSelectionSelectCropTitle => 'Select your crop';

  @override
  String get cropSelectionHeroPill1 => '1. Select crop';

  @override
  String get soilBackendResult => 'Backend recommendation result';

  @override
  String get homeTailoredDashboard =>
      'this dashboard is tailored for your farm.';

  @override
  String get chatbotEmpty => 'Start with a crop or mandi question.';

  @override
  String get assistantSubtitle =>
      'Chat messages are sent directly to the backend assistant service.';

  @override
  String get homeLatestDatasetDate => 'Latest dataset date';

  @override
  String get errorUnableFetchPrediction => 'Unable to fetch prediction';

  @override
  String get cropSelectionHeroPill2 => '2. Pick mandi';

  @override
  String get recommendationTitleBestSellTime => 'Best sell time';

  @override
  String get soilPotassium => 'Potassium (K)';

  @override
  String get cropSelectionSelected => 'Selected';

  @override
  String get cropSelectionDetectingLocation =>
      'Detecting your location for nearby mandis…';

  @override
  String get priceAdvisorTitle => 'Price advisor';

  @override
  String get assistantSuggestionCrops => 'Show available crops';

  @override
  String get cropSelectionChooseMarketTitle => 'Choose a mandi';

  @override
  String get chatbotError => 'Could not reach the assistant. Please try again.';

  @override
  String get chatbotHint => 'Type your question';

  @override
  String get labelBestDay => 'Best day';

  @override
  String get homeWeatherFallbackNote =>
      'Using fallback weather because live weather could not be reached.';

  @override
  String get homeWeatherLiveNote =>
      'Weather is linked to your current location context.';

  @override
  String get assistantInitialMessage =>
      'Ask me about crops, markets, price forecasts, or the best time to sell.';

  @override
  String get cropSelectionRadius => 'Radius';

  @override
  String get soilOrganicMatter => 'Organic matter (%)';

  @override
  String get cropSelectionRecommendationDetails =>
      'Open recommendation details';

  @override
  String get cropSelectionHeroTitle =>
      'Choose your crop, market, and selling window.';

  @override
  String get recommendationLabelExpectedPrice => 'Expected price';

  @override
  String get greetingHi => 'Hi';

  @override
  String get soilGetRecommendations => 'Get recommendations';

  @override
  String get homeSoilSubtitle =>
      'These recommendations are generated by the backend so the frontend stays aligned with the same crop list and logic.';

  @override
  String get homeWelcomeBack => 'Welcome back';

  @override
  String get cropSelectionPredicting => 'Predicting…';

  @override
  String get chartPriceForecastTitle => 'Price forecast';

  @override
  String get predictionFallbackNotice =>
      'A validated model is unavailable. This line repeats the current price as a reference; it is not a market forecast.';

  @override
  String get cropSelectionNoCrops => 'No crops available.';

  @override
  String get cropSelectionKm => 'km';

  @override
  String get cropSelectionTypedMarket => 'Typed mandi';

  @override
  String get cropSelectionKmAway => 'km away';

  @override
  String get recommendationLabelCrop => 'Crop';

  @override
  String get homePriceTrendTitle => 'Price trend';

  @override
  String get cropSelectionSelectCropSubtitle =>
      'Choose the crop you want to get price predictions for.';

  @override
  String get predictionErrorFailed => 'Prediction failed';

  @override
  String get cropSelectionNoMarketsInRadius =>
      'No mandis were found within the selected radius.';

  @override
  String get fieldCrop => 'Crop';

  @override
  String get homeSoilTitle => 'Soil recommendation';

  @override
  String get cropSelectionHeroSubtitle =>
      'Browse more crops, compare current prices across available markets, and forecast the best selling window.';

  @override
  String get buttonGenerating => 'Generating…';

  @override
  String get cropSelectionSearchMarketHint =>
      'Start typing a mandi name, district, or state';

  @override
  String get cropSelectionHeroPill3 => '3. View forecast';

  @override
  String get cropSelectionLoadingOptionsError => 'Unable to load options';

  @override
  String get assistantSuggestionMarkets => 'Markets for wheat';

  @override
  String get predictionButtonPredictPrice => 'Predict price';

  @override
  String get soilPh => 'pH level';

  @override
  String get recommendationLabelMarket => 'Mandi';

  @override
  String get soilNitrogen => 'Nitrogen (N)';

  @override
  String get assistantSuggestionBestTime => 'Best time to sell wheat in Delhi';

  @override
  String get cropSelectionForecastHelper => 'Choose a value from 1 to 90 days';

  @override
  String get soilMoisture => 'Moisture (%)';

  @override
  String get recommendationTitleRecommendedWindow => 'Recommended sale window';

  @override
  String get labelDay => 'Day';

  @override
  String get recommendationLabelTargetDay => 'Target day';

  @override
  String get chatbotSubtitle =>
      'Ask about crops, mandis, prices, and selling timing.';

  @override
  String get homeWeatherTitle => '5-day weather';

  @override
  String get cropSelectionNoMarketPrices =>
      'No market prices are available for this crop yet.';

  @override
  String get homeApproxLocation => 'Approx location';

  @override
  String get cropSelectionSearchMarketLabel => 'Search or type market';

  @override
  String get cropSelectionUseMyLocation => 'Use my location';

  @override
  String get cropSelectionNoMatchingMarketsPrefix => 'No matching mandis for';

  @override
  String get cropSelectionLocationPermissionHelp =>
      'Allow location access to show mandis near you.';

  @override
  String get cropSelectionLatestUpdate => 'Latest update';

  @override
  String get errorSelectCropMarket =>
      'Select a crop and market before generating a forecast.';

  @override
  String get soilSubmitting => 'Submitting…';

  @override
  String get predictionButtonViewRecommendation => 'View recommendation';

  @override
  String get buttonOpenRecommendationDetails => 'Open recommendation details';

  @override
  String get soilPhosphorus => 'Phosphorus (P)';

  @override
  String get cropSelectionLocating => 'Locating…';

  @override
  String get priceAdvisorSubtitle =>
      'This flow is fully backed by the API: crop selection, market selection, forecast generation, and recommendation details.';

  @override
  String get fieldMarket => 'Market';

  @override
  String get valueUnknown => 'Unknown';

  @override
  String get valueNA => 'N/A';

  @override
  String get cropSelectionErrorSelectCropMarket =>
      'Select a crop and either choose a mandi from the list or type the mandi name.';

  @override
  String get cropSelectionNearbyFilteringUnavailable =>
      'Nearby mandi filtering unavailable';

  @override
  String get cropSelectionLocationUnavailable => 'Location unavailable.';

  @override
  String get cropSelectionNoMatchingMarketsSuffix =>
      'You can still use this typed name when generating a forecast.';

  @override
  String get cropSelectionShowingMandisWithin => 'Showing mandis within';

  @override
  String get cropSelectionOfCurrentLocation => 'of your current location.';
}
