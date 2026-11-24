
const db = require('../config/database');

// GET RIWAYAT PEMBELIAN
const getPurchases = async (req, res) => {
    try {
        const [purchases] = await db.promise().query(
            `SELECT ingredient_purchases.*, users.name AS admin_name
             FROM ingredient_purchases
             JOIN users ON ingredient_purchases.user_id = users.id
             ORDER BY ingredient_purchases.id DESC`
        );

        res.status(200).json({
            success: true,
            message: 'Riwayat pembelian berhasil diambil',
            data: purchases
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil riwayat pembelian'
        });
    }
};

// GET DETAIL PEMBELIAN
const getPurchaseById = async (req, res) => {
    try {
        const { id } = req.params;

        const [purchases] = await db.promise().query(
            `SELECT * FROM ingredient_purchases WHERE id = ?`,
            [id]
        );

        if (purchases.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Pembelian tidak ditemukan'
            });
        }

        const [items] = await db.promise().query(
            `SELECT
                ingredient_purchase_items.*,
                ingredients.name AS ingredient_name,
                ingredients.unit
             FROM ingredient_purchase_items
             JOIN ingredients
                ON ingredient_purchase_items.ingredient_id = ingredients.id
             WHERE ingredient_purchase_items.purchase_id = ?`,
            [id]
        );

        res.status(200).json({
            success: true,
            message: 'Detail pembelian berhasil diambil',
            data: {
                ...purchases[0],
                items: items
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil detail pembelian'
        });
    }
};

// TAMBAH PEMBELIAN BAHAN BAKU
const createPurchase = async (req, res) => {
    const connection = db.promise();

    try {
        const {
            supplier_name,
            purchase_date,
            notes,
            items
        } = req.body;

        if (!Array.isArray(items) || items.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Minimal harus ada satu bahan yang dibeli'
            });
        }

        for (const item of items) {
            if (
                !item.ingredient_id ||
                !Number.isFinite(Number(item.quantity)) ||
                Number(item.quantity) <= 0 ||
                !Number.isFinite(Number(item.unit_cost)) ||
                Number(item.unit_cost) < 0
            ) {
                return res.status(400).json({
                    success: false,
                    message: 'Data bahan, jumlah, atau harga tidak valid'
                });
            }
        }

        await connection.beginTransaction();

        let totalAmount = 0;

        // Periksa bahan dan hitung total pembelian
        for (const item of items) {
            const [ingredients] = await connection.query(
                'SELECT id FROM ingredients WHERE id = ? FOR UPDATE',
                [item.ingredient_id]
            );

            if (ingredients.length === 0) {
                throw new Error(`Bahan baku ID ${item.ingredient_id} tidak ditemukan`);
            }

            const subtotal = Number(item.quantity) * Number(item.unit_cost);
            totalAmount += subtotal;
        }

        // Simpan data pembelian
        const [purchaseResult] = await connection.query(
            `INSERT INTO ingredient_purchases
             (user_id, supplier_name, purchase_date, total_amount, notes)
             VALUES (?, ?, ?, ?, ?)`,
            [
                req.user.id,
                supplier_name || null,
                purchase_date || new Date().toISOString().slice(0, 10),
                totalAmount,
                notes || null
            ]
        );

        const purchaseId = purchaseResult.insertId;

        // Simpan detail dan tambahkan stok
        for (const item of items) {
            const quantity = Number(item.quantity);
            const unitCost = Number(item.unit_cost);
            const subtotal = quantity * unitCost;

            await connection.query(
                `INSERT INTO ingredient_purchase_items
                 (purchase_id, ingredient_id, quantity, unit_cost, subtotal)
                 VALUES (?, ?, ?, ?, ?)`,
                [
                    purchaseId,
                    item.ingredient_id,
                    quantity,
                    unitCost,
                    subtotal
                ]
            );

            await connection.query(
                `UPDATE ingredients
                 SET stock = stock + ?
                 WHERE id = ?`,
                [quantity, item.ingredient_id]
            );
        }

        // Catat pembelian sebagai pengeluaran
        await connection.query(
            `INSERT INTO expenses
             (user_id, purchase_id, title, category, amount, description, expense_date)
             VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [
                req.user.id,
                purchaseId,
                'Pembelian bahan baku',
                'Bahan Baku',
                totalAmount,
                supplier_name
                    ? `Pembelian dari ${supplier_name}`
                    : 'Pembelian bahan baku',
                purchase_date || new Date().toISOString().slice(0, 10)
            ]
        );

        await connection.commit();

        res.status(201).json({
            success: true,
            message: 'Pembelian berhasil dicatat dan stok berhasil ditambahkan',
            data: {
                purchase_id: purchaseId,
                total_amount: totalAmount
            }
        });

    } catch (error) {
        await connection.rollback();

        res.status(500).json({
            success: false,
            message: error.message || 'Gagal mencatat pembelian'
        });
    }
};

module.exports = {
    getPurchases,
    getPurchaseById,
    createPurchase
};
