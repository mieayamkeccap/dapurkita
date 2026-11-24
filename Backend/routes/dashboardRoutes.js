
const express = require('express');
const router = express.Router();

const {
    getSummary,
    getDailyOrders,
    getLowStock,
    getTopProducts
} = require('../controllers/dashboardController');

const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

// Semua endpoint dashboard hanya untuk admin
router.use(authMiddleware);
router.use(roleMiddleware('admin'));

router.get('/summary', getSummary);
router.get('/daily-orders', getDailyOrders);
router.get('/low-stock', getLowStock);
router.get('/top-products', getTopProducts);

module.exports = router;
