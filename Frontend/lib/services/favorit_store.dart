
import 'package:shared_preferences/shared_preferences.dart';

// Penyimpan id produk favorit di perangkat (lokal).
// Cukup satu variabel global di SharedPreferences, bukan state management.
class FavoritStore {
  static const String keyFavorit = 'favorit_ids';

  static Future<List<int>> ambilIds() async {
    final preferences = await SharedPreferences.getInstance();
    final daftar = preferences.getStringList(keyFavorit) ?? [];
    List<int> hasil = [];
    for (var teks in daftar) {
      int id = int.tryParse(teks) ?? 0;
      if (id != 0) hasil.add(id);
    }
    return hasil;
  }

  static Future<bool> adalah(int productId) async {
    final ids = await ambilIds();
    return ids.contains(productId);
  }

  // Mengembalikan status baru: true = jadi favorit, false = dihapus
  static Future<bool> toggle(int productId) async {
    final preferences = await SharedPreferences.getInstance();
    final ids = await ambilIds();
    if (ids.contains(productId)) {
      ids.remove(productId);
      await preferences.setStringList(
        keyFavorit,
        ids.map((id) => id.toString()).toList(),
      );
      return false;
    }
    ids.add(productId);
    await preferences.setStringList(
      keyFavorit,
      ids.map((id) => id.toString()).toList(),
    );
    return true;
  }
}
