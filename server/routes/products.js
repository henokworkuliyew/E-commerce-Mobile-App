const express = require('express');
const router = express.Router();
const { createProduct, getProducts } = require('../controllers/productController');
const { validateProduct } = require('../middleware/validate');

router.post('/', validateProduct, createProduct);
router.get('/', getProducts);

module.exports = router;