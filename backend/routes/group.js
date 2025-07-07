const express = require('express');
const router = express.Router();
const { createGroup, joinGroup } = require('../controllers/groupController');
const authMiddleware = require('../middleware/authMiddleware');

// Protect routes with auth middleware
router.post('/create', authMiddleware, createGroup);
router.post('/join', authMiddleware, joinGroup);

module.exports = router;
