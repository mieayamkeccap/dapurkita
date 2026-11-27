// Entry point backend saat jalan di Vercel (serverless).
// Semua request diteruskan ke app Express oleh vercel.json.

const app = require('../server');

module.exports = app;
