const Order = require('../models/Order');

exports.createOrder = async (req, res) => {
  try {
    const { userId, items, totalPrice, shippingName, shippingAddress, city, postalCode, shippingPhone } = req.body;
    const order = new Order({
      userId,
      items,
      totalPrice,
      shippingName,
      shippingAddress,
      city,
      postalCode,
      shippingPhone,
    });
    const savedOrder = await order.save();
    res.status(201).json(savedOrder);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

exports.getOrders = async (req, res) => {
  try {
    const orders = await Order.find({ userId: req.params.userId });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};