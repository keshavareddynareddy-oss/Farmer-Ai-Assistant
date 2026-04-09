import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

class LocaleService {
  static const _key = 'preferred_language_tag';

  Future<AppLanguage?> loadPreferredLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final tag = prefs.getString(_key);
    if (tag == null || tag.trim().isEmpty) {
      return null;
    }
    return L10n.fromTag(tag);
  }

  Future<void> savePreferredLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language.tag);
  }
}
