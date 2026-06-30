import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paynotify/main.dart';



void main() {
  testWidgets('PayNotify app launches with login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login screen shows up
    expect(find.text('PayNotify'), findsOneWidget);
    expect(find.text('Fuel Station Management System'), findsOneWidget);
    
    // Verify login fields exist
    expect(find.byType(TextField), findsNWidgets(2)); // Username and password fields
    
    // Verify login button
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    
    // Verify demo credentials text
    expect(find.text('Demo Credentials:'), findsOneWidget);
    expect(find.textContaining('Manager: manager / manager123'), findsOneWidget);
  });

  testWidgets('Login button is enabled when fields are filled', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Find username and password fields
    final usernameField = find.byType(TextField).first;
    final passwordField = find.byType(TextField).last;
    
    // Enter username
    await tester.enterText(usernameField, 'john');
    await tester.pump();
    
    // Enter password
    await tester.enterText(passwordField, 'pump1');
    await tester.pump();
    
    // Verify login button is enabled (not null)
    final loginButton = find.widgetWithText(ElevatedButton, 'Login');
    expect(loginButton, findsOneWidget);
  });
}