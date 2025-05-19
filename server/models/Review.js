
const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
  rating: { type: Number, required: true },
  comment: { type: String, required: true },
  createdDate: { type: Date, default: Date.now },
});

module.exports = mongoose.models.Review || mongoose.model('Review', reviewSchema);