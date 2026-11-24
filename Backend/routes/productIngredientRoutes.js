
const express = require('express');
const router = express.Router();

const {
    getProductIngredients,
    addProductIngredient,
    updateProductIngredient,
    deleteProductIngredient
} = require('../controllers/productIngredientController');

const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

// Semua pengaturan resep hanya untuk admin
router.use(authMiddleware, roleMiddleware('admin'));

router.get('/:productId', getProductIngredients);
router.post('/:productId', addProductIngredient);
router.put('/:productId/:ingredientId', updateProductIngredient);
router.delete('/:productId/:ingredientId', deleteProductIngredient);

module.exports = router;
