import 'package:flutter/material.dart';

// Warna dan gaya yang dipakai di seluruh aplikasi DapurKita.
// Dikumpulkan di satu tempat supaya semua halaman terlihat sama.
class AppStyle {
  // Warna utama
  static const Color hijauTua = Color(0xFF0B3D2E);
  static const Color hijau = Color(0xFF14663F);
  static const Color hijauMuda = Color(0xFFEAF3E9);
  static const Color krem = Color(0xFFFAF7F0);
  static const Color latar = Color(0xFFF6F8F5);
  static const Color oranye = Color(0xFFF5A623);
  static const Color abuTeks = Color(0xFF89948C);
  static const Color garis = Color(0xFFE8EDE8);
  static const Color merah = Color(0xFFC0392B);

  // Tombol utama hijau tua dengan tulisan putih
  static ButtonStyle tombolUtama() {
    return ElevatedButton.styleFrom(
      backgroundColor: hijauTua,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  // Kotak isian seperti di gambar referensi
  static InputDecoration kotakIsian({
    required String hint,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFA1AAA3),
        fontSize: 13,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: abuTeks,
              size: 20,
            ),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: garis),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: hijauTua, width: 1.4),
      ),
    );
  }
}

// Mengubah angka harga menjadi format rupiah, misal 12000 -> Rp 12.000
String formatRupiah(int harga) {
  String angka = harga.toString();
  String hasil = '';
  int hitung = 0;

  for (int i = angka.length - 1; i >= 0; i--) {
    hasil = '${angka[i]}$hasil';
    hitung++;

    if (hitung % 3 == 0 && i != 0) {
      hasil = '.$hasil';
    }
  }

  return 'Rp $hasil';
}

// Mengubah status pesanan dari database menjadi tulisan yang enak dibaca
String teksStatusPesanan(String status) {
  if (status == 'pending') return 'Menunggu';
  if (status == 'confirmed') return 'Dikonfirmasi';
  if (status == 'preparing') return 'Diproses';
  if (status == 'ready') return 'Siap';
  if (status == 'on_delivery') return 'Diantar';
  if (status == 'completed') return 'Selesai';
  if (status == 'cancelled') return 'Dibatalkan';
  return status;
}

// Warna badge sesuai status pesanan
Color warnaStatusPesanan(String status) {
  if (status == 'pending') return AppStyle.oranye;
  if (status == 'confirmed') return const Color(0xFF2F80ED);
  if (status == 'preparing') return const Color(0xFF9B51E0);
  if (status == 'ready') return const Color(0xFF00A3A3);
  if (status == 'on_delivery') return const Color(0xFF2F80ED);
  if (status == 'completed') return AppStyle.hijau;
  if (status == 'cancelled') return AppStyle.merah;
  return AppStyle.abuTeks;
}

// Menampilkan pesan singkat di bawah layar
void tampilkanPesan(BuildContext context, String pesan) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        pesan,
        style: const TextStyle(fontSize: 12),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppStyle.hijauTua,
    ),
  );
}
