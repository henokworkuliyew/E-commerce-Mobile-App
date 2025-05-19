const express = require('express');
const connectDB = require('./config/db');
const authRoutes = require('./routes/auth');
const productRoutes = require('./routes/products');
const orderRoutes = require('./routes/order');
const paymentRoutes = require('./routes/paymentRoutes');
const { loadEnv } = require('./config/env');
const app = express();

// Connect to MongoDB
connectDB();
loadEnv();

// Middleware
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/payments', paymentRoutes);

app.post('/callback', (req, res) => {
  console.log('Chapa callback received:', req.body);
  res.status(200).send('OK');
});

app.get('/success', (req, res) => {
  console.log('Chapa redirect to success:', req.query);
  const txRef = req.query.tx_ref || '';
  const redirectUrl = `myapp://payment-callback?status=success&tx_ref=${txRef}`;
  try {
    res.redirect(redirectUrl);
    console.log(`Redirected to: ${redirectUrl}`);
  } catch (error) {
    console.error('Redirect failed:', error.message);
    res.status(500).send('Redirect failed');
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));