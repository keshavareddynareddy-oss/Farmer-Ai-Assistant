import 'package:flutter/material.dart';

class AppLanguage {
  final String tag;
  final Locale locale;
  final String englishName;
  final String nativeName;

  const AppLanguage({
    required this.tag,
    required this.locale,
    required this.englishName,
    required this.nativeName,
  });
}

class L10n {
  static const supportedLanguages = <AppLanguage>[
    AppLanguage(
      tag: 'en',
      locale: Locale('en'),
      englishName: 'English',
      nativeName: 'English',
    ),
    AppLanguage(
      tag: 'as',
      locale: Locale('as'),
      englishName: 'Assamese',
      nativeName: 'অসমীয়া',
    ),
    AppLanguage(
      tag: 'bn',
      locale: Locale('bn'),
      englishName: 'Bengali',
      nativeName: 'বাংলা',
    ),
    AppLanguage(
      tag: 'brx',
      locale: Locale('brx'),
      englishName: 'Bodo',
      nativeName: 'बड़ो',
    ),
    AppLanguage(
      tag: 'doi',
      locale: Locale('doi'),
      englishName: 'Dogri',
      nativeName: 'डोगरी',
    ),
    AppLanguage(
      tag: 'gu',
      locale: Locale('gu'),
      englishName: 'Gujarati',
      nativeName: 'ગુજરાતી',
    ),
    AppLanguage(
      tag: 'hi',
      locale: Locale('hi'),
      englishName: 'Hindi',
      nativeName: 'हिन्दी',
    ),
    AppLanguage(
      tag: 'kn',
      locale: Locale('kn'),
      englishName: 'Kannada',
      nativeName: 'ಕನ್ನಡ',
    ),
    AppLanguage(
      tag: 'ks',
      locale: Locale('ks'),
      englishName: 'Kashmiri',
      nativeName: 'कॉशुर',
    ),
    AppLanguage(
      tag: 'kok',
      locale: Locale('kok'),
      englishName: 'Konkani',
      nativeName: 'कोंकणी',
    ),
    AppLanguage(
      tag: 'mai',
      locale: Locale('mai'),
      englishName: 'Maithili',
      nativeName: 'मैथिली',
    ),
    AppLanguage(
      tag: 'ml',
      locale: Locale('ml'),
      englishName: 'Malayalam',
      nativeName: 'മലയാളം',
    ),
    AppLanguage(
      tag: 'mni-Mtei',
      locale: Locale.fromSubtags(languageCode: 'mni', scriptCode: 'Mtei'),
      englishName: 'Manipuri (Meitei)',
      nativeName: 'ꯃꯩꯇꯩꯂꯣꯟ',
    ),
    AppLanguage(
      tag: 'mr',
      locale: Locale('mr'),
      englishName: 'Marathi',
      nativeName: 'मराठी',
    ),
    AppLanguage(
      tag: 'ne',
      locale: Locale('ne'),
      englishName: 'Nepali',
      nativeName: 'नेपाली',
    ),
    AppLanguage(
      tag: 'or',
      locale: Locale('or'),
      englishName: 'Odia',
      nativeName: 'ଓଡ଼ିଆ',
    ),
    AppLanguage(
      tag: 'pa',
      locale: Locale('pa'),
      englishName: 'Punjabi',
      nativeName: 'ਪੰਜਾਬੀ',
    ),
    AppLanguage(
      tag: 'sa',
      locale: Locale('sa'),
      englishName: 'Sanskrit',
      nativeName: 'संस्कृतम्',
    ),
    AppLanguage(
      tag: 'sat-Olck',
      locale: Locale.fromSubtags(languageCode: 'sat', scriptCode: 'Olck'),
      englishName: 'Santali',
      nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ',
    ),
    AppLanguage(
      tag: 'sd',
      locale: Locale('sd'),
      englishName: 'Sindhi',
      nativeName: 'سنڌي',
    ),
    AppLanguage(
      tag: 'ta',
      locale: Locale('ta'),
      englishName: 'Tamil',
      nativeName: 'தமிழ்',
    ),
    AppLanguage(
      tag: 'te',
      locale: Locale('te'),
      englishName: 'Telugu',
      nativeName: 'తెలుగు',
    ),
    AppLanguage(
      tag: 'ur',
      locale: Locale('ur'),
      englishName: 'Urdu',
      nativeName: 'اردو',
    ),
  ];

  static AppLanguage fromTag(String? tag) {
    final value = (tag ?? '').trim();
    if (value.isEmpty) {
      return supportedLanguages.first;
    }
    return supportedLanguages.firstWhere(
      (language) => language.tag.toLowerCase() == value.toLowerCase(),
      orElse: () => supportedLanguages.first,
    );
  }
}
