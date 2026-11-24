
import 'package:shared_preferences/shared_preferences.dart';

// Penyimpan pengaturan aplikasi di perangkat (lokal).
class PengaturanStore {
  static const String keyNotifikasi = 'notifikasi_pesanan';

  static Future<bool> ambilNotifikasi() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(keyNotifikasi) ?? true;
  }

  static Future<void> simpanNotifikasi(bool aktif) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(keyNotifikasi, aktif);
  }
}
