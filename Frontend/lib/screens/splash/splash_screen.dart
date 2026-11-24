import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../admin/dashboard_admin_screen.dart';
import '../auth/login_screen.dart';
import '../main/main_screen.dart';
import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';

// Foto makanan untuk layar pembuka.
const String fotoPembuka =
    'https://images.pexels.com/photos/37205607/pexels-photo-37205607.jpeg?auto=compress&cs=tinysrgb&w=1600';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    cekLogin();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mulai unduh foto sejak splash tampil supaya tidak muncul belakangan.
    precacheImage(
      const ResizeImage(NetworkImage(fotoPembuka), width: 1600),
      context,
    );
  }

  // Menunggu sebentar, lalu cek apakah sudah pernah login
  Future<void> cekLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final preferences = await SharedPreferences.getInstance();
    String token = preferences.getString('token') ?? '';
    String role = preferences.getString('role') ?? '';

    if (token != '' && role == 'admin') {
      pindahHalaman(const DashboardAdminScreen());
    } else if (token != '') {
      pindahHalaman(const MainScreen());
    } else {
      pindahHalaman(const LoginScreen());
    }
  }

  void pindahHalaman(Widget halaman) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) {
          return halaman;
        },
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.hijauTua,
      body: Stack(
        children: [
          // Foto makanan menutupi layar penuh
          Positioned.fill(
            child: SizedBox.expand(
              child: Image.network(
                fotoPembuka,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                cacheWidth: 1600,
                frameBuilder: (context, child, frame, wasSyncLoaded) {
                  // Sebelum foto selesai diunduh, tampilkan hijau tua dulu
                  // supaya tidak ada area putih/kosong.
                  if (frame == null) {
                    return const SizedBox.expand(
                      child: ColoredBox(color: AppStyle.hijauTua),
                    );
                  }
                  return child;
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.expand(
                    child: ColoredBox(color: AppStyle.hijauTua),
                  );
                },
              ),
            ),
          ),

          // Lapisan gelap supaya tulisan terbaca
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppStyle.hijauTua.withValues(alpha: 0.85),
                    AppStyle.hijauTua.withValues(alpha: 0.35),
                    AppStyle.hijauTua.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: BatasLebar(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: AppStyle.hijauTua,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'DapurKita',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nikmatnya Kuliner, Dalam Genggaman',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),

                    // Indikator loading
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Menyiapkan menu...',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
