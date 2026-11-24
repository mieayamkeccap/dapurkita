
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';
import '../admin/dashboard_admin_screen.dart';
import '../main/main_screen.dart';
import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  // Fungsi login
  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      tampilkanPesan(context, 'Email dan password wajib diisi');
      return;
    }

    String? pesanEmail = AuthService.pesanEmailTidakValid(
      emailController.text,
    );

    if (pesanEmail != null) {
      tampilkanPesan(context, pesanEmail);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await AuthService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] != true) {
        tampilkanPesan(context, result['message'] ?? 'Login gagal');
        return;
      }

      // Backend mengirim token dan user di dalam "data"
      final data = result['data'];

      if (data == null) {
        tampilkanPesan(context, 'Data login tidak lengkap');
        return;
      }

      final token = data['token'];
      final user = data['user'];

      if (token == null || user == null) {
        tampilkanPesan(context, 'Data login tidak lengkap');
        return;
      }

      final preferences = await SharedPreferences.getInstance();

      await preferences.setString('token', token.toString());
      await preferences.setString('role', user['role'].toString());
      await preferences.setString('name', user['name'].toString());
      await preferences.setString('email', user['email'].toString());

      if (user['phone'] != null) {
        await preferences.setString('phone', user['phone'].toString());
      }

      if (!mounted) return;

      // Admin masuk ke dashboard, customer masuk ke beranda
      if (user['role'] == 'admin') {
        pindahHalaman(const DashboardAdminScreen());
      } else {
        pindahHalaman(const MainScreen());
      }

      return;
    } catch (error) {
      if (!mounted) return;

      String pesan = error.toString().replaceFirst('Exception: ', '');
      tampilkanPesan(context, pesan);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Pindah halaman dan hapus halaman login dari riwayat
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

  // Membuka halaman daftar akun
  void openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const RegisterScreen();
        },
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.krem,
      body: SafeArea(
        child: BatasLebar(
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildLogoAtas(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
                child: Column(
                  children: [
                    Text(
                      'Selamat Datang',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppStyle.hijauTua,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Masuk untuk melanjutkan',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppStyle.abuTeks,
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 13),
                      decoration: AppStyle.kotakIsian(
                        hint: 'Email',
                        icon: Icons.mail_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: hidePassword,
                      style: const TextStyle(fontSize: 13),
                      decoration: AppStyle.kotakIsian(
                        hint: 'Password',
                        icon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          onPressed: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppStyle.abuTeks,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: AppStyle.tombolUtama(),
                        child: isLoading
                            ? const SizedBox(
                                width: 21,
                                height: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Belum punya akun?',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppStyle.abuTeks,
                          ),
                        ),
                        TextButton(
                          onPressed: openRegister,
                          child: Text(
                            'Daftar di sini',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppStyle.hijauTua,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  // Bagian atas krem dengan logo DapurKita dan hiasan hijau
  Widget buildLogoAtas() {
    return Container(
      width: double.infinity,
      height: 210,
      decoration: const BoxDecoration(
        color: AppStyle.krem,
      ),
      child: Stack(
        children: [
          // Hiasan hijau di sudut kanan atas
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 190,
              height: 190,
              decoration: const BoxDecoration(
                color: AppStyle.hijauTua,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 26,
            right: 40,
            child: Container(
              width: 8,
              height: 26,
              decoration: BoxDecoration(
                color: AppStyle.hijauTua,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            top: 34,
            right: 22,
            child: Container(
              width: 8,
              height: 18,
              decoration: BoxDecoration(
                color: AppStyle.hijauTua,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppStyle.hijauTua,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'DapurKita',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppStyle.hijauTua,
                    letterSpacing: -1.2,
                  ),
                ),
                Text(
                  'Nikmatnya Kuliner, Dalam Genggaman',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppStyle.abuTeks,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
