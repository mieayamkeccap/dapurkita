
const db = require('../config/database');

// GET SEMUA KATEGORI
const getCategories = async (req, res) => {
    try {
        const [categories] = await db.promise().query(
            'SELECT * FROM categories ORDER BY id DESC'
        );

        res.status(200).json({
            success: true,
            message: 'Daftar kategori berhasil diambil',
            data: categories
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil data kategori'
        });
    }
};

// GET DETAIL KATEGORI
const getCategoryById = async (req, res) => {
    try {
        const { id } = req.params;

        const [categories] = await db.promise().query(
            'SELECT * FROM categories WHERE id = ?',
            [id]
        );

        if (categories.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Kategori tidak ditemukan'
            });
        }

        res.status(200).json({
            success: true,
            data: categories[0]
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil detail kategori'
        });
    }
};

// TAMBAH KATEGORI
const createCategory = async (req, res) => {
    try {
        const { name, description } = req.body;

        if (!name || !name.trim()) {
            return res.status(400).json({
                success: false,
                message: 'Nama kategori wajib diisi'
            });
        }

        const [result] = await db.promise().query(
            'INSERT INTO categories (name, description) VALUES (?, ?)',
            [name.trim(), description || null]
        );

        res.status(201).json({
            success: true,
            message: 'Kategori berhasil ditambahkan',
            data: {
                id: result.insertId,
                name: name.trim(),
                description: description || null
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal menambahkan kategori'
        });
    }
};

// UPDATE KATEGORI
const updateCategory = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, description } = req.body;

        if (!name || !name.trim()) {
            return res.status(400).json({
                success: false,
                message: 'Nama kategori wajib diisi'
            });
        }

        const [result] = await db.promise().query(
            'UPDATE categories SET name = ?, description = ? WHERE id = ?',
            [name.trim(), description || null, id]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: 'Kategori tidak ditemukan'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Kategori berhasil diperbarui'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal memperbarui kategori'
        });
    }
};

// DELETE KATEGORI
const deleteCategory = async (req, res) => {
    try {
        const { id } = req.params;

        const [products] = await db.promise().query(
            'SELECT id FROM products WHERE category_id = ? LIMIT 1',
            [id]
        );

        if (products.length > 0) {
            return res.status(409).json({
                success: false,
                message: 'Kategori tidak bisa dihapus karena masih digunakan produk'
            });
        }

        const [result] = await db.promise().query(
            'DELETE FROM categories WHERE id = ?',
            [id]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: 'Kategori tidak ditemukan'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Kategori berhasil dihapus'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal menghapus kategori'
        });
    }
};

module.exports = {
    getCategories,
    getCategoryById,
    createCategory,
    updateCategory,
    deleteCategory
};
