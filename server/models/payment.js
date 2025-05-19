const paymentSchema = {
    txRef: String,
    amount: Number,
    currency: String,
    email: String,
    status: String,
    createdAt: { type: Date, default: Date.now },
  };
  
  module.exports = paymentSchema;