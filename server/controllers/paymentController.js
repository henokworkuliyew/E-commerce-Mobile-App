const axios = require('axios');

const CHAPA_BASE_URL = 'https://api.chapa.co/v1';
const CHAPA_SECRET_KEY = process.env.CHAPA_SECRET_KEY;

const axiosInstance = axios.create({
  baseURL: CHAPA_BASE_URL,
  headers: {
    Authorization: `Bearer ${CHAPA_SECRET_KEY}`,
    'Content-Type': 'application/json',
  },
});

exports.initializePayment = async (req, res) => {
  const { userId, amount, currency, email, firstName, lastName, phoneNumber } = req.body;

  console.log('Received payment initialization request:', { userId, amount, currency, email, firstName, lastName, phoneNumber });

  if (!userId || !amount || !currency || !email || !firstName || !phoneNumber) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  const txRef = `tx-${userId}-${Date.now()}`;
  console.log('Generated txRef:', txRef);

  const paymentData = {
    amount: amount.toString(), // Adjust if Chapa requires cents: (parseFloat(amount) * 100).toString()
    currency,
    email,
    first_name: firstName,
    last_name: lastName,
    phone_number: phoneNumber,
    tx_ref: txRef,
    callback_url: 'http://192.168.228.1:5000/callback',
    return_url: 'https://abcd1234.ngrok.io/success', // Replace with your ngrok URL
  };
  console.log('Sending to Chapa:', paymentData);

  try {
    const response = await axiosInstance.post('/transaction/initialize', paymentData);
    console.log('Chapa response:', response.data);

    const chapaData = response.data;
    if (chapaData.status === 'success' && chapaData.data && chapaData.data.checkout_url) {
      res.status(200).json({
        checkoutUrl: chapaData.data.checkout_url,
        txRef: chapaData.data.tx_ref,
      });
    } else {
      res.status(400).json({ message: 'Failed to get checkout URL', details: chapaData });
    }
  } catch (error) {
    console.error('Payment initialization error:', {
      message: error.message,
      response: error.response ? error.response.data : null,
      status: error.response ? error.response.status : null,
    });
    if (error.response) {
      return res.status(500).json({
        message: `Request failed with status code ${error.response.status}`,
        details: error.response.data,
      });
    }
    res.status(500).json({ message: 'Internal server error' });
  }
};

exports.verifyPayment = async (req, res) => {
  const { tx_ref, status } = req.query;

  console.log('Received payment verification request:', { tx_ref, status });

  if (!tx_ref || !status) {
    return res.status(400).json({ message: 'Missing tx_ref or status' });
  }

  try {
    const response = await axiosInstance.get(`/transaction/verify/${tx_ref}`);
    console.log('Chapa verify response:', response.data);
    res.status(200).json({ status: 'success', data: response.data });
  } catch (error) {
    console.error('Payment verification error:', error.response ? error.response.data : error.message);
    res.status(500).json({ message: 'Verification failed', details: error.response?.data });
  }
};