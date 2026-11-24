
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/app_style.dart';
import '../auth/login_screen.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  String namaAdmin = '';
  String emailAdmin = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final preferences = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      namaAdmin = preferences.getString('name') ?? '';
      emailAdmin = preferences.getString('email') ?? '';
    });
  }

  void keluar() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove('token');
    await preferences.remove('role');
    await preferences.remove('name');
    await preferences.remove('email');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const LoginScreen();
        },
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppStyle.garis),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Akun Admin',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppStyle.hijauTua,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Nama: ${namaAdmin == '' ? '-' : namaAdmin}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppStyle.hijauTua,
                ),
              ),
              Text(
                'Email: ${emailAdmin == '' ? '-' : emailAdmin}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppStyle.hijauTua,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppStyle.garis),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tentang Aplikasi',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppStyle.hijauTua,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'DapurKita - Nikmatnya Kuliner, Dalam Genggaman.\n'
                'Versi 1.0.0',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.6,
                  color: AppStyle.abuTeks,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: keluar,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppStyle.merah,
              side: const BorderSide(color: AppStyle.merah),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(
              'Logout',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
