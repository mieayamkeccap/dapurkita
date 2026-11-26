# Panduan Deploy DapurKita

Dokumen ini mencatat proses menaikkan DapurKita dari komputer lokal ke internet.

| Bagian | Platform | Alamat hasil |
|---|---|---|
| Aplikasi Flutter web | Netlify | _diisi setelah langkah 3_ |
| REST API (Express) | Render | _diisi setelah langkah 2_ |
| Database MySQL | Aiven | _diisi setelah langkah 1_ |

Tanggal deploy: _diisi saat pelaksanaan_

> Catatan: isi bagian yang bertanda _miring_ dengan hasil sebenarnya saat
> mengerjakan. Dokumen ini dipakai sebagai bahan sub-bab 4.5 Deployment pada SRS,
> jadi tulis apa adanya — termasuk masalah yang muncul dan cara mengatasinya.

---

## Persiapan yang sudah dilakukan di kode

Sebelum naik ke server, tiga hal diperbaiki karena baru bermasalah setelah online:

1. **Alamat API tidak lagi ditanam di kode.** `Frontend/lib/config/api_config.dart`
   membaca `API_BASE_URL` saat build. Nilai bawaan tetap `http://localhost:8000/api`
   supaya `flutter run` di lokal tidak berubah.
2. **Koneksi database memakai pool.** `Backend/config/database.js` memakai
   `mysql.createPool` dengan `connectionLimit: 5`, `DB_PORT`, dan dukungan TLS untuk
   Aiven. Sebelumnya satu koneksi dipakai semua request, sehingga koneksi yang
   diputus Aiven mematikan seluruh API.
3. **Transaksi memakai koneksi sendiri.** Lima fungsi (`createOrder`,
   `updateOrderStatus`, `completeOrderByCustomer`, `deleteAddress`,
   `setPrimaryAddress`) mengambil koneksi dari pool lewat `getConnection()` dan
   mengembalikannya dengan `release()` di blok `finally`.

Data awal ada di `Backend/erd/seed_deploy.sql` (2 akun, 4 kategori, 3 produk).
File `Backend/erd/dapurkita_db.sql` tetap ekspor mysqldump apa adanya tanpa INSERT.

---

## Langkah 1 — Database di Aiven

### 1.1 Buat service

1. Masuk ke <https://console.aiven.io> lalu daftar/masuk.
2. **Create service** → pilih **MySQL**.
3. Pilih plan yang tersedia. **Periksa dulu apakah plan gratis ada di akun ini.**
   Kalau yang tersedia hanya berbayar, hentikan di sini dan jangan lanjut dengan
   asumsi — biayanya akan menempel ke akun.
4. Pilih region terdekat (misalnya Singapore), lalu **Create service**.
5. Tunggu status service menjadi **Running**.

### 1.2 Catat kredensial

Buka halaman service, bagian **Overview** → **Connection information**. Catat:

- Host
- Port (Aiven tidak memakai 3306)
- User (biasanya `avnadmin`)
- Password
- Database bawaan (biasanya `defaultdb`)

Unduh juga **CA certificate** (`ca.pem`) dari halaman itu.

> Halaman tersebut menampilkan perintah `mysql` siap pakai. Salin dari sana,
> jangan menyusun sendiri, karena flag SSL-nya bisa berbeda antar service.

### 1.3 Impor struktur tabel

Jalankan dari folder root repo. Ganti bagian dalam kurung siku dengan nilai dari
langkah 1.2.

```bash
mysql --ssl-mode=REQUIRED --ssl-ca=ca.pem -h [HOST] -P [PORT] -u [USER] -p [DATABASE] < Backend/erd/dapurkita_db.sql
```

File SQL tidak memuat `CREATE DATABASE` dan `USE`, jadi nama database **wajib**
disebut di perintah seperti di atas.

### 1.4 Impor data awal

```bash
mysql --ssl-mode=REQUIRED --ssl-ca=ca.pem -h [HOST] -P [PORT] -u [USER] -p [DATABASE] < Backend/erd/seed_deploy.sql
```

Perintah terakhir di file itu menampilkan jumlah baris. Yang benar: **2 user,
4 kategori, 3 produk**.

Akun yang tersedia setelah langkah ini:

| Email | Password | Role |
|---|---|---|
| `admin@gmail.com` | `admin123` | admin |
| `eros@gmail.com` | `eros123` | customer |

> Ganti password ini setelah aplikasi online. Password disimpan sebagai hash
> bcrypt, jadi tidak bisa dibaca dari database.

### 1.5 Siapkan isi DB_CA_CERT

Render tidak menerima unggahan berkas, jadi isi `ca.pem` dikirim lewat variabel
lingkungan. Ubah ke base64 supaya aman ditempel:

```bash
base64 -w0 ca.pem > ca-base64.txt
```

Isi `ca-base64.txt` itulah yang dipakai sebagai nilai `DB_CA_CERT` di langkah 2.

---

## Langkah 2 — Backend di Render

### 2.1 Buat Web Service

