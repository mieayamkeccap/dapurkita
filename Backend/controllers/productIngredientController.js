
const db = require('../config/database');

// MELIHAT RESEP PRODUK
const getProductIngredients = async (req, res) => {
    try {
        const { productId } = req.params;

        const [recipes] = await db.promise().query(
            `SELECT
                product_ingredients.id,
                product_ingredients.product_id,
                product_ingredients.ingredient_id,
                product_ingredients.quantity,
                ingredients.name AS ingredient_name,
                ingredients.unit
             FROM product_ingredients
             JOIN ingredients
                ON product_ingredients.ingredient_id = ingredients.id
             WHERE product_ingredients.product_id = ?`,
            [productId]
        );

        res.status(200).json({
            success: true,
            message: 'Resep produk berhasil diambil',
            data: recipes
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil resep produk'
        });
    }
};

// MENAMBAHKAN BAHAN KE RESEP
const addProductIngredient = async (req, res) => {
    try {
        const { productId } = req.params;
        const { ingredient_id, quantity } = req.body;

        if (
            !ingredient_id ||
            quantity === undefined ||
            !Number.isFinite(Number(quantity)) ||
            Number(quantity) <= 0
        ) {
            return res.status(400).json({
                success: false,
                message: 'Bahan baku dan jumlah kebutuhan wajib diisi dengan benar'
            });
        }

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

        const [ingredients] = await db.promise().query(
            'SELECT id FROM ingredients WHERE id = ?',
            [ingredient_id]
        );

        if (ingredients.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Bahan baku tidak ditemukan'
            });
        }

        const [existing] = await db.promise().query(
            `SELECT id FROM product_ingredients
             WHERE product_id = ? AND ingredient_id = ?`,
            [productId, ingredient_id]
        );

        if (existing.length > 0) {
            return res.status(409).json({
                success: false,
                message: 'Bahan baku sudah ada di resep produk'
            });
        }

        const [result] = await db.promise().query(
            `INSERT INTO product_ingredients
             (product_id, ingredient_id, quantity)
             VALUES (?, ?, ?)`,
            [productId, ingredient_id, Number(quantity)]
        );

        res.status(201).json({
            success: true,
            message: 'Bahan baku berhasil ditambahkan ke resep',
            data: {
                id: result.insertId,
                product_id: Number(productId),
                ingredient_id: Number(ingredient_id),
                quantity: Number(quantity)
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal menambahkan bahan ke resep'
        });
    }
};

// UPDATE KEBUTUHAN BAHAN
const updateProductIngredient = async (req, res) => {
    try {
        const { productId, ingredientId } = req.params;
        const { quantity } = req.body;

        if (
            quantity === undefined ||
            !Number.isFinite(Number(quantity)) ||
            Number(quantity) <= 0
        ) {
            return res.status(400).json({
                success: false,
                message: 'Jumlah kebutuhan harus lebih dari 0'
            });
        }

        const [result] = await db.promise().query(
            `UPDATE product_ingredients
             SET quantity = ?
             WHERE product_id = ? AND ingredient_id = ?`,
            [Number(quantity), productId, ingredientId]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: 'Resep bahan baku tidak ditemukan'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Kebutuhan bahan berhasil diperbarui'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal memperbarui resep'
        });
    }
};

// HAPUS BAHAN DARI RESEP
const deleteProductIngredient = async (req, res) => {
    try {
        const { productId, ingredientId } = req.params;

        const [result] = await db.promise().query(
            `DELETE FROM product_ingredients
             WHERE product_id = ? AND ingredient_id = ?`,
            [productId, ingredientId]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: 'Resep bahan baku tidak ditemukan'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Bahan berhasil dihapus dari resep'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal menghapus bahan dari resep'
        });
    }
};

module.exports = {
    getProductIngredients,
    addProductIngredient,
    updateProductIngredient,
    deleteProductIngredient
};
