// routes/license.js
const express = require('express');
const router  = express.Router();
router.post('/validate', async (req, res) => { res.status(501).json({ error: 'Not implemented' }); });
router.post('/activate', async (req, res) => { res.status(501).json({ error: 'Not implemented' }); });
module.exports = router;
