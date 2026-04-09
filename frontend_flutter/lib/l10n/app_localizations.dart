import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_as.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_brx.dart';
import 'app_localizations_doi.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_kok.dart';
import 'app_localizations_ks.dart';
import 'app_localizations_mai.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mni.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_sa.dart';
import 'app_localizations_sat.dart';
import 'app_localizations_sd.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('bn'),
    Locale('te'),
    Locale('ta'),
    Locale('as'),
    Locale('brx'),
    Locale('doi'),
    Locale('gu'),
    Locale('kn'),
    Locale('kok'),
    Locale('ks'),
    Locale('mai'),
    Locale('ml'),
    Locale('mni'),
    Locale.fromSubtags(languageCode: 'mni', scriptCode: 'Mtei'),
    Locale('mr'),
    Locale('ne'),
    Locale('or'),
    Locale('pa'),
    Locale('sa'),
    Locale('sat'),
    Locale.fromSubtags(languageCode: 'sat', scriptCode: 'Olck'),
    Locale('sd'),
    Locale('ur')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AgriMandi Price AI'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navSoil.
  ///
  /// In en, this message translates to:
  /// **'Soil'**
  String get navSoil;

  /// No description provided for @navPrices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get navPrices;

  /// No description provided for @navAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get navAssistant;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @labelLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get labelLanguage;

  /// No description provided for @labelLanguageHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose your app language (used for the assistant too).'**
  String get labelLanguageHelp;

  /// No description provided for @buttonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get buttonRetry;

  /// No description provided for @buttonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get buttonRefresh;

  /// No description provided for @buttonSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get buttonSend;

  /// No description provided for @buttonSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get buttonSending;

  /// No description provided for @hintAskAssistant.
  ///
  /// In en, this message translates to:
  /// **'Ask about crops, mandis, forecasts, or best time to sell…'**
  String get hintAskAssistant;

  /// No description provided for @titleSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings & status'**
  String get titleSettings;

  /// No description provided for @titleBackendSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Backend snapshot'**
  String get titleBackendSnapshot;

  /// No description provided for @metricCropsTracked.
  ///
  /// In en, this message translates to:
  /// **'Crops tracked'**
  String get metricCropsTracked;

  /// No description provided for @metricMarketsTracked.
  ///
  /// In en, this message translates to:
  /// **'Markets tracked'**
  String get metricMarketsTracked;

  /// No description provided for @metricLatestDatasetDate.
  ///
  /// In en, this message translates to:
  /// **'Latest dataset date'**
  String get metricLatestDatasetDate;

  /// No description provided for @metricBestCrop.
  ///
  /// In en, this message translates to:
  /// **'Best crop'**
  String get metricBestCrop;

  /// No description provided for @messageLocationConnected.
  ///
  /// In en, this message translates to:
  /// **'Location connected. Nearby mandi and weather data use your current area.'**
  String get messageLocationConnected;

  /// No description provided for @messageLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable. Showing full market list and fallback weather context.'**
  String get messageLocationUnavailable;

  /// No description provided for @messageAssistantOffline.
  ///
  /// In en, this message translates to:
  /// **'I could not reach the backend assistant right now.'**
  String get messageAssistantOffline;

  /// No description provided for @homeNoTrendData.
  ///
  /// In en, this message translates to:
  /// **'No trend data available.'**
  String get homeNoTrendData;

  /// No description provided for @cropSelectionTapToChoose.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose'**
  String get cropSelectionTapToChoose;

  /// No description provided for @homeBestCrop.
  ///
  /// In en, this message translates to:
  /// **'Best crop'**
  String get homeBestCrop;

  /// No description provided for @errorUnableFetchSoil.
  ///
  /// In en, this message translates to:
  /// **'Unable to fetch soil recommendations'**
  String get errorUnableFetchSoil;

  /// No description provided for @buttonGenerateForecast.
  ///
  /// In en, this message translates to:
  /// **'Generate forecast'**
  String get buttonGenerateForecast;

  /// No description provided for @cropSelectionGenerateForecast.
  ///
  /// In en, this message translates to:
  /// **'Generate forecast'**
  String get cropSelectionGenerateForecast;

  /// No description provided for @homePriceTrendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Latest average mandi prices for the strongest crops in the dataset.'**
  String get homePriceTrendSubtitle;

  /// No description provided for @labelCurrentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current price'**
  String get labelCurrentPrice;

  /// No description provided for @fieldForecastDays.
  ///
  /// In en, this message translates to:
  /// **'Forecast days'**
  String get fieldForecastDays;

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get assistantTitle;

  /// No description provided for @chatbotTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm assistant'**
  String get chatbotTitle;

  /// No description provided for @cropSelectionSelectCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Select your crop'**
  String get cropSelectionSelectCropTitle;

  /// No description provided for @cropSelectionHeroPill1.
  ///
  /// In en, this message translates to:
  /// **'1. Select crop'**
  String get cropSelectionHeroPill1;

  /// No description provided for @soilBackendResult.
  ///
  /// In en, this message translates to:
  /// **'Backend recommendation result'**
  String get soilBackendResult;

  /// No description provided for @homeTailoredDashboard.
  ///
  /// In en, this message translates to:
  /// **'this dashboard is tailored for your farm.'**
  String get homeTailoredDashboard;

  /// No description provided for @chatbotEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start with a crop or mandi question.'**
  String get chatbotEmpty;

  /// No description provided for @assistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat messages are sent directly to the backend assistant service.'**
  String get assistantSubtitle;

  /// No description provided for @homeLatestDatasetDate.
  ///
  /// In en, this message translates to:
  /// **'Latest dataset date'**
  String get homeLatestDatasetDate;

  /// No description provided for @errorUnableFetchPrediction.
  ///
  /// In en, this message translates to:
  /// **'Unable to fetch prediction'**
  String get errorUnableFetchPrediction;

  /// No description provided for @cropSelectionHeroPill2.
  ///
  /// In en, this message translates to:
  /// **'2. Pick mandi'**
  String get cropSelectionHeroPill2;

  /// No description provided for @recommendationTitleBestSellTime.
  ///
  /// In en, this message translates to:
  /// **'Best sell time'**
  String get recommendationTitleBestSellTime;

  /// No description provided for @soilPotassium.
  ///
  /// In en, this message translates to:
  /// **'Potassium (K)'**
  String get soilPotassium;

  /// No description provided for @cropSelectionSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get cropSelectionSelected;

  /// No description provided for @cropSelectionDetectingLocation.
  ///
  /// In en, this message translates to:
  /// **'Detecting your location for nearby mandis…'**
  String get cropSelectionDetectingLocation;

  /// No description provided for @priceAdvisorTitle.
  ///
  /// In en, this message translates to:
  /// **'Price advisor'**
  String get priceAdvisorTitle;

  /// No description provided for @assistantSuggestionCrops.
  ///
  /// In en, this message translates to:
  /// **'Show available crops'**
  String get assistantSuggestionCrops;

  /// No description provided for @cropSelectionChooseMarketTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a mandi'**
  String get cropSelectionChooseMarketTitle;

  /// No description provided for @chatbotError.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the assistant. Please try again.'**
  String get chatbotError;

  /// No description provided for @chatbotHint.
  ///
  /// In en, this message translates to:
  /// **'Type your question'**
  String get chatbotHint;

  /// No description provided for @labelBestDay.
  ///
  /// In en, this message translates to:
  /// **'Best day'**
  String get labelBestDay;

  /// No description provided for @homeWeatherFallbackNote.
  ///
  /// In en, this message translates to:
  /// **'Using fallback weather because live weather could not be reached.'**
  String get homeWeatherFallbackNote;

  /// No description provided for @homeWeatherLiveNote.
  ///
  /// In en, this message translates to:
  /// **'Weather is linked to your current location context.'**
  String get homeWeatherLiveNote;

  /// No description provided for @assistantInitialMessage.
  ///
  /// In en, this message translates to:
  /// **'Ask me about crops, markets, price forecasts, or the best time to sell.'**
  String get assistantInitialMessage;

  /// No description provided for @cropSelectionRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get cropSelectionRadius;

  /// No description provided for @soilOrganicMatter.
  ///
  /// In en, this message translates to:
  /// **'Organic matter (%)'**
  String get soilOrganicMatter;

  /// No description provided for @cropSelectionRecommendationDetails.
  ///
  /// In en, this message translates to:
  /// **'Open recommendation details'**
  String get cropSelectionRecommendationDetails;

  /// No description provided for @cropSelectionHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your crop, market, and selling window.'**
  String get cropSelectionHeroTitle;

  /// No description provided for @recommendationLabelExpectedPrice.
  ///
  /// In en, this message translates to:
  /// **'Expected price'**
  String get recommendationLabelExpectedPrice;

  /// No description provided for @greetingHi.
  ///
  /// In en, this message translates to:
  /// **'Hi'**
  String get greetingHi;

  /// No description provided for @soilGetRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Get recommendations'**
  String get soilGetRecommendations;

  /// No description provided for @homeSoilSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These recommendations are generated by the backend so the frontend stays aligned with the same crop list and logic.'**
  String get homeSoilSubtitle;

  /// No description provided for @homeWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get homeWelcomeBack;

  /// No description provided for @cropSelectionPredicting.
  ///
  /// In en, this message translates to:
  /// **'Predicting…'**
  String get cropSelectionPredicting;

  /// No description provided for @chartPriceForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Price forecast'**
  String get chartPriceForecastTitle;

  /// No description provided for @cropSelectionNoCrops.
  ///
  /// In en, this message translates to:
  /// **'No crops available.'**
  String get cropSelectionNoCrops;

  /// No description provided for @cropSelectionKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get cropSelectionKm;

  /// No description provided for @cropSelectionTypedMarket.
  ///
  /// In en, this message translates to:
  /// **'Typed mandi'**
  String get cropSelectionTypedMarket;

  /// No description provided for @cropSelectionKmAway.
  ///
  /// In en, this message translates to:
  /// **'km away'**
  String get cropSelectionKmAway;

  /// No description provided for @recommendationLabelCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get recommendationLabelCrop;

  /// No description provided for @homePriceTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Price trend'**
  String get homePriceTrendTitle;

  /// No description provided for @cropSelectionSelectCropSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the crop you want to get price predictions for.'**
  String get cropSelectionSelectCropSubtitle;

  /// No description provided for @predictionErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Prediction failed'**
  String get predictionErrorFailed;

  /// No description provided for @cropSelectionNoMarketsInRadius.
  ///
  /// In en, this message translates to:
  /// **'No mandis were found within the selected radius.'**
  String get cropSelectionNoMarketsInRadius;

  /// No description provided for @fieldCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get fieldCrop;

  /// No description provided for @homeSoilTitle.
  ///
  /// In en, this message translates to:
  /// **'Soil recommendation'**
  String get homeSoilTitle;

  /// No description provided for @cropSelectionHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse more crops, compare current prices across available markets, and forecast the best selling window.'**
  String get cropSelectionHeroSubtitle;

  /// No description provided for @buttonGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get buttonGenerating;

  /// No description provided for @cropSelectionSearchMarketHint.
  ///
  /// In en, this message translates to:
  /// **'Start typing a mandi name, district, or state'**
  String get cropSelectionSearchMarketHint;

  /// No description provided for @cropSelectionHeroPill3.
  ///
  /// In en, this message translates to:
  /// **'3. View forecast'**
  String get cropSelectionHeroPill3;

  /// No description provided for @cropSelectionLoadingOptionsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load options'**
  String get cropSelectionLoadingOptionsError;

  /// No description provided for @assistantSuggestionMarkets.
  ///
  /// In en, this message translates to:
  /// **'Markets for wheat'**
  String get assistantSuggestionMarkets;

  /// No description provided for @predictionButtonPredictPrice.
  ///
  /// In en, this message translates to:
  /// **'Predict price'**
  String get predictionButtonPredictPrice;

  /// No description provided for @soilPh.
  ///
  /// In en, this message translates to:
  /// **'pH level'**
  String get soilPh;

  /// No description provided for @recommendationLabelMarket.
  ///
  /// In en, this message translates to:
  /// **'Mandi'**
  String get recommendationLabelMarket;

  /// No description provided for @soilNitrogen.
  ///
  /// In en, this message translates to:
  /// **'Nitrogen (N)'**
  String get soilNitrogen;

  /// No description provided for @assistantSuggestionBestTime.
  ///
  /// In en, this message translates to:
  /// **'Best time to sell wheat in Delhi'**
  String get assistantSuggestionBestTime;

  /// No description provided for @cropSelectionForecastHelper.
  ///
  /// In en, this message translates to:
  /// **'Choose a value from 1 to 90 days'**
  String get cropSelectionForecastHelper;

  /// No description provided for @soilMoisture.
  ///
  /// In en, this message translates to:
  /// **'Moisture (%)'**
  String get soilMoisture;

  /// No description provided for @recommendationTitleRecommendedWindow.
  ///
  /// In en, this message translates to:
  /// **'Recommended sale window'**
  String get recommendationTitleRecommendedWindow;

  /// No description provided for @labelDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get labelDay;

  /// No description provided for @recommendationLabelTargetDay.
  ///
  /// In en, this message translates to:
  /// **'Target day'**
  String get recommendationLabelTargetDay;

  /// No description provided for @chatbotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about crops, mandis, prices, and selling timing.'**
  String get chatbotSubtitle;

  /// No description provided for @homeWeatherTitle.
  ///
  /// In en, this message translates to:
  /// **'5-day weather'**
  String get homeWeatherTitle;

  /// No description provided for @cropSelectionNoMarketPrices.
  ///
  /// In en, this message translates to:
  /// **'No market prices are available for this crop yet.'**
  String get cropSelectionNoMarketPrices;

  /// No description provided for @homeApproxLocation.
  ///
  /// In en, this message translates to:
  /// **'Approx location'**
  String get homeApproxLocation;

  /// No description provided for @cropSelectionSearchMarketLabel.
  ///
  /// In en, this message translates to:
  /// **'Search or type market'**
  String get cropSelectionSearchMarketLabel;

  /// No description provided for @cropSelectionUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get cropSelectionUseMyLocation;

  /// No description provided for @cropSelectionNoMatchingMarketsPrefix.
  ///
  /// In en, this message translates to:
  /// **'No matching mandis for'**
  String get cropSelectionNoMatchingMarketsPrefix;

  /// No description provided for @cropSelectionLocationPermissionHelp.
  ///
  /// In en, this message translates to:
  /// **'Allow location access to show mandis near you.'**
  String get cropSelectionLocationPermissionHelp;

  /// No description provided for @cropSelectionLatestUpdate.
  ///
  /// In en, this message translates to:
  /// **'Latest update'**
  String get cropSelectionLatestUpdate;

  /// No description provided for @errorSelectCropMarket.
  ///
  /// In en, this message translates to:
  /// **'Select a crop and market before generating a forecast.'**
  String get errorSelectCropMarket;

  /// No description provided for @soilSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get soilSubmitting;

  /// No description provided for @predictionButtonViewRecommendation.
  ///
  /// In en, this message translates to:
  /// **'View recommendation'**
  String get predictionButtonViewRecommendation;

  /// No description provided for @buttonOpenRecommendationDetails.
  ///
  /// In en, this message translates to:
  /// **'Open recommendation details'**
  String get buttonOpenRecommendationDetails;

  /// No description provided for @soilPhosphorus.
  ///
  /// In en, this message translates to:
  /// **'Phosphorus (P)'**
  String get soilPhosphorus;

  /// No description provided for @cropSelectionLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get cropSelectionLocating;

  /// No description provided for @priceAdvisorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This flow is fully backed by the API: crop selection, market selection, forecast generation, and recommendation details.'**
  String get priceAdvisorSubtitle;

  /// No description provided for @fieldMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get fieldMarket;

  /// No description provided for @valueUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get valueUnknown;

  /// No description provided for @valueNA.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get valueNA;

  /// No description provided for @cropSelectionErrorSelectCropMarket.
  ///
  /// In en, this message translates to:
  /// **'Select a crop and either choose a mandi from the list or type the mandi name.'**
  String get cropSelectionErrorSelectCropMarket;

  /// No description provided for @cropSelectionNearbyFilteringUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Nearby mandi filtering unavailable'**
  String get cropSelectionNearbyFilteringUnavailable;

  /// No description provided for @cropSelectionLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable.'**
  String get cropSelectionLocationUnavailable;

  /// No description provided for @cropSelectionNoMatchingMarketsSuffix.
  ///
  /// In en, this message translates to:
  /// **'You can still use this typed name when generating a forecast.'**
  String get cropSelectionNoMatchingMarketsSuffix;

  /// No description provided for @cropSelectionShowingMandisWithin.
  ///
  /// In en, this message translates to:
  /// **'Showing mandis within'**
  String get cropSelectionShowingMandisWithin;

  /// No description provided for @cropSelectionOfCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'of your current location.'**
  String get cropSelectionOfCurrentLocation;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'as',
        'bn',
        'brx',
        'doi',
        'en',
        'gu',
        'hi',
        'kn',
        'kok',
        'ks',
        'mai',
        'ml',
        'mni',
        'mr',
        'ne',
        'or',
        'pa',
        'sa',
        'sat',
        'sd',
        'ta',
        'te',
        'ur'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'mni':
      {
        switch (locale.scriptCode) {
          case 'Mtei':
            return AppLocalizationsMniMtei();
        }
        break;
      }
    case 'sat':
      {
        switch (locale.scriptCode) {
          case 'Olck':
            return AppLocalizationsSatOlck();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'as':
      return AppLocalizationsAs();
    case 'bn':
      return AppLocalizationsBn();
    case 'brx':
      return AppLocalizationsBrx();
    case 'doi':
      return AppLocalizationsDoi();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'kok':
      return AppLocalizationsKok();
    case 'ks':
      return AppLocalizationsKs();
    case 'mai':
      return AppLocalizationsMai();
    case 'ml':
      return AppLocalizationsMl();
    case 'mni':
      return AppLocalizationsMni();
    case 'mr':
      return AppLocalizationsMr();
    case 'ne':
      return AppLocalizationsNe();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'sa':
      return AppLocalizationsSa();
    case 'sat':
      return AppLocalizationsSat();
    case 'sd':
      return AppLocalizationsSd();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
