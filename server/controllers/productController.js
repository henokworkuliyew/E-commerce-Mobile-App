const Product = require('../models/Product');

const createProduct = async (req, res) => {
  try {
    const { name, description, price, brand, category, inStock, images, reviews } = req.body;
    const product = new Product({
      name,
      description,
      price,
      brand,
      category,
      inStock,
      images,
      reviews
    });
    await product.save();
    res.status(201).json({
      message: 'Product created successfully',
      product: {
        id: product._id,
        name: product.name,
        description: product.description,
        price: product.price,
        brand: product.brand,
        category: product.category,
        inStock: product.inStock,
        images: product.images,
        reviews: product.reviews
      }
    });
  } catch (error) {
    console.error('Product creation error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

const getProducts = async (req, res) => {
  try {
    const products = await Product.find();
    res.status(200).json({
      message: 'Products fetched successfully',
      products: products.map(product => ({
        id: product._id,
        name: product.name,
        description: product.description,
        price: product.price,
        brand: product.brand,
        category: product.category,
        inStock: product.inStock,
        images: product.images,
        reviews: product.reviews
      }))
    });
  } catch (error) {
    console.error('Product fetch error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = { createProduct, getProducts };