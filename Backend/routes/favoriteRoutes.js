const express = require('express');
const router = express.Router();

const {
    getFavorites,
    getFavoriteIds,
    addFavorite,
    removeFavorite
} = require('../controllers/favoriteController');

const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

// Semua route butuh login dan hanya untuk customer.
router.use(authMiddleware, roleMiddleware('customer'));

// /ids harus didaftarkan sebelum /:productId supaya tidak tertangkap
// sebagai id produk bernama "ids".
router.get('/ids', getFavoriteIds);
router.get('/', getFavorites);
router.post('/:productId', addFavorite);
router.delete('/:productId', removeFavorite);

module.exports = router;
