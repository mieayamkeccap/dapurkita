
const db = require('../config/database');

// Ongkir untuk pesanan yang diantar. Dipakai juga oleh layar checkout
// di frontend supaya total yang terlihat sama dengan yang tersimpan.
const ONGKIR = 5000;

// MEMBUAT PESANAN CUSTOMER
const createOrder = async (req, res) => {
    const connection = db.promise();
    let transactionStarted = false;

    try {
        const {
            items,
            delivery_method,
            order_type,
            scheduled_at,
            recipient_name,
            recipient_phone,
            delivery_address,
            notes,
            payment_method
        } = req.body;

        if (!Array.isArray(items) || items.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Pesanan harus memiliki minimal satu produk'
            });
        }

        if (!['pickup', 'delivery'].includes(delivery_method)) {
            return res.status(400).json({
                success: false,
                message: 'Metode pengambilan tidak valid'
            });
        }

        if (!['asap', 'scheduled'].includes(order_type)) {
            return res.status(400).json({
                success: false,
                message: 'Jenis waktu pesanan tidak valid'
            });
        }

        // Pembayaran hanya tersedia lewat transfer bank.
        if (payment_method !== 'transfer') {
            return res.status(400).json({
                success: false,
                message: 'Metode pembayaran yang tersedia hanya transfer'
            });
        }

        if (!recipient_name || !recipient_phone) {
            return res.status(400).json({
                success: false,
                message: 'Nama dan nomor telepon penerima wajib diisi'
            });
        }

        if (delivery_method === 'delivery' && !delivery_address) {
            return res.status(400).json({
                success: false,
                message: 'Alamat pengantaran wajib diisi'
            });
        }

        if (order_type === 'scheduled' && !scheduled_at) {
            return res.status(400).json({
                success: false,
                message: 'Tanggal dan waktu pesanan wajib diisi'
            });
        }

        for (const item of items) {
            if (
                !item.product_id ||
                !Number.isInteger(Number(item.quantity)) ||
                Number(item.quantity) <= 0
            ) {
                return res.status(400).json({
                    success: false,
                    message: 'Produk dan jumlah pesanan tidak valid'
                });
            }
        }

        await connection.beginTransaction();
        transactionStarted = true;

        let subtotal = 0;
        const orderItems = [];

        // Periksa produk dan ambil harga dari database
        for (const item of items) {
            const [products] = await connection.query(
                `SELECT id, name, price
                 FROM products
                 WHERE id = ? AND is_available = 1
                 FOR UPDATE`,
                [item.product_id]
            );

            if (products.length === 0) {
                throw new Error(`Produk ID ${item.product_id} tidak tersedia`);
            }

            const product = products[0];
            const quantity = Number(item.quantity);
            const price = Number(product.price);
            const itemSubtotal = price * quantity;

            subtotal += itemSubtotal;

            orderItems.push({
                product_id: product.id,
                product_name: product.name,
                quantity: quantity,
                price: price,
                subtotal: itemSubtotal
            });
        }

        // Ongkir hanya untuk pengantaran; ambil sendiri tidak kena ongkir.
        const deliveryFee = delivery_method === 'delivery' ? ONGKIR : 0;
        const totalAmount = subtotal + deliveryFee;

        // Buat kode pesanan
        const orderCode =
            'DK-' + Date.now() + '-' + Math.floor(Math.random() * 1000);

        // Simpan pesanan utama
        const [orderResult] = await connection.query(
            `INSERT INTO orders (
                user_id,
                order_code,
                delivery_method,
                order_type,
                scheduled_at,
                recipient_name,
                recipient_phone,
                delivery_address,
                notes,
                subtotal,
                delivery_fee,
                total_amount,
                order_status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')`,
            [
                req.user.id,
                orderCode,
                delivery_method,
                order_type,
                order_type === 'scheduled' ? scheduled_at : null,
                recipient_name,
                recipient_phone,
                delivery_method === 'delivery' ? delivery_address : null,
                notes || null,
                subtotal,
                deliveryFee,
                totalAmount
            ]
        );

        const orderId = orderResult.insertId;

        // Simpan detail produk pesanan
        for (const item of orderItems) {
            await connection.query(
                `INSERT INTO order_items (
                    order_id,
                    product_id,
                    product_name,
                    quantity,
                    price,
                    subtotal
                ) VALUES (?, ?, ?, ?, ?, ?)`,
                [
                    orderId,
                    item.product_id,
                    item.product_name,
                    item.quantity,
                    item.price,
                    item.subtotal
                ]
            );
        }

        // Pembayaran transfer dicatat lunas saat pesanan dibuat, supaya
        // uang dianggap masuk sebesar total pesanan (makanan + ongkir).
        await connection.query(
            `INSERT INTO payments (
                order_id,
                payment_method,
                payment_status,
                paid_at
            ) VALUES (?, ?, 'paid', NOW())`,
            [orderId, payment_method]
        );

        await connection.commit();
        transactionStarted = false;

        res.status(201).json({
            success: true,
            message: 'Pesanan berhasil dibuat',
            data: {
                order_id: orderId,
                order_code: orderCode,
                subtotal: subtotal,
                delivery_fee: deliveryFee,
                total_amount: totalAmount,
                order_status: 'pending',
                payment_method: payment_method,
                payment_status: 'paid'
            }
        });

    } catch (error) {
        if (transactionStarted) {
            await connection.rollback();
        }

        res.status(400).json({
            success: false,
            message: error.message || 'Gagal membuat pesanan'
        });
    }
};


