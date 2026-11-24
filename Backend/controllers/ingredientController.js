
const db = require('../config/database');

// GET SEMUA BAHAN BAKU
const getIngredients = async (req, res) => {
    try {
        const [ingredients] = await db.promise().query(
            'SELECT * FROM ingredients ORDER BY id DESC'
        );

        res.status(200).json({
            success: true,
            message: 'Daftar bahan baku berhasil diambil',
            data: ingredients
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil data bahan baku'
        });
    }
};

// GET DETAIL BAHAN BAKU
const getIngredientById = async (req, res) => {
    try {
        const { id } = req.params;

        const [ingredients] = await db.promise().query(
            'SELECT * FROM ingredients WHERE id = ?',
            [id]
        );

        if (ingredients.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Bahan baku tidak ditemukan'
            });
        }

        res.status(200).json({
            success: true,
            data: ingredients[0]
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil detail bahan baku'
        });
    }
};

// TAMBAH BAHAN BAKU
const createIngredient = async (req, res) => {
    try {
        const { name, unit, stock, minimum_stock } = req.body;

        if (!name || !name.trim() || !unit || !unit.trim()) {
            return res.status(400).json({
                success: false,
                message: 'Nama dan satuan bahan baku wajib diisi'
            });
        }

        if (
            stock === undefined ||
            minimum_stock === undefined ||
            !Number.isFinite(Number(stock)) ||
            !Number.isFinite(Number(minimum_stock)) ||
            Number(stock) < 0 ||
            Number(minimum_stock) < 0
        ) {
            return res.status(400).json({
                success: false,
                message: 'Stok dan minimum stok harus berupa angka yang valid'
            });
        }

        const [result] = await db.promise().query(
            `INSERT INTO ingredients (name, unit, stock, minimum_stock)
             VALUES (?, ?, ?, ?)`,
            [name.trim(), unit.trim(), Number(stock), Number(minimum_stock)]
        );

        res.status(201).json({
            success: true,
            message: 'Bahan baku berhasil ditambahkan',
            data: {
                id: result.insertId,
                name: name.trim(),
                unit: unit.trim(),
                stock: Number(stock),
                minimum_stock: Number(minimum_stock)
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal menambahkan bahan baku'
        });
    }
};

// UPDATE BAHAN BAKU
const updateIngredient = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, unit, minimum_stock } = req.body;

        if (!name || !name.trim() || !unit || !unit.trim()) {
            return res.status(400).json({
                success: false,
                message: 'Nama dan satuan bahan baku wajib diisi'
            });
        }

        if (
            minimum_stock === undefined ||
            !Number.isFinite(Number(minimum_stock)) ||
            Number(minimum_stock) < 0
        ) {
            return res.status(400).json({
                success: false,
                message: 'Minimum stok harus berupa angka yang valid'
            });
        }

        const [result] = await db.promise().query(
            `UPDATE ingredients
             SET name = ?, unit = ?, minimum_stock = ?
             WHERE id = ?`,
            [name.trim(), unit.trim(), Number(minimum_stock), id]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: 'Bahan baku tidak ditemukan'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Bahan baku berhasil diperbarui'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal memperbarui bahan baku'
        });
    }
};

// DELETE BAHAN BAKU
const deleteIngredient = async (req, res) => {
    try {
        const { id } = req.params;

        const [ingredients] = await db.promise().query(
            'SELECT id FROM ingredients WHERE id = ?',
            [id]
        );

        if (ingredients.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Bahan baku tidak ditemukan'
            });
        }

        const [usedIngredients] = await db.promise().query(
            'SELECT id FROM product_ingredients WHERE ingredient_id = ? LIMIT 1',
            [id]
        );

        const [purchaseItems] = await db.promise().query(
            'SELECT id FROM ingredient_purchase_items WHERE ingredient_id = ? LIMIT 1',
            [id]
        );

        if (usedIngredients.length > 0 || purchaseItems.length > 0) {
            return res.status(409).json({
                success: false,
                message: 'Bahan baku masih digunakan dalam resep atau riwayat pembelian'
            });
        }

        await db.promise().query(
            'DELETE FROM ingredients WHERE id = ?',
            [id]
        );

        res.status(200).json({
            success: true,
            message: 'Bahan baku berhasil dihapus'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal menghapus bahan baku'
        });
    }
};

// GET BAHAN BAKU DENGAN STOK MENIPIS
const getLowStockIngredients = async (req, res) => {
    try {
        const [ingredients] = await db.promise().query(
            `SELECT * FROM ingredients
             WHERE stock <= minimum_stock
             ORDER BY stock ASC`
        );

        res.status(200).json({
            success: true,
            message: 'Data stok menipis berhasil diambil',
            data: ingredients
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil data stok menipis'
        });
    }
};

module.exports = {
    getIngredients,
    getIngredientById,
    createIngredient,
    updateIngredient,
    deleteIngredient,
    getLowStockIngredients
};
