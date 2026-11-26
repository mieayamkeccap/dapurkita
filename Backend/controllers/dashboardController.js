
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

// Nama hari dipakai sebagai label sumbu grafik. Urutannya mengikuti
// getDay() JavaScript (Minggu = 0).
const namaHari = [
    'Minggu',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu'
];

// Daftar tanggal [jumlahHari] hari terakhir, urut dari paling lama sampai
// hari ini. Dipakai grafik dashboard dan grafik penjualan per produk supaya
// keduanya punya sumbu hari yang sama.
const daftarHariTerakhir = (jumlahHari) => {
    const data = [];
    const hariIni = new Date();
    hariIni.setHours(0, 0, 0, 0);

    for (let i = jumlahHari - 1; i >= 0; i--) {
        const tanggal = new Date(hariIni);
        tanggal.setDate(hariIni.getDate() - i);

        const tahun = tanggal.getFullYear();
        const bulan = String(tanggal.getMonth() + 1).padStart(2, '0');
        const tanggalAngka = String(tanggal.getDate()).padStart(2, '0');

        data.push({
            tanggal: `${tahun}-${bulan}-${tanggalAngka}`,
            hari: namaHari[tanggal.getDay()]
        });
    }

    return data;
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

        const data = daftarHariTerakhir(7).map((item) => {
            return {
                tanggal: item.tanggal,
                hari: item.hari,
                jumlah: jumlahPerTanggal[item.tanggal] || 0
            };
        });

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

// Mengambil jumlah unit terjual per produk per hari untuk 7 hari terakhir.
// Produk yang belum pernah terjual tetap ikut (LEFT JOIN dari products),
// jadi setiap menu baru langsung punya grafik sendiri walaupun masih nol.
const getProductSales = async (req, res) => {
    try {
        const connection = db.promise();

        // Syarat tanggal dan status sengaja ada di klausa ON, bukan WHERE:
        // kalau di WHERE, produk tanpa penjualan akan terbuang oleh LEFT JOIN
        // dan grafiknya hilang.
        const [rows] = await connection.query(`
            SELECT
                categories.id AS category_id,
                categories.name AS category_name,
                products.id AS product_id,
                products.name AS product_name,
                DATE_FORMAT(orders.created_at, '%Y-%m-%d') AS tanggal,
                SUM(order_items.quantity) AS jumlah
            FROM products
            JOIN categories ON categories.id = products.category_id
            LEFT JOIN order_items ON order_items.product_id = products.id
            LEFT JOIN orders ON orders.id = order_items.order_id
                 AND orders.created_at >= CURDATE() - INTERVAL 6 DAY
                 AND orders.order_status <> 'cancelled'
            GROUP BY
                categories.id,
                categories.name,
                products.id,
                products.name,
                tanggal
            ORDER BY categories.name, products.name, tanggal
        `);

        const hari = daftarHariTerakhir(7);

        // Susun hasil pipih (kategori + produk + tanggal) menjadi
        // kategori -> daftar produk -> daftar harian.
        const kategori = new Map();

        for (const row of rows) {
            if (!kategori.has(row.category_id)) {
                kategori.set(row.category_id, {
                    category_id: row.category_id,
                    category_name: row.category_name,
                    products: new Map()
                });
            }

            const daftarProduk = kategori.get(row.category_id).products;

            if (!daftarProduk.has(row.product_id)) {
                daftarProduk.set(row.product_id, {
                    product_id: row.product_id,
                    product_name: row.product_name,
                    total: 0,
                    harian: {}
                });
            }

            const produk = daftarProduk.get(row.product_id);

            if (row.tanggal) {
                produk.harian[row.tanggal] = Number(row.jumlah);
                produk.total += Number(row.jumlah);
            }
        }

        const data = [];

        for (const isiKategori of kategori.values()) {
            const daftarProduk = [];

            for (const produk of isiKategori.products.values()) {
                daftarProduk.push({
                    product_id: produk.product_id,
                    product_name: produk.product_name,
                    total: produk.total,
                    // Semua produk memakai 7 tanggal yang sama supaya batang
                    // grafiknya sejajar.
                    harian: hari.map((item) => {
                        return {
                            tanggal: item.tanggal,
                            hari: item.hari,
                            jumlah: produk.harian[item.tanggal] || 0
                        };
                    })
                });
            }

            data.push({
                category_id: isiKategori.category_id,
                category_name: isiKategori.category_name,
                products: daftarProduk
            });
        }

        res.status(200).json({
            success: true,
            message: 'Penjualan per produk berhasil diambil',
            data: data
        });

    } catch (error) {
        console.error('getProductSales gagal:', error.message || error);

        res.status(500).json({
            success: false,
            message: 'Gagal mengambil penjualan per produk'
        });
    }
};

module.exports = {
    getSummary,
    getDailyOrders,
    getTopProducts,
    getProductSales
};
