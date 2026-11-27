
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());

// Koneksi database
require('./config/database');

// Routes
const authRoutes = require('./routes/authRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const productRoutes = require('./routes/productRoutes');
const orderRoutes = require('./routes/orderRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const addressRoutes = require('./routes/addressRoutes');
const favoriteRoutes = require('./routes/favoriteRoutes');

// Menggunakan routes
app.use('/api/auth', authRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/addresses', addressRoutes);
app.use('/api/favorites', favoriteRoutes);

// Halaman utama
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'DapurKita API berhasil berjalan!'
    });
});

// Penanganan error
app.use((error, req, res, next) => {
    // Error dari multer (upload gambar) punya kode sendiri. Terjemahkan
    // supaya pesannya jelas dan tidak jadi "Terjadi kesalahan pada server".
    if (error && error.name === 'MulterError') {
        let pesan = 'Upload gambar gagal';

        if (error.code === 'LIMIT_FILE_SIZE') {
            pesan = 'Ukuran gambar maksimal 5 MB';
        }

        return res.status(400).json({
            success: false,
            message: pesan
        });
    }

    res.status(400).json({
        success: false,
        message: error.message || 'Terjadi kesalahan pada server'
    });
});

// Menjalankan server
const PORT = process.env.PORT || 8000;

// Di Vercel (serverless) file ini di-require dari api/index.js — jangan listen,
// Vercel yang memanggil app-nya sendiri. Di lokal (`nodemon server.js`) blok
// ini tetap jalan seperti biasa.
if (!process.env.VERCEL) {
    app.listen(PORT, () => {
        console.log(`Server berjalan di http://localhost:${PORT}`);
    });
}

module.exports = app;
