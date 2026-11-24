
const express = require('express');
const router = express.Router();

const {
    createOrder,
    getMyOrders,
    getAllOrders,
    getOrderById,
    updateOrderStatus,
    completeOrderByCustomer
} = require('../controllers/orderController');

const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

// Semua route pesanan harus login
router.use(authMiddleware);

// Customer
router.post('/', roleMiddleware('customer'), createOrder);
router.get('/my-orders', roleMiddleware('customer'), getMyOrders);
router.put(
    '/:id/selesai',
    roleMiddleware('customer'),
    completeOrderByCustomer
);

// Admin
router.get('/', roleMiddleware('admin'), getAllOrders);
router.put('/:id/status', roleMiddleware('admin'), updateOrderStatus);

// Customer dan admin bisa melihat detail
router.get('/:id', getOrderById);

module.exports = router;