// MELIHAT PESANAN MILIK CUSTOMER
const getMyOrders = async (req, res) => {
    try {
        const [orders] = await db.promise().query(
            `SELECT
                orders.*,
                payments.payment_method,
                payments.payment_status
             FROM orders
             LEFT JOIN payments ON orders.id = payments.order_id
             WHERE orders.user_id = ?
             ORDER BY orders.id DESC`,
            [req.user.id]
        );

        res.status(200).json({
            success: true,
            message: 'Riwayat pesanan berhasil diambil',
            data: orders
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil riwayat pesanan'
        });
    }
};


// MELIHAT SEMUA PESANAN ADMIN
const getAllOrders = async (req, res) => {
    try {
        const [orders] = await db.promise().query(
            `SELECT
                orders.*,
                users.name AS customer_name,
                payments.payment_method,
                payments.payment_status
             FROM orders
             JOIN users ON orders.user_id = users.id
             LEFT JOIN payments ON orders.id = payments.order_id
             ORDER BY orders.id DESC`
        );

        res.status(200).json({
            success: true,
            message: 'Semua pesanan berhasil diambil',
            data: orders
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil semua pesanan'
        });
    }
};


// MELIHAT DETAIL PESANAN
const getOrderById = async (req, res) => {
    try {
        const { id } = req.params;

        let query = `
            SELECT
                orders.*,
                payments.payment_method,
                payments.payment_status,
                payments.paid_at
            FROM orders
            LEFT JOIN payments ON orders.id = payments.order_id
            WHERE orders.id = ?
        `;

        const params = [id];

        // Customer hanya boleh melihat pesanannya sendiri
        if (req.user.role === 'customer') {
            query += ' AND orders.user_id = ?';
            params.push(req.user.id);
        }

        const [orders] = await db.promise().query(query, params);

        if (orders.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Pesanan tidak ditemukan'
            });
        }

        const [items] = await db.promise().query(
            'SELECT * FROM order_items WHERE order_id = ?',
            [id]
        );

        res.status(200).json({
            success: true,
            data: {
                ...orders[0],
                items: items
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil detail pesanan'
        });
    }
};


