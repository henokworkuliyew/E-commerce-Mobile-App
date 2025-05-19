const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');

// Initialize payment
router.post('/initialize', paymentController.initializePayment);

// Verify payment
router.get('/verify', paymentController.verifyPayment);

module.exports = router;