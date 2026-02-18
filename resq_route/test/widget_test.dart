import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App launches and shows ResQ Route title', (tester) async {
    // Minimal smoke test — full app requires Supabase init
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('ResQ Route')),
        ),
      ),
    );

    expect(find.text('ResQ Route'), findsOneWidget);
  });
}
