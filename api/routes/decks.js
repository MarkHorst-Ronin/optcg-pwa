// routes/decks.js
const express = require('express');
const router  = express.Router();
// GET  /api/decks/:uid
router.get('/:uid', async (req, res) => { res.status(501).json({ error: 'Not implemented' }); });
// POST /api/decks/:uid
router.post('/:uid', async (req, res) => { res.status(501).json({ error: 'Not implemented' }); });
// DELETE /api/decks/:uid/:deck_id
router.delete('/:uid/:deck_id', async (req, res) => { res.status(501).json({ error: 'Not implemented' }); });
module.exports = router;
