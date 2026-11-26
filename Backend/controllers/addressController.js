const db = require('../config/database');

// GET SEMUA ALAMAT MILIK SENDIRI
// Alamat utama selalu di atas supaya Flutter tidak perlu mengurutkan lagi.
const getAddresses = async (req, res) => {
    try {
        const [addresses] = await db.promise().query(
            `SELECT id, label, address, is_primary, created_at, updated_at
             FROM addresses
             WHERE user_id = ?
             ORDER BY is_primary DESC, id ASC`,
            [req.user.id]
        );

        res.status(200).json({
            success: true,
            message: 'Daftar alamat berhasil diambil',
            data: addresses
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil data alamat'
        });
    }
};

// TAMBAH ALAMAT
// Alamat pertama milik seorang user otomatis menjadi alamat utama.
const createAddress = async (req, res) => {
    try {
        const { label, address } = req.body;

        if (!label || !String(label).trim()) {
            return res.status(400).json({
                success: false,
                message: 'Label alamat wajib diisi'
            });
        }

        if (!address || !String(address).trim()) {
            return res.status(400).json({
                success: false,
                message: 'Alamat wajib diisi'
            });
        }

        const [jumlah] = await db.promise().query(
            'SELECT COUNT(*) AS total FROM addresses WHERE user_id = ?',
            [req.user.id]
        );

        const utama = jumlah[0].total === 0 ? 1 : 0;

        const [result] = await db.promise().query(
            `INSERT INTO addresses (user_id, label, address, is_primary)
             VALUES (?, ?, ?, ?)`,
            [
                req.user.id,
                String(label).trim(),
                String(address).trim(),
                utama
            ]
        );

        res.status(201).json({
            success: true,
            message: 'Alamat berhasil ditambahkan',
            data: {
                id: result.insertId,
                label: String(label).trim(),
                address: String(address).trim(),
                is_primary: utama
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal menambahkan alamat'
        });
    }
};

// UBAH ALAMAT
// Hanya alamat milik sendiri. Id milik user lain dijawab 404, bukan 403,
// supaya keberadaan alamat orang lain tidak bisa ditebak.
const updateAddress = async (req, res) => {
    try {
        const { id } = req.params;
        const { label, address } = req.body;

        if (!label || !String(label).trim()) {
            return res.status(400).json({
                success: false,
                message: 'Label alamat wajib diisi'
            });
        }

        if (!address || !String(address).trim()) {
            return res.status(400).json({
                success: false,
                message: 'Alamat wajib diisi'
            });
        }

        const [result] = await db.promise().query(
            `UPDATE addresses
             SET label = ?, address = ?
             WHERE id = ? AND user_id = ?`,
            [
                String(label).trim(),
                String(address).trim(),
                id,
                req.user.id
            ]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: 'Alamat tidak ditemukan'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Alamat berhasil diperbarui'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal memperbarui alamat'
        });
    }
};

// HAPUS ALAMAT
// Kalau yang dihapus adalah alamat utama, alamat tersisa yang paling awal
// naik menjadi utama, supaya user tidak pernah kehilangan alamat utama.
const deleteAddress = async (req, res) => {
    let connection;

    try {
        const { id } = req.params;

        // Koneksi diambil dari pool dan dilepas lagi di blok finally.
        connection = await db.promise().getConnection();
        await connection.beginTransaction();

        const [addresses] = await connection.query(
            'SELECT id, is_primary FROM addresses WHERE id = ? AND user_id = ?',
            [id, req.user.id]
        );

        if (addresses.length === 0) {
            await connection.rollback();

            return res.status(404).json({
                success: false,
                message: 'Alamat tidak ditemukan'
            });
        }

        const dihapusUtama = addresses[0].is_primary === 1;

        await connection.query(
            'DELETE FROM addresses WHERE id = ? AND user_id = ?',
            [id, req.user.id]
        );

        if (dihapusUtama) {
            const [sisa] = await connection.query(
                `SELECT id FROM addresses
                 WHERE user_id = ?
                 ORDER BY id ASC
                 LIMIT 1`,
                [req.user.id]
            );

            if (sisa.length > 0) {
                await connection.query(
                    'UPDATE addresses SET is_primary = 1 WHERE id = ?',
                    [sisa[0].id]
                );
            }
        }

        await connection.commit();

        res.status(200).json({
            success: true,
            message: 'Alamat berhasil dihapus'
        });

    } catch (error) {
        if (connection) {
            await connection.rollback();
        }

        res.status(500).json({
            success: false,
            message: 'Gagal menghapus alamat'
        });
    } finally {
        if (connection) connection.release();
    }
};

// JADIKAN ALAMAT UTAMA
// Dua baris harus berubah bersama (yang lama jadi 0, yang dipilih jadi 1),
// jadi dibungkus transaksi.
const setPrimaryAddress = async (req, res) => {
    let connection;

    try {
        const { id } = req.params;

        // Koneksi diambil dari pool dan dilepas lagi di blok finally.
        connection = await db.promise().getConnection();
        await connection.beginTransaction();

        const [addresses] = await connection.query(
            'SELECT id FROM addresses WHERE id = ? AND user_id = ?',
            [id, req.user.id]
        );

        if (addresses.length === 0) {
            await connection.rollback();

            return res.status(404).json({
                success: false,
                message: 'Alamat tidak ditemukan'
            });
        }

        await connection.query(
            'UPDATE addresses SET is_primary = 0 WHERE user_id = ?',
            [req.user.id]
        );

        await connection.query(
            'UPDATE addresses SET is_primary = 1 WHERE id = ? AND user_id = ?',
            [id, req.user.id]
        );

        await connection.commit();

        res.status(200).json({
            success: true,
            message: 'Alamat utama berhasil diatur'
        });

    } catch (error) {
        if (connection) {
            await connection.rollback();
        }

        res.status(500).json({
            success: false,
            message: 'Gagal mengatur alamat utama'
        });
    } finally {
        if (connection) connection.release();
    }
};

module.exports = {
    getAddresses,
    createAddress,
    updateAddress,
    deleteAddress,
    setPrimaryAddress
};
