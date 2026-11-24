
const express = require('express');
const router = express.Router();

const {
    getExpenses,
    createExpense,
    deleteExpense
} = require('../controllers/expenseController');

const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

router.use(authMiddleware, roleMiddleware('admin'));

router.get('/', getExpenses);
router.post('/', createExpense);
router.delete('/:id', deleteExpense);

module.exports = router;
