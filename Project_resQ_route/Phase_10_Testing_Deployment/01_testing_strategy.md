# 01 — Testing Strategy

## Objective
Define and implement a comprehensive testing strategy covering unit, widget, integration, and end-to-end tests.

---

## Unit Tests (60% of tests)

### What to Test
- Data models (serialization/deserialization)
- Use cases (business logic)
- Services (API calls with mocks)
- Validators (phone, email, password)
- Utility functions (distance, hash, etc.)

### Example: Validator Tests

```dart
// test/core/utils/validators_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:resq_route/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('isValidIndianPhone', () {
      test('valid 10-digit phone starting with 9', () {
        expect(Validators.isValidIndianPhone('9876543210'), true);
      });
      test('valid 10-digit phone starting with 6', () {
        expect(Validators.isValidIndianPhone('6876543210'), true);
      });
      test('invalid - too short', () {
        expect(Validators.isValidIndianPhone('98765432'), false);
      });
      test('invalid - starts with 0', () {
        expect(Validators.isValidIndianPhone('0876543210'), false);
      });
    });

    group('isStrongPassword', () {
      test('valid strong password', () {
        expect(Validators.isStrongPassword('SecureP@ss1'), true);
      });
      test('invalid - no special char', () {
        expect(Validators.isStrongPassword('SecurePass1'), false);
      });
      test('invalid - too short', () {
        expect(Validators.isStrongPassword('S@1'), false);
      });
    });

    group('isValidAadhaar', () {
      test('valid 12-digit number', () {
        expect(Validators.isValidAadhaar('123456789012'), true);
      });
      test('invalid - wrong length', () {
        expect(Validators.isValidAadhaar('12345678'), false);
      });
    });
  });
}
```

### Example: Safety Score Tests

```dart
// test/features/safety/domain/usecases/calculate_safety_score_test.dart
void main() {
  group('SafetyScoreCalculator', () {
    test('high crime density reduces score', () {
      final score = SafetyScoreCalculator.calculate(
        crimeScore: 30,   // Low (lots of crime)
        flagScore: 80,
        commercialScore: 70,
        lightingScore: 60,
        populationScore: 65,
      );
      expect(score, lessThan(60)); // Should be below 60
    });

    test('all-safe area produces high score', () {
      final score = SafetyScoreCalculator.calculate(
        crimeScore: 95,
        flagScore: 90,
        commercialScore: 85,
        lightingScore: 90,
        populationScore: 85,
      );
      expect(score, greaterThan(85));
    });

    test('score bounded between 0-100', () {
      final score = SafetyScoreCalculator.calculate(
        crimeScore: 0,
        flagScore: 0,
        commercialScore: 0,
        lightingScore: 0,
        populationScore: 0,
      );
      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(100));
    });
  });
}
```

---

## Widget Tests (30% of tests)

### What to Test
- Form field validation UI
- SOS button hold/double-tap behavior
- Route card rendering with scores
- Emergency contact list display
- Navigation flows (GoRouter)

```dart
// test/features/auth/presentation/widgets/login_form_test.dart
void main() {
  testWidgets('shows error when phone is invalid', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));
    
    await tester.enterText(find.byKey(Key('phone_field')), '12345');
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();
    
    expect(find.text('Enter a valid Indian phone number'), findsOneWidget);
  });
}
```

---

## Integration Tests (10% of tests)

### Critical User Flows
```dart
// integration_test/full_journey_test.dart
void main() {
  integrationTestRunner((tester) async {
    // 1. Login
    await tester.tap(find.byKey(Key('login_tab')));
    await tester.enterText(find.byKey(Key('phone_field')), '9876543210');
    await tester.enterText(find.byKey(Key('password_field')), 'TestP@ss1');
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();
    
    // 2. Should be on home screen with map
    expect(find.byType(GoogleMap), findsOneWidget);
    
    // 3. Search destination
    await tester.tap(find.byKey(Key('search_bar')));
    await tester.enterText(find.byKey(Key('search_input')), 'India Gate');
    await tester.pumpAndSettle();
    
    // Continue through journey flow...
  });
}
```

---

## Running Tests

```bash
# Unit + Widget tests
flutter test --coverage

# Integration tests
flutter test integration_test/

# Coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## CI Integration

Tests run automatically in GitHub Actions (configured in Phase 1):
- Every push triggers unit + widget tests
- PR merges trigger integration tests
- Release branches trigger full E2E suite

---

## Verification
- [ ] Unit test coverage > 80%
- [ ] Widget test coverage > 60%  
- [ ] Integration tests pass for critical flows
- [ ] All tests pass in CI pipeline
