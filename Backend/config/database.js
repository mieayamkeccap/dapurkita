const mysql = require('mysql2');

// Database memakai POOL, bukan satu koneksi tunggal. Dua alasan:
// 1. Host database seperti Aiven memutus koneksi yang menganggur. Dengan satu
//    koneksi, seluruh API mati sampai server di-restart. Pool membuka koneksi
//    baru saat dibutuhkan.
// 2. Beberapa fungsi memakai transaksi (beginTransaction/commit/rollback).
//    Dengan satu koneksi bersama, dua request bersamaan bisa saling menutup
//    transaksi satu sama lain. Dengan pool, tiap request mengambil koneksinya
//    sendiri lewat db.promise().getConnection() lalu melepasnya dengan release().
const konfigurasi = {
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT) || 3306,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,

    // Aiven (dan sebagian host lain) membatasi jumlah koneksi pada plan kecil.
    connectionLimit: 5,
    waitForConnections: true,
    queueLimit: 0,
    connectTimeout: 10000
};

// Aiven mewajibkan koneksi TLS. DB_SSL=true menyalakannya.
// Kalau DB_CA_CERT diisi, sertifikat itu yang dipakai untuk memverifikasi
// penerbitnya. Kalau tidak diisi, koneksi tetap terenkripsi tetapi sertifikat
// server tidak diperiksa (rejectUnauthorized: false).
if (String(process.env.DB_SSL).toLowerCase() === 'true') {
    const cert = bacaSertifikat(process.env.DB_CA_CERT);

    konfigurasi.ssl = cert
        ? { ca: cert, rejectUnauthorized: true }
        : { rejectUnauthorized: false };
}

// Sertifikat dari variabel lingkungan bisa datang dalam dua bentuk:
// teks PEM apa adanya (dengan \n tertulis sebagai dua karakter), atau isi
// berkas ca.pem yang diubah ke base64 supaya aman ditempel ke kolom env.
function bacaSertifikat(nilai) {
    if (!nilai) return null;

    const teks = String(nilai).replace(/\\n/g, '\n');

    if (teks.includes('BEGIN CERTIFICATE')) {
        return teks;
    }

    try {
        return Buffer.from(teks, 'base64').toString('utf8');
    } catch (error) {
        return null;
    }
}

const db = mysql.createPool(konfigurasi);

// Satu kali percobaan saat start, supaya log langsung jelas kalau kredensial
// salah. Kegagalan di sini tidak menjatuhkan proses: pool akan mencoba lagi
// pada permintaan berikutnya.
db.promise()
    .query('SELECT 1')
    .then(() => {
        console.log('Database berhasil terhubung!');
    })
    .catch((error) => {
        console.log('Koneksi database gagal:', error.message);
    });

module.exports = db;
