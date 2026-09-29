// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:crop_price_predictor/main.dart';
import 'package:crop_price_predictor/services/app_locale_controller.dart';
import 'package:crop_price_predictor/services/auth_controller.dart';
import 'package:crop_price_predictor/services/auth_service.dart';
import 'package:crop_price_predictor/services/locale_service.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    final localeController = AppLocaleController(
      localeService: LocaleService(),
    );
    final authController = AuthController(
      authService: AuthService(),
      initialUser: 'test@example.com',
    );

    await tester.pumpWidget(
      AppLocaleScope(
        controller: localeController,
        child: AuthScope(
          controller: authController,
          child: const CropPricePredictorApp(),
        ),
      ),
    );

    expect(find.text('AgriMandi Price AI'), findsOneWidget);
  });
}
