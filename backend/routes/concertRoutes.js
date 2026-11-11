const express = require('express');
const router = express.Router();
const concertController = require('../controllers/concertController');

router.get('/', concertController.getAllConcerts);
router.get('/:id', concertController.getConcertById);

module.exports = router;
