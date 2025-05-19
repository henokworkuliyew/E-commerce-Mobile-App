const mongoose = require('mongoose');

const itemSchema = new mongoose.Schema({
  id: { type: String, required: true },
  name: { type: String, required: true },
  price: { type: Number, required: true },
  quantity: { type: Number, required: true },
  image: { type: String, required: true },
});

const orderSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
  },
  items: {
    type: [itemSchema],
    required: true,
  },
  totalPrice: {
    type: Number,
    required: true,
  },
  shippingName: {
    type: String,
    required: true,
  },
  shippingAddress: {
    type: String,
    required: true,
  },
  city: {
    type: String,
    required: true,
  },
  postalCode: {
    type: String,
    required: true,
  },
  shippingPhone: {
    type: String,
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Order', orderSchema);