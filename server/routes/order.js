const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

// Create a new order
router.post('/', orderController.createOrder);

// Get all orders for a user
router.get('/:userId', orderController.getOrders);

module.exports = router;