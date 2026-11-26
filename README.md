# DapurKita

Aplikasi pemesanan makanan berbasis web dan mobile untuk UMKM kuliner. Dibuat dengan **Flutter** di sisi frontend, **Node.js/Express** di sisi backend, dan **MySQL** sebagai database.

Fitur utama:
- Login & registrasi dengan JWT, password ter-hash bcrypt, dan otorisasi berbasis role (admin & customer)
- Katalog produk & kategori, keranjang, checkout, dan pelacakan status pesanan
- Pembayaran transfer (langsung lunas) dengan ongkir flat Rp5.000
- Upload foto produk lewat backend ke Cloudinary
- Dashboard admin: ringkasan pendapatan, produk terlaris, pesanan harian, dan laporan
- Halaman Pesanan admin menampilkan isi tiap pesanan (produk & jumlahnya) sebelum status diubah
- Laporan admin punya grafik penjualan per produk, dikelompokkan per kategori, untuk 7 hari terakhir

## Struktur Folder

```
DapurKita/
├── Frontend/   # Aplikasi Flutter (lib/, pubspec.yaml)
├── Backend/    # API Express (server.js, controllers/, routes/, config/)
└── Backend/erd/# File SQL ekspor & ERD database
```

## Cara Jalan Lokal

### 1. Database (MySQL)

Buat database `dapurkita_db` lalu impor struktur dari file SQL:

```bash
mysql -u root -p dapurkita_db < Backend/erd/dapurkita_db.sql
```

### 2. Backend

```bash
cd Backend
cp .env.example .env   # isi sesuai database kamu
npm install
npm run dev            # jalan di http://localhost:8000
```

### 3. Frontend

```bash
cd Frontend
flutter pub get
flutter run            # pilih Chrome untuk versi web
```

## Akun Uji

| Role | Email | Password |
|---|---|---|
| Admin | admin@gmail.com | (sesuai data di database lokal) |
| Customer | eros@gmail.com | (sesuai data di database lokal) |


