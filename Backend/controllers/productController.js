
const db = require('../config/database');
const cloudinary = require('../config/cloudinary');

// FUNGSI UPLOAD GAMBAR KE CLOUDINARY
const uploadImage = (file) => {
    return new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
            {
                folder: 'dapurkita/products'
            },
            (error, result) => {
                if (error) {
                    reject(error);
                } else {
                    resolve(result.secure_url);
                }
            }
        );

        stream.end(file.buffer);
    });
};

// GET SEMUA PRODUK
const getProducts = async (req, res) => {
    try {
        const [products] = await db.promise().query(
            `SELECT products.*, categories.name AS category_name
             FROM products
             LEFT JOIN categories ON products.category_id = categories.id
             ORDER BY products.id DESC`
        );

        res.status(200).json({
            success: true,
            message: 'Daftar produk berhasil diambil',
            data: products
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil data produk'
        });
    }
};

// GET DETAIL PRODUK
const getProductById = async (req, res) => {
    try {
        const { id } = req.params;

        const [products] = await db.promise().query(
            `SELECT products.*, categories.name AS category_name
             FROM products
             LEFT JOIN categories ON products.category_id = categories.id
             WHERE products.id = ?`,
            [id]
        );

        if (products.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Produk tidak ditemukan'
            });
        }

        res.status(200).json({
            success: true,
            data: products[0]
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal mengambil detail produk'
        });
    }
};

// TAMBAH PRODUK
const createProduct = async (req, res) => {
    try {
        const {
            category_id,
            name,
            description,
            price,
            is_available
        } = req.body;

        if (!category_id || !name || !name.trim() || price === undefined || price === '') {
            return res.status(400).json({
                success: false,
                message: 'Kategori, nama, dan harga wajib diisi'
            });
        }

        if (!Number.isFinite(Number(price)) || Number(price) < 0) {
            return res.status(400).json({
                success: false,
                message: 'Harga harus berupa angka dan tidak boleh negatif'
            });
        }

        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: 'Gambar produk wajib diupload'
            });
        }

        const [categories] = await db.promise().query(
            'SELECT id FROM categories WHERE id = ?',
            [category_id]
        );

        if (categories.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Kategori tidak ditemukan'
            });
        }

        // Kalau Cloudinary menolak (kredensial salah, kuota, dsb), beri
        // pesan yang berbeda supaya tidak tampak seperti server mati.
        let imageUrl;

        try {
            imageUrl = await uploadImage(req.file);
        } catch (uploadError) {
            console.error(
                'Upload gambar ke Cloudinary gagal:',
                uploadError.message || uploadError
            );

            return res.status(502).json({
                success: false,
                message: 'Gagal mengunggah gambar ke Cloudinary. Periksa konfigurasi penyimpanan.'
            });
        }

        const [result] = await db.promise().query(
            `INSERT INTO products
             (category_id, name, description, price, image_url, is_available)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [
                category_id,
                name.trim(),
                description || null,
                Number(price),
                imageUrl,
                is_available === undefined ? 1 : Number(is_available)
            ]
        );

        res.status(201).json({
            success: true,
            message: 'Produk berhasil ditambahkan',
            data: {
                id: result.insertId,
                category_id,
                name: name.trim(),
                description: description || null,
                price: Number(price),
                image_url: imageUrl
            }
        });

    } catch (error) {
        console.error('createProduct gagal:', error.message || error);

        res.status(500).json({
            success: false,
            message: 'Gagal menambahkan produk'
        });
    }
};

// UPDATE PRODUK
const updateProduct = async (req, res) => {
    try {
        const { id } = req.params;

        const {
            category_id,
            name,
            description,
            price,
            is_available
        } = req.body;

        const [products] = await db.promise().query(
            'SELECT * FROM products WHERE id = ?',
            [id]
        );

        if (products.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Produk tidak ditemukan'
            });
        }

        if (!category_id || !name || !name.trim() || price === undefined || price === '') {
            return res.status(400).json({
                success: false,
                message: 'Kategori, nama, dan harga wajib diisi'
            });
        }

        if (!Number.isFinite(Number(price)) || Number(price) < 0) {
            return res.status(400).json({
                success: false,
                message: 'Harga harus berupa angka dan tidak boleh negatif'
            });
        }

        const [categories] = await db.promise().query(
            'SELECT id FROM categories WHERE id = ?',
            [category_id]
        );

        if (categories.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Kategori tidak ditemukan'
            });
        }

        let imageUrl = products[0].image_url;

        if (req.file) {
            try {
                imageUrl = await uploadImage(req.file);
            } catch (uploadError) {
                console.error(
                    'Upload gambar ke Cloudinary gagal:',
                    uploadError.message || uploadError
                );

                return res.status(502).json({
                    success: false,
                    message: 'Gagal mengunggah gambar ke Cloudinary. Periksa konfigurasi penyimpanan.'
                });
            }
        }

        await db.promise().query(
            `UPDATE products
             SET category_id = ?, name = ?, description = ?,
                 price = ?, image_url = ?, is_available = ?
             WHERE id = ?`,
            [
                category_id,
                name.trim(),
                description || null,
                Number(price),
                imageUrl,
                is_available === undefined
                    ? products[0].is_available
                    : Number(is_available),
                id
            ]
        );

        res.status(200).json({
            success: true,
            message: 'Produk berhasil diperbarui'
        });

    } catch (error) {
        console.error('updateProduct gagal:', error.message || error);

        res.status(500).json({
            success: false,
            message: 'Gagal memperbarui produk'
        });
    }
};

// DELETE PRODUK
const deleteProduct = async (req, res) => {
    try {
        const { id } = req.params;

        const [products] = await db.promise().query(
            'SELECT id FROM products WHERE id = ?',
            [id]
        );

        if (products.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Produk tidak ditemukan'
            });
        }

        const [orderItems] = await db.promise().query(
            'SELECT id FROM order_items WHERE product_id = ? LIMIT 1',
            [id]
        );

        if (orderItems.length > 0) {
            return res.status(409).json({
                success: false,
                message: 'Produk masih digunakan dalam pesanan'
            });
        }

        await db.promise().query(
            'DELETE FROM products WHERE id = ?',
            [id]
        );

        res.status(200).json({
            success: true,
            message: 'Produk berhasil dihapus'
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Gagal menghapus produk'
        });
    }
};

module.exports = {
    getProducts,
    getProductById,
    createProduct,
    updateProduct,
    deleteProduct
};
