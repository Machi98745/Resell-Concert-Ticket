const express = require('express');
const router = express.Router();
const resellController = require('../controllers/resellController');

router.get('/', resellController.getAllResellListings);
router.get('/:id', resellController.getResellListingById);
router.post('/', resellController.createResellListing);

module.exports = router;