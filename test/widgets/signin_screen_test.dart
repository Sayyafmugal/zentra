import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zentra_0/Controllers/auth_controller.dart';
import 'package:zentra_0/view/signin_screen.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGetStorage extends Mock implements GetStorage {}

void main() {
  late MockFirebaseAuth auth;
  late MockGetStorage storage;

  setUp(() {
    auth = MockFirebaseAuth();
    storage = MockGetStorage();
    when(() => auth.authStateChanges()).thenAnswer((_) => const Stream.empty());
    when(() => auth.currentUser).thenReturn(null);
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});

    Get.put<AuthController>(AuthController(auth: auth, storage: storage));
  });

  tearDown(Get.reset);

  testWidgets('submitting the form empty shows validation errors and never calls sign-in', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: SigninScreen()));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    // No sign-in attempt should have reached FirebaseAuth.
    verifyNever(
      () => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('shows an error for a malformed email', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: SigninScreen()));

    await tester.enterText(find.byKey(const Key('signin_email_field')), 'not-an-email');
    await tester.enterText(find.byKey(const Key('signin_password_field')), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('the "Login as Seller / Admin" bypass button no longer exists', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: SigninScreen()));
    expect(find.text('Login as Seller / Admin'), findsNothing);
  });
}
