const express = require('express');
const router = express.Router();

const {
    getAddresses,
    createAddress,
    updateAddress,
    deleteAddress,
    setPrimaryAddress
} = require('../controllers/addressController');

const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

// Semua route butuh login dan hanya untuk customer.
// Admin tidak berbelanja, jadi tidak punya alamat pengiriman.
router.use(authMiddleware, roleMiddleware('customer'));

router.get('/', getAddresses);
router.post('/', createAddress);
router.put('/:id/utama', setPrimaryAddress);
router.put('/:id', updateAddress);
router.delete('/:id', deleteAddress);

module.exports = router;
