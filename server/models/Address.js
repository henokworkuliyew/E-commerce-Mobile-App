const mongoose = require('mongoose');

const addressSchema = new mongoose.Schema({
  userId: {
    type: String,
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

module.exports = mongoose.model('Address', addressSchema);