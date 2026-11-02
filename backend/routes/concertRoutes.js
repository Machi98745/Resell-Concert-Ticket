const express = require('express');
const router = express.Router();
const concertController = require('../controllers/concertController');

router.get('/concerts', concertController.getAllConcerts);
router.get('/concerts/:id', concertController.getConcertById);

module.exports = router;