const express = require('express');
const { getPosts, createPost } = require('./community.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const router = express.Router();

router.use(verifyToken);
router.get('/', getPosts);
router.post('/', createPost);

module.exports = router;