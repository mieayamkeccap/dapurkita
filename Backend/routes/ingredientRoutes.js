
const express = require('express');
const router = express.Router();

const {
    getIngredients,
    getIngredientById,
    createIngredient,
    updateIngredient,
    deleteIngredient,
    getLowStockIngredients
} = require('../controllers/ingredientController');

const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

// Semua endpoint bahan baku khusus admin
router.use(authMiddleware, roleMiddleware('admin'));

router.get('/low-stock', getLowStockIngredients);
router.get('/', getIngredients);
router.get('/:id', getIngredientById);
router.post('/', createIngredient);
router.put('/:id', updateIngredient);
router.delete('/:id', deleteIngredient);

module.exports = router;
