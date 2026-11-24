import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dapurkita/screens/auth/login_screen.dart';

void main() {
  testWidgets('Halaman login tampil dengan tombol Login', (
    WidgetTester tester,
  ) async {
    // Supaya SharedPreferences bisa dipakai saat tes
    SharedPreferences.setMockInitialValues({});

    // Supaya font tidak diunduh dari internet saat tes
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DapurKita'), findsOneWidget);
    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Daftar di sini'), findsOneWidget);
  });
}