// UPDATE STATUS PESANAN ADMIN
const updateOrderStatus = async (req, res) => {
    const connection = db.promise();
    let transactionStarted = false;

    try {
        const { id } = req.params;
        const { order_status } = req.body;

        const allowedStatuses = [
            'confirmed',
            'preparing',
            'ready',
            'on_delivery',
            'completed',
            'cancelled'
        ];

        if (!allowedStatuses.includes(order_status)) {
            return res.status(400).json({
                success: false,
                message: 'Status pesanan tidak valid'
            });
        }

        await connection.beginTransaction();
        transactionStarted = true;

        const [orders] = await connection.query(
            'SELECT * FROM orders WHERE id = ? FOR UPDATE',
            [id]
        );

        if (orders.length === 0) {
            await connection.rollback();
            transactionStarted = false;

            return res.status(404).json({
                success: false,
                message: 'Pesanan tidak ditemukan'
            });
        }

        const order = orders[0];

        const allowedTransitions = {
            pending: ['confirmed', 'cancelled'],
            confirmed: ['preparing', 'cancelled'],
            preparing: ['ready'],
            ready: ['on_delivery', 'completed'],
            on_delivery: ['completed'],
            completed: [],
            cancelled: []
        };

        if (!allowedTransitions[order.order_status].includes(order_status)) {
            await connection.rollback();
            transactionStarted = false;

            return res.status(400).json({
                success: false,
                message: 'Perubahan status pesanan tidak diperbolehkan'
            });
        }

        if (
            order_status === 'on_delivery' &&
            order.delivery_method !== 'delivery'
        ) {
            await connection.rollback();
            transactionStarted = false;

            return res.status(400).json({
                success: false,
                message: 'Pesanan pickup tidak memerlukan status pengantaran'
            });
        }

        if (
            order_status === 'completed' &&
            order.delivery_method === 'delivery' &&
            order.order_status !== 'on_delivery'
        ) {
            await connection.rollback();
            transactionStarted = false;

            return res.status(400).json({
                success: false,
                message: 'Pesanan delivery harus dalam status pengantaran terlebih dahulu'
            });
        }

        // Simpan status pesanan.
        // Stok bahan tidak dipotong di sini: tidak ada logika pengurangan
        // stok dari aplikasi.
        await connection.query(
            'UPDATE orders SET order_status = ? WHERE id = ?',
            [order_status, id]
        );

        await connection.commit();
        transactionStarted = false;

        res.status(200).json({
            success: true,
            message: 'Status pesanan berhasil diperbarui',
            data: {
                order_id: Number(id),
                previous_status: order.order_status,
                order_status: order_status
            }
        });

    } catch (error) {
        if (transactionStarted) {
            await connection.rollback();
        }

        res.status(400).json({
            success: false,
            message: error.message || 'Gagal memperbarui status pesanan'
        });
    }
};


// CUSTOMER MENANDAI PESANANNYA SELESAI
// Dipisah dari updateOrderStatus supaya aturan admin tidak berubah dan
// customer hanya bisa menyelesaikan pesanannya sendiri.
const completeOrderByCustomer = async (req, res) => {
    const connection = db.promise();
    let transactionStarted = false;

    try {
        const { id } = req.params;

        await connection.beginTransaction();
        transactionStarted = true;

        const [orders] = await connection.query(
            'SELECT * FROM orders WHERE id = ? AND user_id = ? FOR UPDATE',
            [id, req.user.id]
        );

        if (orders.length === 0) {
            await connection.rollback();
            transactionStarted = false;

            return res.status(404).json({
                success: false,
                message: 'Pesanan tidak ditemukan'
            });
        }

        const order = orders[0];

        // Pesanan belum boleh diselesaikan sebelum admin mengonfirmasi.
        if (order.order_status === 'pending') {
            await connection.rollback();
            transactionStarted = false;

            return res.status(400).json({
                success: false,
                message: 'Pesanan belum dikonfirmasi admin'
            });
        }

        const bolehSelesai = [
            'confirmed',
            'preparing',
            'ready',
            'on_delivery'
        ];

        if (!bolehSelesai.includes(order.order_status)) {
            await connection.rollback();
            transactionStarted = false;

            return res.status(400).json({
                success: false,
                message: 'Status pesanan ini sudah final'
            });
        }

        await connection.query(
            'UPDATE orders SET order_status = ? WHERE id = ?',
            ['completed', id]
        );

        await connection.commit();
        transactionStarted = false;

        res.status(200).json({
            success: true,
            message: 'Pesanan ditandai selesai',
            data: {
                order_id: Number(id),
                previous_status: order.order_status,
                order_status: 'completed'
            }
        });

    } catch (error) {
        if (transactionStarted) {
            await connection.rollback();
        }

        res.status(400).json({
            success: false,
            message: error.message || 'Gagal menandai pesanan selesai'
        });
    }
};


module.exports = {
    createOrder,
    getMyOrders,
    getAllOrders,
    getOrderById,
    updateOrderStatus,
    completeOrderByCustomer
};
