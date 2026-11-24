# Frontend DapurKita

Bagian frontend aplikasi **DapurKita** (Flutter). Dokumentasi lengkap ada di README di root repo.

## Cara jalan

```bash
flutter pub get
flutter run
```

Untuk versi web, pilih Chrome saat menjalankan. Aplikasi akan terhubung ke backend di `http://localhost:8000/api` (lihat `lib/config/api_config.dart`).

## Struktur

- `lib/config/` — konfigurasi API
- `lib/models/` — model data (produk, pesanan, kategori)
- `lib/screens/` — layar per peran (admin & customer)
- `lib/services/` — komunikasi ke API & penyimpanan lokal
- `test/` — pengujian Flutter

Lihat juga: [README utama](../README.md) · [Backend](../Backend/README.md)
