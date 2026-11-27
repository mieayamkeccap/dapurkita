import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';
import '../auth/login_screen.dart';
import 'alamat_screen.dart';
import 'favorit_screen.dart';
import 'pengaturan_screen.dart';

class ProfilScreen extends StatefulWidget {
  // Dipakai menu "Pesanan Saya" supaya pindah ke tab Pesanan di navbar
  final VoidCallback bukaPesanan;

  const ProfilScreen({super.key, required this.bukaPesanan});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  String userName = '';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final preferences = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      userName = preferences.getString('name') ?? '';
      userEmail = preferences.getString('email') ?? '';
    });
  }

  void bukaHalaman(Widget halaman) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => halaman),
    ).then((_) {
      if (mounted) loadUserData();
    });
  }

  void bukaPengaturan() {
    bukaHalaman(const PengaturanScreen());
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
    return Scaffold(
      backgroundColor: AppStyle.latar,
      appBar: AppBar(
        backgroundColor: AppStyle.latar,
        title: Text(
          'Profil',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppStyle.hijauTua,
          ),
        ),
        actions: [
          IconButton(
            onPressed: bukaPengaturan,
            icon: const Icon(Icons.settings_outlined, color: AppStyle.hijauTua),
          ),
        ],
      ),
      body: BatasLebar(
        maxWidth: lebarKontenAdaptif(context),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppStyle.hijauMuda,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 56,
                    color: AppStyle.hijauTua,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userName == '' ? 'Pelanggan' : userName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppStyle.hijauTua,
                  ),
                ),
                Text(
                  userEmail == '' ? '-' : userEmail,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppStyle.abuTeks,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppStyle.garis),
              ),
              child: Column(
                children: [
                  buildMenu(
                    Icons.receipt_long_outlined,
                    'Pesanan Saya',
                    widget.bukaPesanan,
                  ),
                  buildMenu(
                    Icons.location_on_outlined,
                    'Alamat Saya',
                    () => bukaHalaman(const AlamatScreen()),
                  ),
                  buildMenu(
                    Icons.favorite_border_rounded,
                    'Favorit',
                    () => bukaHalaman(const FavoritScreen()),
                  ),
                  buildMenu(
                    Icons.settings_outlined,
                    'Pengaturan',
                    bukaPengaturan,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppStyle.garis),
              ),
              child: buildMenu(Icons.logout_rounded, 'Keluar Akun', keluar),
            ),
          ],
        ),
      ),
    );
  }

  // Material transparan supaya ListTile tampil di atas dekorasi Container
  Widget buildMenu(IconData ikon, String teks, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Icon(ikon, color: AppStyle.hijauTua, size: 20),
        title: Text(
          teks,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppStyle.hijauTua,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppStyle.abuTeks,
          size: 20,
        ),
      ),
    );
  }
}
