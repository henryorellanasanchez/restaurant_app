// Test básico de la aplicación RestaurantApp.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:restaurant_app/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RestaurantApp()));

    // Verificar que la app renderiza el título
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
