// routes/matches.js
const express = require('express');
const router  = express.Router();
router.post('/result',       async (req, res) => { res.status(501).json({ error: 'Not implemented' }); });
router.get('/:uid/history',  async (req, res) => { res.status(501).json({ error: 'Not implemented' }); });
module.exports = router;
