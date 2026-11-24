
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../widgets/app_style.dart';
import '../../widgets/responsive.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  // Fungsi untuk mendaftar akun baru
  Future<void> register() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String phone = phoneController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      tampilkanPesan(context, 'Nama, email, dan password wajib diisi');
      return;
    }

    String? pesanEmail = AuthService.pesanEmailTidakValid(email);

    if (pesanEmail != null) {
      tampilkanPesan(context, pesanEmail);
      return;
    }

    if (password.length < 6) {
      tampilkanPesan(context, 'Password minimal 6 karakter');
      return;
    }

    if (password != confirmPassword) {
      tampilkanPesan(context, 'Password dan konfirmasi password tidak sama');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await AuthService.register(
        name,
        email,
        password,
        phone,
      );

      if (!mounted) return;

      if (result['success'] != true) {
        tampilkanPesan(context, result['message'] ?? 'Pendaftaran gagal');
        return;
      }

      tampilkanPesan(context, 'Daftar berhasil, silakan masuk');

      Navigator.pop(context);
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

  // Label kecil di atas setiap kolom isian
  Widget buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppStyle.hijauTua,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.krem,
      appBar: AppBar(
        backgroundColor: AppStyle.krem,
        foregroundColor: AppStyle.hijauTua,
        elevation: 0,
        title: Text(
          'Daftar Akun',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppStyle.hijauTua,
          ),
        ),
      ),
      body: SafeArea(
        child: BatasLebar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buat akun baru',
                style: GoogleFonts.poppins(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: AppStyle.hijauTua,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Isi data di bawah untuk mulai memesan.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppStyle.abuTeks,
                ),
              ),
              const SizedBox(height: 24),
              buildLabel('Nama'),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: const TextStyle(fontSize: 13),
                decoration: AppStyle.kotakIsian(
                  hint: 'Masukkan nama lengkap',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 16),
              buildLabel('Email'),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 13),
                decoration: AppStyle.kotakIsian(
                  hint: 'Masukkan email',
                  icon: Icons.mail_outline_rounded,
                ),
              ),
              const SizedBox(height: 16),
              buildLabel('Nomor HP (boleh kosong)'),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 13),
                decoration: AppStyle.kotakIsian(
                  hint: 'Masukkan nomor HP',
                  icon: Icons.phone_outlined,
                ),
              ),
              const SizedBox(height: 16),
              buildLabel('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                style: const TextStyle(fontSize: 13),
                decoration: AppStyle.kotakIsian(
                  hint: 'Minimal 6 karakter',
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
              const SizedBox(height: 16),
              buildLabel('Konfirmasi Password'),
              const SizedBox(height: 8),
              TextField(
                controller: confirmPasswordController,
                obscureText: hideConfirmPassword,
                style: const TextStyle(fontSize: 13),
                decoration: AppStyle.kotakIsian(
                  hint: 'Ulangi password',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        hideConfirmPassword = !hideConfirmPassword;
                      });
                    },
                    icon: Icon(
                      hideConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppStyle.abuTeks,
                      size: 19,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : register,
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
                          'Daftar',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