1. Masuk ke <https://dashboard.render.com> lalu hubungkan akun GitHub.
2. **New** → **Web Service** → pilih repo `mieayamkeccap/dapurkita`.
3. Isi:

| Kolom | Nilai |
|---|---|
| Name | `dapurkita-api` (atau nama lain) |
| Region | Singapore (samakan dengan Aiven) |
| Branch | `main` |
| Root Directory | `Backend` |
| Runtime | Node |
| Build Command | `npm install` |
| Start Command | `npm start` |
| Instance Type | **Free** |

### 2.2 Isi variabel lingkungan

Bagian **Environment** → **Add Environment Variable**. Isi satu per satu:

| Nama | Nilai |
|---|---|
| `DB_HOST` | host Aiven |
| `DB_PORT` | port Aiven |
| `DB_USER` | user Aiven |
| `DB_PASSWORD` | password Aiven |
| `DB_NAME` | nama database Aiven |
| `DB_SSL` | `true` |
| `DB_CA_CERT` | isi `ca-base64.txt` dari langkah 1.5 |
| `JWT_SECRET` | **kunci baru**, bukan yang di `.env` lokal |
| `CLOUDINARY_CLOUD_NAME` | dari akun Cloudinary |
| `CLOUDINARY_API_KEY` | dari akun Cloudinary |
| `CLOUDINARY_API_SECRET` | dari akun Cloudinary |

`PORT` **tidak diisi**. Render menentukan port sendiri dan `server.js` sudah
membacanya dari `process.env.PORT`.

> `JWT_SECRET` harus berbeda dari lokal. Kalau sama, token yang dibuat di lokal
> ikut berlaku di server.

### 2.3 Uji

Buka `https://[nama-service].onrender.com/`. Yang benar:

```json
{"success":true,"message":"DapurKita API berhasil berjalan!"}
```

Lalu `https://[nama-service].onrender.com/api/products` harus mengembalikan 3
produk dari Aiven.

Cek juga log Render: harus muncul `Database berhasil terhubung!` satu kali dan
tidak ada error berulang.

Uji keamanan: buka `/api/orders` tanpa token, harus menjawab kode 401 dengan
pesan `Token tidak ditemukan. Silakan login.`

> Render gratis **tidur setelah 15 menit tanpa trafik** dan butuh sekitar 1 menit
> untuk bangun. Sebelum sidang, buka alamat API sekali lebih dulu supaya tidak
> menunggu layar loading di depan penguji.

---

## Langkah 3 — Aplikasi web di Netlify

### 3.1 Build dengan alamat API Render

Build dijalankan di komputer, bukan di Netlify, karena Flutter tidak tersedia di
server build Netlify secara bawaan.

```bash
cd Frontend
flutter build web --release --dart-define=API_BASE_URL=https://[nama-service].onrender.com/api
```

Hasilnya ada di `Frontend/build/web`. Folder ini sudah di-*gitignore*, jadi tidak
ikut masuk repository.

### 3.2 Naikkan ke Netlify

1. Masuk ke <https://app.netlify.com> lalu daftar/masuk.
2. Buka menu **Sites** → tarik folder `Frontend/build/web` ke halaman itu
   (drag & drop).
3. Netlify memberi alamat seperti `https://[nama-acak].netlify.app`.
4. Ganti nama lewat **Site configuration** → **Change site name** kalau mau lebih
   rapi, misalnya `dapurkita-[nama]`.

File `Frontend/web/_redirects` sudah ikut tersalin ke `build/web`. Isinya
`/*  /index.html  200`, supaya membuka alamat selain `/` atau menekan refresh di
tengah aplikasi tetap memuat aplikasi, bukan 404.

### 3.3 Uji

| Cek | Harapan |
|---|---|
| Buka alamat Netlify | splash lalu halaman login, tanpa layar kosong |
| Refresh di halaman dalam | aplikasi tetap tampil, bukan 404 |
| Login `admin@gmail.com` / `admin123` | masuk Dashboard Admin |
| Login `eros@gmail.com` / `eros123` | masuk Beranda customer |
| Katalog | 3 produk tampil (tanpa foto, memakai placeholder) |
| Tambah produk + upload foto | foto masuk Cloudinary dan tampil di katalog |
| Checkout pickup vs delivery | ongkir Rp0 vs Rp5.000 |
| Buka dari ponsel | tata letak satu kolom, tombol bisa ditekan |
| Console peramban | tidak ada error CORS, tidak ada permintaan ke `localhost` |

---

## Hasil akhir

| Bagian | Alamat |
|---|---|
| Aplikasi web | _diisi_ |
| REST API | _diisi_ |
| Database | _diisi (host Aiven)_ |
| Repository | <https://github.com/mieayamkeccap/dapurkita> |

---

## Masalah yang muncul saat deploy

Isi bagian ini selama proses berlangsung. Bagian ini yang membuat dokumentasi
bernilai, karena mencatat hal yang tidak ada di tutorial mana pun.

| No | Masalah | Penyebab | Penyelesaian |
|---|---|---|---|
| | | | |
