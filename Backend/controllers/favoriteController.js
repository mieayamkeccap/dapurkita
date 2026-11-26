const db = require('../config/database');

// GET PRODUK FAVORIT
// Bentuk datanya disamakan dengan GET /api/products (products.* + category_name)
// supaya Flutter bisa memakai ProductModel.fromJson yang sama.
const getFavorites = async (req, res) => {
    try {
        const [products] = await db.promise().query(
            `SELECT products.*, categories.name AS category_name
             FROM favorites
             JOIN products ON favorites.product_id = products.id
             LEFT JOIN categories ON products.category_id = categories.id
             WHERE favorites.user_id = ?
             ORDER BY favorites.id DESC`,
            [req.user.id]
        );

        res.status(200).json({
            success: true,
            message: 'Daftar favorit berhasil diambil',
            data: products
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil data favorit'
        });
    }
};

// GET ID FAVORIT SAJA
// Dipakai detail produk untuk menentukan ikon hati tanpa mengunduh
// seluruh data produk.
const getFavoriteIds = async (req, res) => {
    try {
        const [rows] = await db.promise().query(
            'SELECT product_id FROM favorites WHERE user_id = ?',
            [req.user.id]
        );

        const ids = rows.map((row) => row.product_id);

        res.status(200).json({
            success: true,
            data: ids
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil id favorit'
        });
    }
};

// TAMBAH FAVORIT
const addFavorite = async (req, res) => {
    try {
        const { productId } = req.params;

        const [products] = await db.promise().query(
            'SELECT id FROM products WHERE id = ?',
            [productId]
        );

        if (products.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Produk tidak ditemukan'
            });
        }

        const [sudahAda] = await db.promise().query(
            'SELECT id FROM favorites WHERE user_id = ? AND product_id = ?',
            [req.user.id, productId]
        );

        if (sudahAda.length > 0) {
            return res.status(409).json({
                success: false,
                message: 'Produk sudah ada di favorit'
            });
        }

        await db.promise().query(
            'INSERT INTO favorites (user_id, product_id) VALUES (?, ?)',
            [req.user.id, productId]
        );

        res.status(201).json({
            success: true,
            message: 'Produk ditambahkan ke favorit'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal menambahkan favorit'
        });
    }
};

// HAPUS FAVORIT
const removeFavorite = async (req, res) => {
    try {
        const { productId } = req.params;

        const [result] = await db.promise().query(
            'DELETE FROM favorites WHERE user_id = ? AND product_id = ?',
            [req.user.id, productId]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: 'Produk tidak ada di favorit'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Produk dihapus dari favorit'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal menghapus favorit'
        });
    }
};

module.exports = {
    getFavorites,
    getFavoriteIds,
    addFavorite,
    removeFavorite
};
