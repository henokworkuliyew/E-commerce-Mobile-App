const express = require('express');
const connectDB = require('./config/db');
const authRoutes = require('./routes/auth');
const productRoutes = require('./routes/products');
// const cartRoutes = require('./routes/cart');

const app = express();

// Connect to MongoDB
connectDB();

// Middleware
app.use(express.json());


app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
// app.use('/api/cart', cartRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));