
const express = require('express');
const router = express.Router();

const {
    confirmTransfer,
    verifyPayment,
    getMyPayment
} = require('../controllers/paymentController');

const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

router.use(authMiddleware);

// Customer
router.post(
    '/:orderId/confirm-transfer',
    roleMiddleware('customer'),
    confirmTransfer
);

router.get(
    '/:orderId',
    roleMiddleware('customer'),
    getMyPayment
);

// Admin
router.put(
    '/:orderId/verify',
    roleMiddleware('admin'),
    verifyPayment
);

module.exports = router;
