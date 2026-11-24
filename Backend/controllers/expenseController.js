
const db = require('../config/database');

// GET SEMUA PENGELUARAN
const getExpenses = async (req, res) => {
    try {
        const [expenses] = await db.promise().query(
            `SELECT expenses.*, users.name AS admin_name
             FROM expenses
             JOIN users ON expenses.user_id = users.id
             ORDER BY expenses.expense_date DESC, expenses.id DESC`
        );

        res.status(200).json({
            success: true,
            message: 'Data pengeluaran berhasil diambil',
            data: expenses
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil data pengeluaran'
        });
    }
};

// TAMBAH PENGELUARAN MANUAL
const createExpense = async (req, res) => {
    try {
        const {
            title,
            category,
            amount,
            description,
            expense_date
        } = req.body;

        if (!title || !title.trim() || !category || !category.trim()) {
            return res.status(400).json({
                success: false,
                message: 'Nama dan kategori pengeluaran wajib diisi'
            });
        }

        if (
            amount === undefined ||
            !Number.isFinite(Number(amount)) ||
            Number(amount) <= 0
        ) {
            return res.status(400).json({
                success: false,
                message: 'Jumlah pengeluaran harus lebih dari 0'
            });
        }

        const [result] = await db.promise().query(
            `INSERT INTO expenses
             (user_id, title, category, amount, description, expense_date)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [
                req.user.id,
                title.trim(),
                category.trim(),
                Number(amount),
                description || null,
                expense_date || new Date().toISOString().slice(0, 10)
            ]
        );

        res.status(201).json({
            success: true,
            message: 'Pengeluaran berhasil dicatat',
            data: {
                id: result.insertId,
                title: title.trim(),
                category: category.trim(),
                amount: Number(amount)
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mencatat pengeluaran'
        });
    }
};

// DELETE PENGELUARAN MANUAL
const deleteExpense = async (req, res) => {
    try {
        const { id } = req.params;

        // Pengeluaran pembelian tidak boleh dihapus dari sini
        const [expenses] = await db.promise().query(
            'SELECT id, purchase_id FROM expenses WHERE id = ?',
            [id]
        );

        if (expenses.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Pengeluaran tidak ditemukan'
            });
        }

        if (expenses[0].purchase_id !== null) {
            return res.status(409).json({
                success: false,
                message: 'Pengeluaran pembelian harus dikelola melalui data pembelian'
            });
        }

        await db.promise().query(
            'DELETE FROM expenses WHERE id = ?',
            [id]
        );

        res.status(200).json({
            success: true,
            message: 'Pengeluaran berhasil dihapus'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal menghapus pengeluaran'
        });
    }
};

module.exports = {
    getExpenses,
    createExpense,
    deleteExpense
};
