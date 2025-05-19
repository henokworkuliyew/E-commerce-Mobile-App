require('dotenv').config();

function loadEnv() {
  if (!process.env.CHAPA_SECRET_KEY) {
    console.error('Error: CHAPA_SECRET_KEY is not set in environment variables.');
    process.exit(1);
  }
}

module.exports = { loadEnv };