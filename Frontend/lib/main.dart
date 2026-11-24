
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash/splash_screen.dart';

// Dipakai ApiService untuk kembali ke halaman login saat token ditolak
// server (401), dari layar mana pun pengguna berada.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const DapurKitaApp());
}

class DapurKitaApp extends StatelessWidget {
  const DapurKitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0B3D2E);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'DapurKita',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF6F8F5),
          foregroundColor: primaryGreen,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryGreen,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
