const db = require('../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// REGISTER
const register = async (req, res) => {
    try {
        const { name, email, password, phone } = req.body;

        // Validasi input
        if (!name || !email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Nama, email, dan password wajib diisi'
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                success: false,
                message: 'Password minimal 6 karakter'
            });
        }

        // Pola sama dengan validasi di aplikasi Flutter.
        const polaEmail = /^[\w.+-]+@[\w-]+(\.[\w-]+)+$/;

        if (!polaEmail.test(String(email).trim())) {
            return res.status(400).json({
                success: false,
                message: 'Format email tidak valid'
            });
        }

        // Cek email
        const [users] = await db.promise().query(
            'SELECT id FROM users WHERE email = ?',
            [email]
        );

        if (users.length > 0) {
            return res.status(409).json({
                success: false,
                message: 'Email sudah terdaftar'
            });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Simpan user baru
        await db.promise().query(
            `INSERT INTO users (name, email, password, phone, role)
             VALUES (?, ?, ?, ?, 'customer')`,
            [name, email, hashedPassword, phone || null]
        );

        res.status(201).json({
            success: true,
            message: 'Registrasi berhasil'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};


// LOGIN
const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Email dan password wajib diisi'
            });
        }

        // Cari user berdasarkan email
        const [users] = await db.promise().query(
            'SELECT * FROM users WHERE email = ?',
            [email]
        );

        if (users.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Email atau password salah'
            });
        }

        const user = users[0];

        // Cocokkan password
        const passwordMatch = await bcrypt.compare(
            password,
            user.password
        );

        if (!passwordMatch) {
            return res.status(401).json({
                success: false,
                message: 'Email atau password salah'
            });
        }

        // Buat JWT
        const token = jwt.sign(
            {
                id: user.id,
                role: user.role
            },
            process.env.JWT_SECRET,
            {
                expiresIn: '1d'
            }
        );

        res.status(200).json({
            success: true,
            message: 'Login berhasil',
            data: {
                token: token,
                user: {
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    phone: user.phone,
                    role: user.role
                }
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Terjadi kesalahan pada server'
        });
    }
};


// PROFIL SENDIRI
// Dipakai halaman Pengaturan supaya nama dan telepon dibaca dari database,
// bukan dari salinan di perangkat.
const getProfile = async (req, res) => {
    try {
        const [users] = await db.promise().query(
            `SELECT id, name, email, phone, role, created_at
             FROM users
             WHERE id = ?`,
            [req.user.id]
        );

        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Pengguna tidak ditemukan'
            });
        }

        res.status(200).json({
            success: true,
            data: users[0]
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil data profil'
        });
    }
};

// UBAH PROFIL
// Hanya nama dan telepon. Email tidak diubah karena dipakai untuk login dan
// punya aturan UNIQUE di database.
const updateProfile = async (req, res) => {
    try {
        const { name, phone } = req.body;

        if (!name || !String(name).trim()) {
            return res.status(400).json({
                success: false,
                message: 'Nama wajib diisi'
            });
        }

        const [result] = await db.promise().query(
            'UPDATE users SET name = ?, phone = ? WHERE id = ?',
            [String(name).trim(), phone ? String(phone).trim() : null, req.user.id]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: 'Pengguna tidak ditemukan'
            });
        }

        const [users] = await db.promise().query(
            `SELECT id, name, email, phone, role
             FROM users
             WHERE id = ?`,
            [req.user.id]
        );

        res.status(200).json({
            success: true,
            message: 'Profil berhasil diperbarui',
            data: users[0]
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal memperbarui profil'
        });
    }
};


module.exports = {
    register,
    login,
    getProfile,
    updateProfile
};