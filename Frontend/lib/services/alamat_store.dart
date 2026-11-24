
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Model satu alamat yang disimpan di perangkat.
class Alamat {
  final String id;
  String label;
  String alamat;

  Alamat({required this.id, required this.label, required this.alamat});

  Map<String, dynamic> toJson() {
    return {'id': id, 'label': label, 'alamat': alamat};
  }

  factory Alamat.fromJson(Map<String, dynamic> json) {
    return Alamat(
      id: json['id'] == null ? '' : json['id'].toString(),
      label: json['label'] == null ? 'Rumah' : json['label'].toString(),
      alamat: json['alamat'] == null ? '' : json['alamat'].toString(),
    );
  }
}

// Penyimpan daftar alamat di perangkat (lokal).
class AlamatStore {
  static const String keyDaftar = 'alamat_list';
  static const String keyUtama = 'alamat_utama';

  static Future<List<Alamat>> ambilSemua() async {
    final preferences = await SharedPreferences.getInstance();
    final teks = preferences.getString(keyDaftar);
    if (teks == null || teks == '') return [];

    try {
      final hasil = jsonDecode(teks);
      if (hasil is! List) return [];
      List<Alamat> daftar = [];
      for (var item in hasil) {
        if (item is Map<String, dynamic>) {
          daftar.add(Alamat.fromJson(item));
        }
      }
      return daftar;
    } catch (error) {
      return [];
    }
  }

  static Future<void> simpanSemua(List<Alamat> daftar) async {
    final preferences = await SharedPreferences.getInstance();
    final teks = jsonEncode(daftar.map((a) => a.toJson()).toList());
    await preferences.setString(keyDaftar, teks);
  }

  static String buatId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static Future<Alamat> tambah(String label, String alamat) async {
    final daftar = await ambilSemua();
    final baru = Alamat(id: buatId(), label: label, alamat: alamat);
    daftar.add(baru);
    await simpanSemua(daftar);
    // Alamat pertama otomatis jadi utama
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getString(keyUtama) == null) {
      await preferences.setString(keyUtama, baru.id);
    }
    return baru;
  }

  static Future<void> ubah(String id, String label, String alamat) async {
    final daftar = await ambilSemua();
    for (var item in daftar) {
      if (item.id == id) {
        item.label = label;
        item.alamat = alamat;
      }
    }
    await simpanSemua(daftar);
  }

  static Future<void> hapus(String id) async {
    final daftar = await ambilSemua();
    daftar.removeWhere((item) => item.id == id);
    await simpanSemua(daftar);
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getString(keyUtama) == id) {
      if (daftar.isEmpty) {
        await preferences.remove(keyUtama);
      } else {
        await preferences.setString(keyUtama, daftar.first.id);
      }
    }
  }

  static Future<void> setUtama(String id) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(keyUtama, id);
  }

  static Future<Alamat?> ambilUtama() async {
    final preferences = await SharedPreferences.getInstance();
    final idUtama = preferences.getString(keyUtama);
    final daftar = await ambilSemua();
    for (var item in daftar) {
      if (item.id == idUtama) return item;
    }
    return daftar.isEmpty ? null : daftar.first;
  }
}
