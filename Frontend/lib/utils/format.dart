// Helper kecil yang dipakai lebih dari satu layar/model.
// Dikumpulkan di sini supaya aturannya tidak ditulis berulang kali.

/// Membaca angka uang dari server menjadi int utuh.
///
/// MySQL mengirim kolom DECIMAL sebagai teks desimal ("29000.00"), jadi
/// dibaca sebagai double dulu. int.parse akan gagal pada bentuk itu dan
/// nilainya jatuh ke 0 kalau dibaca langsung. Nilai yang kosong atau rusak
/// juga menghasilkan 0 supaya tampilan tidak error.
int bacaAngkaDesimal(dynamic nilai) {
  if (nilai == null) {
    return 0;
  }

  try {
    return double.parse(nilai.toString()).toInt();
  } catch (error) {
    return 0;
  }
}

/// Mengubah nama hari lengkap menjadi singkatan 3 huruf untuk sumbu grafik.
String singkatHari(String hari) {
  if (hari == 'Senin') return 'Sen';
  if (hari == 'Selasa') return 'Sel';
  if (hari == 'Rabu') return 'Rab';
  if (hari == 'Kamis') return 'Kam';
  if (hari == 'Jumat') return 'Jum';
  if (hari == 'Sabtu') return 'Sab';
  if (hari == 'Minggu') return 'Min';
  return hari;
}
