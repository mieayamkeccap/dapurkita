
const express = require('express');
const router = express.Router();

const {
    getProducts,
    getProductById,
    createProduct,
    updateProduct,
    deleteProduct
} = require('../controllers/productController');

const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');
const upload = require('../middleware/uploadMiddleware');

// Public: semua pengguna bisa melihat produk
router.get('/', getProducts);
router.get('/:id', getProductById);

// Admin only
router.post(
    '/',
    authMiddleware,
    roleMiddleware('admin'),
    upload.single('image'),
    createProduct
);

router.put(
    '/:id',
    authMiddleware,
    roleMiddleware('admin'),
    upload.single('image'),
    updateProduct
);

router.delete(
    '/:id',
    authMiddleware,
    roleMiddleware('admin'),
    deleteProduct
);

module.exports = router;
