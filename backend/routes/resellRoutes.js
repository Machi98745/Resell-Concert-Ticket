
const express = require('express');
const router = express.Router();

const resellController = require('../controllers/resellController');
const { verifyToken } = require('../middlewares/authMiddleware');

// Check whether all required handlers exist
const requiredHandlers = [
  'getAllResellListings',
  'getMyResellListings',
  'getMyTickets',
  'registerSeller',
  'getSellerStatus',
  'getResellListingById',
  'createResellListing',
  'cancelResellListing',
];

for (const handler of requiredHandlers) {
  if (typeof resellController[handler] !== 'function') {
    throw new Error(
      `resellController.${handler} is missing or is not a function.`
    );
  }
}

if (typeof verifyToken !== 'function') {
  throw new Error('verifyToken middleware is not a function.');
}

// Get available resale listings
router.get('/listings', resellController.getAllResellListings);
router.get('/', resellController.getAllResellListings);

// Get the logged-in user's listings
router.get('/my-listings', verifyToken, resellController.getMyResellListings);

// Get tickets owned by the logged-in user
router.get('/my-tickets', verifyToken, resellController.getMyTickets);

// Seller identity verification
router.post('/seller/register', verifyToken, resellController.registerSeller);
router.get('/seller/status', verifyToken, resellController.getSellerStatus);

// Get a resale listing by ID
router.get('/:id', resellController.getResellListingById);

// Create a resale listing
router.post('/create', verifyToken, resellController.createResellListing);
router.post('/', verifyToken, resellController.createResellListing);

// Cancel a resale listing
router.patch('/:id/cancel', verifyToken, resellController.cancelResellListing);

module.exports = router;
