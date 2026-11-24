
const db = require('../config/database');

// CUSTOMER KONFIRMASI SUDAH TRANSFER
const confirmTransfer = async (req, res) => {
    try {
        const { orderId } = req.params;

        const [orders] = await db.promise().query(
            `SELECT orders.id, orders.user_id, payments.payment_method,
                    payments.payment_status
             FROM orders
             JOIN payments ON orders.id = payments.order_id
             WHERE orders.id = ? AND orders.user_id = ?`,
            [orderId, req.user.id]
        );

        if (orders.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Pesanan tidak ditemukan'
            });
        }

        const payment = orders[0];

        if (payment.payment_method !== 'transfer') {
            return res.status(400).json({
                success: false,
                message: 'Pesanan ini menggunakan pembayaran tunai'
            });
        }

        if (!['pending', 'rejected'].includes(payment.payment_status)) {
            return res.status(400).json({
                success: false,
                message: 'Konfirmasi transfer tidak dapat dilakukan lagi'
            });
        }

        await db.promise().query(
            `UPDATE payments
             SET payment_status = 'awaiting_verification'
             WHERE order_id = ?`,
            [orderId]
        );

        res.status(200).json({
            success: true,
            message: 'Konfirmasi transfer berhasil dikirim. Menunggu pemeriksaan admin.'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengirim konfirmasi transfer'
        });
    }
};

// ADMIN VERIFIKASI PEMBAYARAN
const verifyPayment = async (req, res) => {
    try {
        const { orderId } = req.params;
        const { payment_status } = req.body;

        if (!['paid', 'rejected'].includes(payment_status)) {
            return res.status(400).json({
                success: false,
                message: 'Status pembayaran tidak valid'
            });
        }

        const [payments] = await db.promise().query(
            'SELECT * FROM payments WHERE order_id = ?',
            [orderId]
        );

        if (payments.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Data pembayaran tidak ditemukan'
            });
        }

        const payment = payments[0];

        if (payment.payment_status === 'paid') {
            return res.status(400).json({
                success: false,
                message: 'Pembayaran sudah dinyatakan lunas'
            });
        }

        if (
            payment.payment_method === 'transfer' &&
            payment.payment_status !== 'awaiting_verification'
        ) {
            return res.status(400).json({
                success: false,
                message: 'Customer belum mengirim konfirmasi transfer'
            });
        }

        await db.promise().query(
            `UPDATE payments
             SET payment_status = ?,
                 paid_at = ?
             WHERE order_id = ?`,
            [
                payment_status,
                payment_status === 'paid' ? new Date() : null,
                orderId
            ]
        );

        res.status(200).json({
            success: true,
            message: payment_status === 'paid'
                ? 'Pembayaran berhasil diverifikasi'
                : 'Pembayaran ditolak',
            data: {
                order_id: Number(orderId),
                payment_status: payment_status
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal memproses pembayaran'
        });
    }
};

// CUSTOMER MELIHAT STATUS PEMBAYARAN
const getMyPayment = async (req, res) => {
    try {
        const { orderId } = req.params;

        const [payments] = await db.promise().query(
            `SELECT payments.*
             FROM payments
             JOIN orders ON payments.order_id = orders.id
             WHERE payments.order_id = ? AND orders.user_id = ?`,
            [orderId, req.user.id]
        );

        if (payments.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Pembayaran tidak ditemukan'
            });
        }

        res.status(200).json({
            success: true,
            data: payments[0]
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil status pembayaran'
        });
    }
};

module.exports = {
    confirmTransfer,
    verifyPayment,
    getMyPayment
};
