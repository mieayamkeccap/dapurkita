
const db = require('../config/database');

// Mengambil ringkasan dashboard
const getSummary = async (req, res) => {
    try {
        const connection = db.promise();

        // Menghitung jumlah pesanan berdasarkan status
        const [orderData] = await connection.query(`
            SELECT
                COUNT(*) AS total_orders,
                SUM(order_status = 'pending') AS pending_orders,
                SUM(order_status = 'preparing') AS preparing_orders,
                SUM(order_status = 'completed') AS completed_orders
            FROM orders
        `);

        // Menghitung pendapatan dari semua pesanan yang tidak dibatalkan.
        // Uang dianggap masuk saat pesanan dibuat (transfer langsung lunas),
        // jadi tidak lagi difilter lewat payments.payment_status.
        const [revenueData] = await connection.query(`
            SELECT COALESCE(SUM(total_amount), 0) AS total_revenue
            FROM orders
            WHERE order_status <> 'cancelled'
        `);

        const totalRevenue = Number(revenueData[0].total_revenue);

        res.status(200).json({
            success: true,
            message: 'Ringkasan dashboard berhasil diambil',
            data: {
                total_orders: Number(orderData[0].total_orders),
                pending_orders: Number(orderData[0].pending_orders || 0),
                preparing_orders: Number(orderData[0].preparing_orders || 0),
                completed_orders: Number(orderData[0].completed_orders || 0),
                total_revenue: totalRevenue
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil ringkasan dashboard'
        });
    }
};

// Mengambil jumlah pesanan per hari untuk 7 hari terakhir.
// Dipakai grafik dashboard supaya angkanya berasal dari tabel orders,
// bukan data contoh.
const getDailyOrders = async (req, res) => {
    try {
        const connection = db.promise();

        // created_at bertipe TIMESTAMP; MySQL mengonversinya ke zona waktu
        // server (WIB), jadi DATE_FORMAT menghasilkan tanggal lokal.
        // Pesanan batal tidak dihitung, sama seperti produk terlaris.
        const [rows] = await connection.query(`
            SELECT
                DATE_FORMAT(created_at, '%Y-%m-%d') AS tanggal,
                COUNT(*) AS jumlah
            FROM orders
            WHERE created_at >= CURDATE() - INTERVAL 6 DAY
              AND order_status <> 'cancelled'
            GROUP BY tanggal
        `);

        const jumlahPerTanggal = {};

        for (const row of rows) {
            jumlahPerTanggal[row.tanggal] = Number(row.jumlah);
        }

        const namaHari = [
            'Minggu',
            'Senin',
            'Selasa',
            'Rabu',
            'Kamis',
            'Jumat',
            'Sabtu'
        ];

        const data = [];
        const hariIni = new Date();
        hariIni.setHours(0, 0, 0, 0);

        // Urut dari 6 hari lalu sampai hari ini (7 hari).
        for (let i = 6; i >= 0; i--) {
            const tanggal = new Date(hariIni);
            tanggal.setDate(hariIni.getDate() - i);

            const tahun = tanggal.getFullYear();
            const bulan = String(tanggal.getMonth() + 1).padStart(2, '0');
            const tanggalAngka = String(tanggal.getDate()).padStart(2, '0');
            const kunci = `${tahun}-${bulan}-${tanggalAngka}`;

            data.push({
                tanggal: kunci,
                hari: namaHari[tanggal.getDay()],
                jumlah: jumlahPerTanggal[kunci] || 0
            });
        }

        res.status(200).json({
            success: true,
            message: 'Data grafik penjualan berhasil diambil',
            data: data
        });

    } catch (error) {
        console.error('getDailyOrders gagal:', error.message || error);

        res.status(500).json({
            success: false,
            message: 'Gagal mengambil data grafik penjualan'
        });
    }
};

// Mengambil produk paling banyak dipesan
const getTopProducts = async (req, res) => {
    try {
        const [products] = await db.promise().query(`
            SELECT
                product_id,
                product_name,
                SUM(quantity) AS total_sold
            FROM order_items
            JOIN orders ON order_items.order_id = orders.id
            WHERE orders.order_status != 'cancelled'
            GROUP BY product_id, product_name
            ORDER BY total_sold DESC
            LIMIT 5
        `);

        res.status(200).json({
            success: true,
            message: 'Produk terlaris berhasil diambil',
            data: products
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil produk terlaris'
        });
    }
};

module.exports = {
    getSummary,
    getDailyOrders,
    getTopProducts
};
