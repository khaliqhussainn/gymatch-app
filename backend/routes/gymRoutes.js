const express = require('express');
const router = express.Router();
const gymController = require('../controllers/gymController');
const authMiddleware = require('../middleware/authMiddleware');

// Public routes (no auth required — guests can browse gyms)
router.get('/places-nearby', gymController.getPlacesNearby);
router.get('/place-photo', gymController.getPlacePhoto);
router.get('/debug-google', gymController.debugGoogleGymData);
router.get('/', authMiddleware.optionalAuthenticate, gymController.getNearby);

// /favorites must come before /:id to avoid 'favorites' being parsed as an id
router.get('/favorites', authMiddleware.authenticate, gymController.getFavorites);

router.get('/:id', authMiddleware.optionalAuthenticate, gymController.getById);
router.get('/:id/active-partners', authMiddleware.optionalAuthenticate, gymController.getActivePartners);

// Protected routes (auth required)
router.post('/:id/favorite', authMiddleware.authenticate, gymController.toggleFavorite);
router.post('/:id/partner-toggle', authMiddleware.authenticate, gymController.togglePartnerStatus);

module.exports = router;
