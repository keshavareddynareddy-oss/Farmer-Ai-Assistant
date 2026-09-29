import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'locale_service.dart';

class AppLocaleController extends ChangeNotifier {
  AppLocaleController({
    required LocaleService localeService,
    AppLanguage? initialLanguage,
  })  : _localeService = localeService,
        _language = initialLanguage ?? L10n.supportedLanguages.first;

  final LocaleService _localeService;
  AppLanguage _language;

  AppLanguage get language => _language;
  Locale get locale => _language.locale;
  String get apiLanguageTag => _language.tag;

  Future<void> setLanguage(AppLanguage language) async {
    if (language.tag == _language.tag) {
      return;
    }
    _language = language;
    notifyListeners();
    await _localeService.savePreferredLanguage(language);
  }
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    required AppLocaleController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope not found in widget tree.');
    return scope!.notifier!;
  }
}
