// routes/auth.js — POST /api/auth/login, /api/auth/register
// Agent 6 owns this file.
const express = require('express');
const router  = express.Router();

// POST /api/auth/login
router.post('/login', async (req, res) => {
  // TODO: Agent 6 — validate Firebase ID token, upsert player record
  res.status(501).json({ error: 'Not implemented' });
});

// POST /api/auth/register
router.post('/register', async (req, res) => {
  // TODO: Agent 6 — create player record in PostgreSQL
  res.status(501).json({ error: 'Not implemented' });
});

module.exports = router;
