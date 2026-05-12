// index.js — OPTCG Cloud Run API entry point
// Agent 6 owns this file.
require('dotenv').config();
const express = require('express');

const app = express();
app.use(express.json());

// ── Routes ────────────────────────────────────────────────────────────────────
// TODO: Agent 6 implements all routes
app.use('/api/auth',     require('./routes/auth'));
app.use('/api/decks',    require('./routes/decks'));
app.use('/api/matches',  require('./routes/matches'));
app.use('/api/license',  require('./routes/license'));

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'optcg-api' }));

// ── Start ─────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`OPTCG API running on port ${PORT}`);
});
