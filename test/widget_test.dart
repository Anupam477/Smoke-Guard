import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smokeguard/features/dashboard/home_page.dart';

void main() {
  testWidgets('SmokeGuard Dashboard HomePage renders cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomePage(),
        ),
      ),
    );

    // Initial frame
    await tester.pump();

    // Verify key dashboard widgets
    expect(find.text('SmokeGuard'), findsOneWidget);
    expect(find.text('Personal Exposure Index (PEI)'), findsOneWidget);
    expect(find.text('Quick Safety Controls'), findsOneWidget);
  });
}
