const axios = require('axios');
const { v4: uuidv4 } = require('uuid');

exports.initializePayment = async (req, res) => {
  try {
    const { userId, amount, currency, email, firstName, lastName, phoneNumber } = req.body;

    const txRef = uuidv4(); // Generate a unique transaction reference

    const paymentData = {
      amount,
      currency,
      email,
      first_name: firstName,
      last_name: lastName,
      phone_number: phoneNumber,
      tx_ref: txRef,
      callback_url: process.env.CALLBACK_URL,
      return_url: 'myapp://payment-callback', // Deep link for mobile app
    };

    const response = await axios.post(
      'https://api.chapa.co/v1/transaction/initialize',
      paymentData,
      {
        headers: {
          Authorization: `Bearer ${process.env.CHAPA_SECRET_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    if (response.data.status === 'success') {
      res.status(200).json({
        checkoutUrl: response.data.data.checkout_url,
        txRef: txRef,
      });
    } else {
      res.status(400).json({ message: 'Failed to initialize payment' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.verifyPayment = async (req, res) => {
  try {
    const { tx_ref, status } = req.query;

    if (status !== 'success') {
      return res.status(400).json({ message: 'Payment not successful' });
    }

    const response = await axios.get(
      `https://api.chapa.co/v1/transaction/verify/${tx_ref}`,
      {
        headers: {
          Authorization: `Bearer ${process.env.CHAPA_SECRET_KEY}`,
        },
      }
    );

    if (response.data.status === 'success') {
      res.status(200).json({
        status: 'success',
        data: response.data.data,
      });
    } else {
      res.status(400).json({ message: 'Payment verification failed' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};