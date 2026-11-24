
const express = require('express');
const router = express.Router();

const {
    getPurchases,
    getPurchaseById,
    createPurchase
} = require('../controllers/purchaseController');

const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

router.use(authMiddleware, roleMiddleware('admin'));

router.get('/', getPurchases);
router.get('/:id', getPurchaseById);
router.post('/', createPurchase);

module.exports = router;
