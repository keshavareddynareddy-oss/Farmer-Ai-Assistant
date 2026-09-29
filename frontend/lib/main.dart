import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:crop_price_predictor/l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';
import 'firebase_options.dart';
import 'services/app_locale_controller.dart';
import 'services/auth_controller.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.web,
    );
  }

  final localeService = LocaleService();
  final initialLanguage = await localeService.loadPreferredLanguage();
  final controller = AppLocaleController(
    localeService: localeService,
    initialLanguage: initialLanguage,
  );

  final authService = AuthService();
  final initialUser = await authService.loadSignedInUser();
  final authController = AuthController(
    authService: authService,
    initialUser: initialUser,
  );

  runApp(
    AppLocaleScope(
      controller: controller,
      child: AuthScope(
        controller: authController,
        child: const CropPricePredictorApp(),
      ),
    ),
  );
}

class CropPricePredictorApp extends StatelessWidget {
  const CropPricePredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppLocaleScope.of(context);

    return MaterialApp(
      onGenerateTitle: (context) => 'AgriProject AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: controller.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AuthGate(),
    );
  }
}
