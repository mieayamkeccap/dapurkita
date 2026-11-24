
import 'api_service.dart';

// Pintasan supaya layar login dan daftar tetap sederhana.
// Isinya hanya meneruskan ke fungsi di ApiService.
class AuthService {
  // Pola sederhana: nama@domain.tld. Cukup untuk form, bukan validasi
  // penuh standar RFC. Email tidak harus asli — dipakai hanya sebagai
  // nama pengguna saat login.
  static final RegExp _polaEmail = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  // Mengembalikan pesan kesalahan, atau null kalau email sudah benar.
  static String? pesanEmailTidakValid(String email) {
    String bersih = email.trim();

    if (bersih.isEmpty) {
      return 'Email wajib diisi';
    }

    if (!_polaEmail.hasMatch(bersih)) {
      return 'Format email tidak valid (contoh: nama@gmail.com)';
    }

    return null;
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    return ApiService.loginUser(email, password);
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    return ApiService.registerUser(name, email, password, phone);
  }
}
