import 'package:flutter_test/flutter_test.dart';

import 'package:farmers_weather_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FarmersWeatherApp());
  });
}
