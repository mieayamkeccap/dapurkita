const express = require('express');
const router = express.Router();

const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

// Route demonstrasi otorisasi. Tidak dipakai aplikasi Flutter; gunanya
// untuk membuktikan middleware bekerja: tanpa token ditolak 401, role
// yang salah ditolak 403, role yang cocok mendapat 200.

// Hanya role admin yang boleh mengakses
router.get(
    '/admin',
    authMiddleware,
    roleMiddleware('admin'),
    (req, res) => {
        res.json({
            success: true,
            message: 'Selamat datang di halaman admin'
        });
    }
);

// Hanya role customer yang boleh mengakses
router.get(
    '/customer',
    authMiddleware,
    roleMiddleware('customer'),
    (req, res) => {
        res.json({
            success: true,
            message: 'Selamat datang di halaman customer'
        });
    }
);

module.exports = router;