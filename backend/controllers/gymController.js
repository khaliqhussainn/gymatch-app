const Gym = require('../models/Gym');
const pool = require('../config/connection');

const DUMMY_PHONE = '+1-310-555-0199';
const PUBLIC_API_BASE_URL = process.env.PUBLIC_API_BASE_URL || 'https://gymatch.syedmisbahali.com/api';
const GOOGLE_API_KEY_PLACEHOLDER = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
const SEEDED_GYM_MAX_ID = 32;
const SEEDED_PARTNER_LINK_RADIUS_KM = 8;

function isDummyPhone(phone) {
  if (!phone || !phone.trim()) return true;
  return phone === DUMMY_PHONE || phone.includes('555-0199');
}

function isDummyImageUrl(url) {
  return !url || url.includes('unsplash.com') || url.includes('placeholder');
}

function isDirectGooglePhotoUrl(url) {
  return !!url && url.includes('maps.googleapis.com/maps/api/place/photo');
}

function formatOpeningHours(openingHours) {
  if (!openingHours?.weekday_text?.length) return '';
  return openingHours.weekday_text.join(' | ');
}

function buildPhotoUrl(photoReference, maxWidth = 800, placeId = '') {
  const params = new URLSearchParams({
    maxwidth: String(maxWidth),
    photo_reference: photoReference,
  });
  if (placeId) {
    params.set('place_id', placeId);
  }
  return `${PUBLIC_API_BASE_URL}/gyms/place-photo?${params}`;
}

function addPlaceIdToPhotoUrl(url, placeId) {
  if (!url || !placeId || !url.includes('/gyms/place-photo')) return url;
  try {
    const parsed = new URL(url);
    if (!parsed.searchParams.get('place_id')) {
      parsed.searchParams.set('place_id', placeId);
    }
    return parsed.toString();
  } catch {
    return url;
  }
}

function normalizeGooglePhotoUrlsForGym(gym) {
  if (!gym?.google_place_id) return gym;
  const normalized = { ...gym };
  normalized.cover_image = addPlaceIdToPhotoUrl(
    normalized.cover_image,
    normalized.google_place_id
  );
  if (Array.isArray(normalized.images)) {
    normalized.images = normalized.images.map((url) =>
      addPlaceIdToPhotoUrl(url, normalized.google_place_id)
    );
  }
  return normalized;
}

function hasUsableGoogleMapsKey(apiKey) {
  return !!apiKey && apiKey !== GOOGLE_API_KEY_PLACEHOLDER;
}

function redactKeyFromUrl(url) {
  return url.replace(/([?&]key=)[^&]+/i, '$1REDACTED');
}

function sanitizeGymForGoogleOnly(gym) {
  const sanitized = { ...gym };
  if (isDummyPhone(sanitized.contact_phone)) {
    sanitized.contact_phone = '';
  }
  if (sanitized.cover_image && isDummyImageUrl(sanitized.cover_image)) {
    sanitized.cover_image = null;
  }
  if (Array.isArray(sanitized.images)) {
    sanitized.images = sanitized.images.filter((url) => !isDummyImageUrl(url));
  }
  return sanitized;
}

async function fetchGooglePlaceDetails(placeId, apiKey) {
  const fields = [
    'name',
    'formatted_phone_number',
    'international_phone_number',
    'opening_hours',
    'photos',
    'formatted_address',
    'vicinity',
    'rating',
    'url',
    'website',
    'wheelchair_accessible_entrance',
    'editorial_summary',
  ].join(',');
  const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${encodeURIComponent(placeId)}&fields=${fields}&key=${apiKey}`;
  const response = await fetch(url);
  const data = await response.json();
  if (data.status !== 'OK') {
    console.warn('[fetchGooglePlaceDetails]', data.status, data.error_message);
    return null;
  }
  return data.result;
}

async function fetchGooglePlaceDetailsNew(placeId, apiKey) {
  const fields = [
    'accessibilityOptions',
    'parkingOptions',
    'restroom',
    'outdoorSeating',
  ].join(',');
  const url = `https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}`;
  const response = await fetch(url, {
    headers: {
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': fields,
    },
  });
  const data = await response.json();
  if (!response.ok || data.error) {
    console.warn(
      '[fetchGooglePlaceDetailsNew]',
      data.error?.status || response.status,
      data.error?.message
    );
    return null;
  }
  return data;
}

async function fetchGoogleNearbyPlaces({ lat, lng, radiusMeters, category, openNow, apiKey }) {
  const cat = (category || 'All').toString();
  const params = new URLSearchParams({
    location: `${lat},${lng}`,
    radius: String(radiusMeters),
    type: 'gym',
    key: apiKey,
  });

  if (cat.toLowerCase() !== 'all' && cat.toLowerCase() !== 'gym') {
    params.set('keyword', placesKeywordForCategory(cat));
  }
  if (openNow === true || openNow === 'true') {
    params.set('opennow', 'true');
  }

  const url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?${params}`;
  const response = await fetch(url);
  const data = await response.json();
  return { url, data };
}

function pushAmenity(amenities, condition, label) {
  if (condition) amenities.add(label);
}

function buildGoogleAmenities(legacyDetails, newDetails) {
  const amenities = new Set();

  pushAmenity(
    amenities,
    legacyDetails?.wheelchair_accessible_entrance === true ||
      newDetails?.accessibilityOptions?.wheelchairAccessibleEntrance === true,
    'Wheelchair accessible entrance'
  );
  pushAmenity(
    amenities,
    newDetails?.accessibilityOptions?.wheelchairAccessibleParking === true,
    'Wheelchair accessible parking'
  );
  pushAmenity(amenities, newDetails?.restroom === true, 'Restroom');
  pushAmenity(amenities, newDetails?.outdoorSeating === true, 'Outdoor services');

  const parking = newDetails?.parkingOptions || {};
  pushAmenity(
    amenities,
    parking.freeParkingLot === true || parking.paidParkingLot === true,
    'Parking lot'
  );
  pushAmenity(
    amenities,
    parking.freeStreetParking === true || parking.paidStreetParking === true,
    'Street parking'
  );
  pushAmenity(
    amenities,
    parking.freeGarageParking === true || parking.paidGarageParking === true,
    'Garage parking'
  );
  pushAmenity(amenities, parking.valetParking === true, 'Valet parking');

  return [...amenities];
}

async function syncGymAmenitiesFromGoogle(gymId, amenities) {
  await pool.query('DELETE FROM gym_amenities WHERE gym_id = ?', [gymId]);
  if (!amenities.length) return;
  for (const amenity of amenities) {
    await pool.query(
      'INSERT INTO gym_amenities (gym_id, name) VALUES (?, ?)',
      [gymId, amenity]
    );
  }
}

async function syncGymPhotosFromGoogle(gymId, photos, placeId) {
  await pool.query('DELETE FROM gym_images WHERE gym_id = ?', [gymId]);
  if (!photos?.length) return;
  const seenReferences = new Set();
  const slice = photos
    .filter((photo) => {
      const reference = photo?.photo_reference;
      if (!reference || seenReferences.has(reference)) return false;
      seenReferences.add(reference);
      return true;
    })
    .slice(0, 4);
  for (let i = 0; i < slice.length; i++) {
    const photoUrl = buildPhotoUrl(slice[i].photo_reference, 800, placeId);
    await pool.query(
      'INSERT INTO gym_images (gym_id, image_url, sort_order) VALUES (?, ?, ?)',
      [gymId, photoUrl, i]
    );
  }
}

async function syncGymFromGooglePlace(gymId, placeId, apiKey) {
  const details = await fetchGooglePlaceDetails(placeId, apiKey);
  if (!details) return false;
  const newDetails = await fetchGooglePlaceDetailsNew(placeId, apiKey);

  const phone = details.formatted_phone_number || details.international_phone_number || '';
  const openHours = formatOpeningHours(details.opening_hours);
  const isOpen = details.opening_hours?.open_now != null
    ? (details.opening_hours.open_now ? 1 : 0)
    : null;
  const rating = details.rating ?? null;
  const address = details.formatted_address || details.vicinity || '';

  const updates = [];
  const params = [];
  updates.push('contact_phone = ?');
  params.push(phone);

  updates.push('open_hours = ?');
  params.push(openHours);

  if (isOpen !== null) {
    updates.push('is_open = ?');
    params.push(isOpen);
  }
  if (rating != null) {
    updates.push('rating = ?');
    params.push(rating);
  }
  if (address) {
    updates.push('location_name = ?');
    params.push(address);
  }

  params.push(gymId);
  await pool.query(`UPDATE gyms SET ${updates.join(', ')} WHERE id = ?`, params);

  await syncGymPhotosFromGoogle(gymId, details.photos || [], placeId);

  const googleAmenities = buildGoogleAmenities(details, newDetails);
  await syncGymAmenitiesFromGoogle(gymId, googleAmenities);

  return true;
}

async function fetchGymRowWithCover(gymId) {
  const [rows] = await pool.query(
    `SELECT g.*,
      (SELECT i.image_url FROM gym_images i WHERE i.gym_id = g.id ORDER BY i.sort_order ASC LIMIT 1) AS cover_image
     FROM gyms g WHERE g.id = ?`,
    [gymId]
  );
  return rows[0] || null;
}

async function findGooglePlaceIdForPhotoReference(photoReference) {
  if (!photoReference) return '';
  const [rows] = await pool.query(
    `SELECT g.google_place_id
     FROM gym_images i
     JOIN gyms g ON g.id = i.gym_id
     WHERE i.image_url LIKE ?
       AND g.google_place_id IS NOT NULL
       AND g.google_place_id != ''
     ORDER BY i.sort_order ASC
     LIMIT 1`,
    [`%${photoReference}%`]
  );
  return rows[0]?.google_place_id || '';
}

async function findPhotoSortOrder(photoReference, placeId) {
  if (!photoReference || !placeId) return 0;
  const [rows] = await pool.query(
    `SELECT i.sort_order
     FROM gym_images i
     JOIN gyms g ON g.id = i.gym_id
     WHERE i.image_url LIKE ?
       AND g.google_place_id = ?
     ORDER BY i.sort_order ASC
     LIMIT 1`,
    [`%${photoReference}%`, placeId]
  );
  return parseInt(rows[0]?.sort_order, 10) || 0;
}

async function refreshStoredPhotosForPlace(placeId, photos) {
  if (!placeId || !photos?.length) return;
  const [rows] = await pool.query(
    'SELECT id FROM gyms WHERE google_place_id = ? LIMIT 1',
    [placeId]
  );
  const gymId = rows[0]?.id;
  if (!gymId) return;
  await syncGymPhotosFromGoogle(gymId, photos, placeId);
}

async function refreshStoredPhotoReference(oldReference, freshReference, placeId) {
  if (!oldReference || !freshReference || !placeId) return;
  const freshUrl = buildPhotoUrl(freshReference, 800, placeId);
  await pool.query(
    `UPDATE gym_images i
     JOIN gyms g ON g.id = i.gym_id
     SET i.image_url = ?
     WHERE i.image_url LIKE ?
       AND g.google_place_id = ?`,
    [freshUrl, `%${oldReference}%`, placeId]
  );
}

async function linkSeededPartnersToGoogleGym(gymId, latitude, longitude) {
  await pool.query(
    `INSERT IGNORE INTO active_partners
       (user_id, gym_id, status, workout_type, experience_level)
     SELECT ap.user_id, ?, ap.status, ap.workout_type, ap.experience_level
     FROM active_partners ap
     JOIN gyms seeded ON seeded.id = ap.gym_id
     WHERE seeded.id <= ?
       AND seeded.google_place_id IS NULL
       AND (
         6371 * acos(
           GREATEST(-1, LEAST(1,
             cos(radians(?)) * cos(radians(seeded.latitude)) *
             cos(radians(seeded.longitude) - radians(?)) +
             sin(radians(?)) * sin(radians(seeded.latitude))
           ))
         )
       ) <= ?`,
    [
      gymId,
      SEEDED_GYM_MAX_ID,
      latitude,
      longitude,
      latitude,
      SEEDED_PARTNER_LINK_RADIUS_KM,
    ]
  );
}

/**
 * GET /api/gyms
 * Query: lat, lng, radius (km), search, category
 */
exports.getNearby = async (req, res) => {
  try {
    const { lat, lng, radius = 15, search = '', category = '', featured = '' } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({ error: 'Location coordinates (lat, lng) are required.' });
    }

    const parsedLat = parseFloat(lat);
    const parsedLng = parseFloat(lng);

    if (isNaN(parsedLat) || isNaN(parsedLng)) {
      return res.status(400).json({ error: 'Invalid coordinates provided.' });
    }

    const dbConfig = require('../config/db');
    const apiKey = dbConfig.googleMapsApiKey;
    
    // Calculate radius in meters (max 50,000 for Google Places API)
    const radiusMeters = Math.min(Math.max(parseFloat(radius) * 1000 || 15000, 500), 50000);
    const cat = (category || 'All').toString();

    let places = [];
    let googleFailed = false;

    if (hasUsableGoogleMapsKey(apiKey)) {
      try {
        const { data } = await fetchGoogleNearbyPlaces({
          lat: parsedLat,
          lng: parsedLng,
          radiusMeters,
          category: cat,
          apiKey,
        });

        if (data.status === 'OK' || data.status === 'ZERO_RESULTS') {
          places = data.results || [];
        } else {
          console.warn('[GymController.getNearby] Google Places API status:', data.status, data.error_message);
          googleFailed = true;
        }
      } catch (err) {
        console.error('[GymController.getNearby] Google Places API fetch error:', err);
        googleFailed = true;
      }
    } else {
      googleFailed = true;
    }

    // If Google Places query succeeded, synchronize and return them!
    if (!googleFailed) {
      const gymsList = [];
      const currentUserId = req.user ? req.user.userId : null;

      for (const place of places) {
        const placeId = place.place_id;
        const name = place.name;
        const placeLat = place.geometry.location.lat;
        const placeLng = place.geometry.location.lng;
        const rating = place.rating || 0;
        const address = place.vicinity || '';
        const isOpen = place.opening_hours ? (place.opening_hours.open_now ? 1 : 0) : 0;

        // Check if gym exists in the DB
        const [existing] = await pool.query(
          'SELECT id, is_featured, category FROM gyms WHERE google_place_id = ?',
          [placeId]
        );

        let gymId;
        let isFeatured = 0;

        if (existing.length > 0) {
          gymId = existing[0].id;
          isFeatured = existing[0].is_featured;
          await syncGymFromGooglePlace(gymId, placeId, apiKey);
        } else {
          const details = await fetchGooglePlaceDetails(placeId, apiKey);
          const newDetails = details ? await fetchGooglePlaceDetailsNew(placeId, apiKey) : null;
          const phone =
            details?.formatted_phone_number ||
            details?.international_phone_number ||
            '';
          const openHours = details ? formatOpeningHours(details.opening_hours) : '';
          const detailRating = details?.rating ?? rating;
          const detailAddress =
            details?.formatted_address || details?.vicinity || address;
          const detailIsOpen =
            details?.opening_hours?.open_now != null
              ? details.opening_hours.open_now
                ? 1
                : 0
              : isOpen;

          const [insertRes] = await pool.query(
            `INSERT INTO gyms (name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, google_place_id, is_featured)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
              name,
              '',
              detailAddress,
              '',
              placeLat,
              placeLng,
              detailRating,
              detailIsOpen,
              openHours,
              phone,
              cat.toUpperCase() === 'ALL' ? 'GYM' : cat,
              placeId,
              0,
            ]
          );
          gymId = insertRes.insertId;

          if (details?.photos?.length) {
            await syncGymPhotosFromGoogle(gymId, details.photos, placeId);
          }
          await syncGymAmenitiesFromGoogle(
            gymId,
            buildGoogleAmenities(details, newDetails)
          );
        }

        const gymRow = normalizeGooglePhotoUrlsForGym(await fetchGymRowWithCover(gymId));
        await linkSeededPartnersToGoogleGym(gymId, placeLat, placeLng);

        // Calculate Haversine distance
        const R = 6371; // km
        const dLat = (placeLat - parsedLat) * Math.PI / 180;
        const dLon = (placeLng - parsedLng) * Math.PI / 180;
        const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                  Math.cos(parsedLat * Math.PI / 180) * Math.cos(placeLat * Math.PI / 180) *
                  Math.sin(dLon/2) * Math.sin(dLon/2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        const distanceKm = R * c;

        // Fetch active partners count
        const [partners] = await pool.query(
          'SELECT COUNT(*) AS count FROM active_partners WHERE gym_id = ?',
          [gymId]
        );
        const activePartnersCount = partners[0].count;

        // Fetch user specific fields (is_saved, is_active_partner)
        let isSaved = false;
        let isActivePartner = false;
        if (currentUserId) {
          const [savedCheck] = await pool.query(
            'SELECT 1 FROM saved_gyms WHERE user_id = ? AND gym_id = ?',
            [currentUserId, gymId]
          );
          isSaved = savedCheck.length > 0;

          const [activeCheck] = await pool.query(
            'SELECT 1 FROM active_partners WHERE user_id = ? AND gym_id = ?',
            [currentUserId, gymId]
          );
          isActivePartner = activeCheck.length > 0;
        }

        const coverImage =
          gymRow?.cover_image && !isDummyImageUrl(gymRow.cover_image)
            ? gymRow.cover_image
            : null;
        const contactPhone =
          gymRow?.contact_phone && !isDummyPhone(gymRow.contact_phone)
            ? gymRow.contact_phone
            : '';

        gymsList.push({
          id: gymId,
          name: gymRow?.name || name,
          sub_name: gymRow?.sub_name || '',
          location_name: gymRow?.location_name || address,
          near_location: gymRow?.near_location || '',
          latitude: placeLat,
          longitude: placeLng,
          rating: gymRow?.rating ?? rating,
          is_open: gymRow?.is_open ?? isOpen,
          open_hours: gymRow?.open_hours || '',
          contact_phone: contactPhone,
          category: gymRow?.category || (cat.toUpperCase() === 'ALL' ? 'GYM' : cat),
          is_featured: isFeatured,
          distance_km: distanceKm,
          cover_image: coverImage,
          active_partners_count: activePartnersCount,
          is_saved: isSaved,
          is_active_partner: isActivePartner,
        });
      }

      // Apply client-side filters on synced results if requested
      let filteredGyms = gymsList;
      if (featured === 'true') {
        filteredGyms = filteredGyms.filter(g => g.is_featured === 1);
      }
      if (search && search.trim()) {
        const term = search.trim().toLowerCase();
        filteredGyms = filteredGyms.filter(g =>
          g.name.toLowerCase().includes(term) ||
          g.location_name.toLowerCase().includes(term)
        );
      }

      // Sort: Featured first, then by distance
      filteredGyms.sort((a, b) => {
        if (b.is_featured !== a.is_featured) {
          return b.is_featured - a.is_featured;
        }
        return a.distance_km - b.distance_km;
      });

      // Also fetch manually registered gyms (without google_place_id) from database
      const manualGyms = await Gym.findNearby({
        lat: parsedLat,
        lng: parsedLng,
        radiusKm: parseFloat(radius),
        search,
        category,
        featuredOnly: featured === 'true',
      });

      // Filter to only include gyms without google_place_id (manually registered)
      const manuallyRegisteredGyms = manualGyms.filter(gym => !gym.google_place_id);

      // Enrich manually registered gyms with user state
      for (const gym of manuallyRegisteredGyms) {
        let isSaved = false;
        let isActivePartner = false;
        if (currentUserId) {
          const [savedCheck] = await pool.query(
            'SELECT 1 FROM saved_gyms WHERE user_id = ? AND gym_id = ?',
            [currentUserId, gym.id]
          );
          isSaved = savedCheck.length > 0;

          const [activeCheck] = await pool.query(
            'SELECT 1 FROM active_partners WHERE user_id = ? AND gym_id = ?',
            [currentUserId, gym.id]
          );
          isActivePartner = activeCheck.length > 0;
        }

        // Calculate distance for manually registered gyms
        const R = 6371; // km
        const dLat = (gym.latitude - parsedLat) * Math.PI / 180;
        const dLon = (gym.longitude - parsedLng) * Math.PI / 180;
        const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                  Math.cos(parsedLat * Math.PI / 180) * Math.cos(gym.latitude * Math.PI / 180) *
                  Math.sin(dLon/2) * Math.sin(dLon/2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        const distanceKm = R * c;

        filteredGyms.push({
          ...gym,
          distance_km: distanceKm,
          is_saved: isSaved,
          is_active_partner: isActivePartner
        });
      }

      // Re-sort after adding manually registered gyms
      filteredGyms.sort((a, b) => {
        if (b.is_featured !== a.is_featured) {
          return b.is_featured - a.is_featured;
        }
        return a.distance_km - b.distance_km;
      });

      return res.json({ gyms: filteredGyms, count: filteredGyms.length });
    }

    // FALLBACK: If Google Places API fails or isn't configured, query local DB gyms
    const gyms = await Gym.findNearby({
      lat: parsedLat,
      lng: parsedLng,
      radiusKm: parseFloat(radius),
      search,
      category,
      featuredOnly: featured === 'true',
    });

    // Enrich local fallback gyms with user state (is_saved, is_active_partner)
    const currentUserId = req.user ? req.user.userId : null;
    const enrichedGyms = [];
    for (const gym of gyms) {
      let isSaved = false;
      let isActivePartner = false;
      if (currentUserId) {
        const [savedCheck] = await pool.query(
          'SELECT 1 FROM saved_gyms WHERE user_id = ? AND gym_id = ?',
          [currentUserId, gym.id]
        );
        isSaved = savedCheck.length > 0;

        const [activeCheck] = await pool.query(
          'SELECT 1 FROM active_partners WHERE user_id = ? AND gym_id = ?',
          [currentUserId, gym.id]
        );
        isActivePartner = activeCheck.length > 0;
      }
      enrichedGyms.push(normalizeGooglePhotoUrlsForGym({
        ...gym,
        is_saved: isSaved,
        is_active_partner: isActivePartner
      }));
    }

    res.json({ gyms: enrichedGyms, count: enrichedGyms.length });
  } catch (error) {
    console.error('[GymController.getNearby]', error);
    res.status(500).json({ error: 'Failed to fetch nearby gyms. Please try again.' });
  }
};

/**
 * GET /api/gyms/:id
 */
exports.getById = async (req, res) => {
  try {
    const { id } = req.params;
    const gymId = parseInt(id, 10);

    const dbConfig = require('../config/db');
    const apiKey = dbConfig.googleMapsApiKey;
    const [placeRows] = await pool.query(
      'SELECT google_place_id FROM gyms WHERE id = ?',
      [gymId]
    );
    if (
      placeRows[0]?.google_place_id &&
      hasUsableGoogleMapsKey(apiKey)
    ) {
      await syncGymFromGooglePlace(gymId, placeRows[0].google_place_id, apiKey);
    }

    let gym = await Gym.findById(gymId);

    if (!gym) {
      return res.status(404).json({ error: 'Gym not found.' });
    }

    gym = normalizeGooglePhotoUrlsForGym(gym);

    if (isDummyPhone(gym.contact_phone)) {
      gym.contact_phone = '';
    }
    gym.images = (gym.images || []).filter((url) => !isDummyImageUrl(url));
    if (gym.cover_image && isDummyImageUrl(gym.cover_image)) {
      gym.cover_image = gym.images[0] || null;
    }

    // If user is authenticated, check if saved and if active partner
    let isSaved = false;
    let isActivePartner = false;
    if (req.user && req.user.userId) {
      isSaved = await Gym.isSaved(req.user.userId, gym.id);
      const [activeCheck] = await pool.query(
        'SELECT 1 FROM active_partners WHERE user_id = ? AND gym_id = ?',
        [req.user.userId, gym.id]
      );
      isActivePartner = activeCheck.length > 0;
    }

    res.json({ ...gym, is_saved: isSaved, is_active_partner: isActivePartner });
  } catch (error) {
    console.error('[GymController.getById]', error);
    res.status(500).json({ error: 'Failed to fetch gym details. Please try again.' });
  }
};

/**
 * POST /api/gyms/:id/favorite  (requires auth)
 */
exports.toggleFavorite = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    const result = await Gym.toggleSaved(userId, parseInt(id, 10));
    res.json(result);
  } catch (error) {
    console.error('[GymController.toggleFavorite]', error);
    res.status(500).json({ error: 'Failed to update saved gym. Please try again.' });
  }
};

/**
 * GET /api/gyms/favorites  (requires auth)
 */
exports.getFavorites = async (req, res) => {
  try {
    const userId = req.user.userId;
    const gyms = await Gym.getSaved(userId);
    res.json({ gyms, count: gyms.length });
  } catch (error) {
    console.error('[GymController.getFavorites]', error);
    res.status(500).json({ error: 'Failed to fetch saved gyms. Please try again.' });
  }
};

/**
 * POST /api/gyms/:id/partner-toggle (requires auth)
 */
exports.togglePartnerStatus = async (req, res) => {
  try {
    const gymId = parseInt(req.params.id, 10);
    const userId = req.user.userId;
    const { status, workout_type, experience_level } = req.body;

    const [existing] = await pool.query(
      'SELECT 1 FROM active_partners WHERE user_id = ? AND gym_id = ?',
      [userId, gymId]
    );

    if (existing.length > 0) {
      await pool.query(
        'DELETE FROM active_partners WHERE user_id = ? AND gym_id = ?',
        [userId, gymId]
      );
      return res.json({ active: false });
    } else {
      const userStatus = status || 'Active Now';
      let workoutType = workout_type;
      let expLevel = experience_level;

      if (!workoutType || !expLevel) {
        const [profile] = await pool.query('SELECT workout_types FROM profiles WHERE user_id = ?', [userId]);
        if (profile.length > 0) {
          workoutType = workoutType || profile[0].workout_types || 'General';
        } else {
          workoutType = workoutType || 'General';
        }
        expLevel = expLevel || 'Intermediate';
      }

      await pool.query(
        'INSERT INTO active_partners (user_id, gym_id, status, workout_type, experience_level) VALUES (?, ?, ?, ?, ?)',
        [userId, gymId, userStatus, workoutType, expLevel]
      );
      return res.json({ active: true });
    }
  } catch (error) {
    console.error('[GymController.togglePartnerStatus]', error);
    res.status(500).json({ error: 'Failed to toggle partner status.' });
  }
};

/**
 * GET /api/gyms/:id/active-partners
 */
exports.getActivePartners = async (req, res) => {
  try {
    const gymId = parseInt(req.params.id, 10);
    let currentUserId = null;
    if (req.user && req.user.userId) {
      currentUserId = req.user.userId;
    }

    const query = `
      SELECT ap.*, p.name AS user_name, u.email
      FROM active_partners ap
      JOIN users u ON ap.user_id = u.id
      LEFT JOIN profiles p ON ap.user_id = p.user_id
      WHERE ap.gym_id = ? AND (? IS NULL OR ap.user_id != ?)
      ORDER BY ap.activated_at DESC
    `;
    const [rows] = await pool.query(query, [gymId, currentUserId, currentUserId]);
    
    const partners = rows.map(r => ({
      userId: r.user_id,
      gymId: r.gym_id,
      status: r.status,
      workoutType: r.workout_type || 'General',
      experienceLevel: r.experience_level || 'Intermediate',
      name: r.user_name || r.email.split('@')[0],
      activatedAt: r.activated_at
    }));

    res.json({ partners, count: partners.length });
  } catch (error) {
    console.error('[GymController.getActivePartners]', error);
    res.status(500).json({ error: 'Failed to fetch active partners.' });
  }
};

/**
 * GET /api/gyms/place-photo
 * Proxies Google Place photos so the mobile app never exposes the server API key.
 * Query: photo_reference, maxwidth
 */
exports.getPlacePhoto = async (req, res) => {
  try {
    const dbConfig = require('../config/db');
    const apiKey = dbConfig.googleMapsApiKey;
    const {
      photo_reference: photoReference,
      place_id: placeId = '',
      maxwidth = '800',
    } = req.query;

    if (!hasUsableGoogleMapsKey(apiKey)) {
      return res.status(503).json({ error: 'GOOGLE_MAPS_API_KEY is not configured on the server.' });
    }
    if (!photoReference) {
      return res.status(400).json({ error: 'photo_reference is required.' });
    }

    const maxWidth = Math.min(Math.max(parseInt(maxwidth, 10) || 800, 100), 1600);
    const buildGooglePhotoUrl = (reference) => {
      const params = new URLSearchParams({
        maxwidth: String(maxWidth),
        photo_reference: reference,
        key: apiKey,
      });
      return `https://maps.googleapis.com/maps/api/place/photo?${params}`;
    };

    const effectivePlaceId =
      placeId || (await findGooglePlaceIdForPhotoReference(photoReference));

    let url = buildGooglePhotoUrl(photoReference);
    const response = await fetch(url, {
      redirect: 'follow',
      headers: {
        Accept: 'image/jpeg,image/png,image/webp,*/*;q=0.8',
      },
    });

    if (!response.ok) {
      if (effectivePlaceId) {
        const freshDetails = await fetchGooglePlaceDetails(effectivePlaceId, apiKey);
        const sortOrder = await findPhotoSortOrder(photoReference, effectivePlaceId);
        const freshReference =
          freshDetails?.photos?.[sortOrder]?.photo_reference ||
          freshDetails?.photos?.[0]?.photo_reference;
        if (freshReference && freshReference !== photoReference) {
          url = buildGooglePhotoUrl(freshReference);
          const retryResponse = await fetch(url, {
            redirect: 'follow',
            headers: {
              Accept: 'image/jpeg,image/png,image/webp,*/*;q=0.8',
            },
          });
          if (retryResponse.ok) {
            await refreshStoredPhotosForPlace(
              effectivePlaceId,
              freshDetails.photos
            )
              .catch(() =>
                refreshStoredPhotoReference(
                  photoReference,
                  freshReference,
                  effectivePlaceId
                )
              )
              .catch((err) =>
                console.warn('[GymController.getPlacePhoto] failed to refresh stored photo URL:', err.message)
              );
            const retryContentType =
              retryResponse.headers.get('content-type') || 'image/jpeg';
            const retryBuffer = Buffer.from(await retryResponse.arrayBuffer());
            res.setHeader('Content-Type', retryContentType);
            res.setHeader('Cache-Control', 'public, max-age=86400');
            return res.send(retryBuffer);
          }
        }
      }

      const googleError = await response.text().catch(() => '');
      return res.status(response.status).json({
        error: 'Google Place photo request failed.',
        google_status: response.status,
        can_retry_with_place_id: !effectivePlaceId,
        google_error: googleError.slice(0, 500),
      });
    }

    const contentType = response.headers.get('content-type') || 'image/jpeg';
    const buffer = Buffer.from(await response.arrayBuffer());
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=604800, immutable');
    return res.send(buffer);
  } catch (error) {
    console.error('[GymController.getPlacePhoto]', error);
    res.status(500).json({ error: 'Failed to fetch Google Place photo.' });
  }
};

/**
 * GET /api/gyms/debug-google
 * Browser-friendly endpoint to verify raw Google Places data and enriched fields.
 * Query: lat, lng, radius (meters), category, limit
 */
exports.debugGoogleGymData = async (req, res) => {
  try {
    const dbConfig = require('../config/db');
    const apiKey = dbConfig.googleMapsApiKey;
    if (!hasUsableGoogleMapsKey(apiKey)) {
      return res.status(503).json({
        configured: false,
        status: 'MISSING_API_KEY',
        error: 'GOOGLE_MAPS_API_KEY is not configured on the server.',
      });
    }

    const {
      lat = '38.9072',
      lng = '-77.0369',
      radius = '15000',
      category = 'All',
      openNow = 'false',
      limit = '10',
    } = req.query;

    const parsedLat = parseFloat(lat);
    const parsedLng = parseFloat(lng);
    if (Number.isNaN(parsedLat) || Number.isNaN(parsedLng)) {
      return res.status(400).json({ error: 'Valid lat and lng query params are required.' });
    }

    const radiusMeters = Math.min(Math.max(parseInt(radius, 10) || 15000, 500), 50000);
    const maxResults = Math.min(Math.max(parseInt(limit, 10) || 10, 1), 20);
    const { url, data } = await fetchGoogleNearbyPlaces({
      lat: parsedLat,
      lng: parsedLng,
      radiusMeters,
      category,
      openNow,
      apiKey,
    });

    const rawResults = (data.results || []).slice(0, maxResults);
    const enriched = [];
    for (const place of rawResults) {
      const details = await fetchGooglePlaceDetails(place.place_id, apiKey);
      const newDetails = details ? await fetchGooglePlaceDetailsNew(place.place_id, apiKey) : null;
      enriched.push({
        place_id: place.place_id,
        name: details?.name || place.name,
        address: details?.formatted_address || details?.vicinity || place.vicinity || '',
        phone: details?.formatted_phone_number || details?.international_phone_number || '',
        open_now: details?.opening_hours?.open_now ?? place.opening_hours?.open_now ?? null,
        opening_hours: formatOpeningHours(details?.opening_hours),
        rating: details?.rating ?? place.rating ?? 0,
        photo_count: details?.photos?.length || place.photos?.length || 0,
        first_photo_url: details?.photos?.[0]?.photo_reference
          ? buildPhotoUrl(details.photos[0].photo_reference, 800, place.place_id)
          : null,
        amenities: buildGoogleAmenities(details, newDetails),
        places_new_fields_available: !!newDetails,
        nearby_has_photos: !!place.photos?.length,
        details_found: !!details,
      });
    }

    return res.json({
      configured: true,
      request: {
        lat: parsedLat,
        lng: parsedLng,
        radius_meters: radiusMeters,
        category,
        open_now: openNow === 'true' || openNow === true,
        google_url: redactKeyFromUrl(url),
      },
      google_status: data.status,
      google_error_message: data.error_message || null,
      raw_count: data.results?.length || 0,
      enriched_count: enriched.length,
      gyms: enriched,
    });
  } catch (error) {
    console.error('[GymController.debugGoogleGymData]', error);
    res.status(500).json({ error: 'Failed to debug Google gym data.' });
  }
};

const PLACES_CATEGORY_KEYWORDS = {
  all: 'gym fitness center',
  crossfit: 'CrossFit gym',
  mma: 'MMA gym martial arts',
  yoga: 'yoga studio',
  'strength training': 'strength training gym',
  bodybuilding: 'bodybuilding gym',
  powerlifting: 'powerlifting gym',
  'cardio training': 'cardio fitness center',
  hiit: 'HIIT fitness gym',
  'functional fitness': 'functional fitness gym',
  boxing: 'boxing gym',
  kickboxing: 'kickboxing gym',
  pilates: 'pilates studio',
  zumba: 'zumba fitness class',
  'cycling / spinning': 'spinning cycling studio',
  calisthenics: 'calisthenics gym',
  'personal training': 'personal training gym',
  'circuit training': 'circuit training gym',
  aerobics: 'aerobics fitness center',
  'dance fitness': 'dance fitness studio',
  'mobility & stretching': 'mobility stretching studio',
};

function placesKeywordForCategory(category) {
  const key = (category || 'all').toLowerCase();
  return PLACES_CATEGORY_KEYWORDS[key] || `${key} gym`;
}

/**
 * GET /api/gyms/places-nearby
 * Server-side proxy for Google Places Nearby Search (avoids browser CORS on web).
 * Query: lat, lng, radius (meters), category, openNow ('true'|'false')
 */
exports.getPlacesNearby = async (req, res) => {
  try {
    const dbConfig = require('../config/db');
    const apiKey = dbConfig.googleMapsApiKey;
    if (!hasUsableGoogleMapsKey(apiKey)) {
      return res.status(503).json({
        status: 'REQUEST_DENIED',
        error: 'GOOGLE_MAPS_API_KEY is not configured on the server.',
        results: [],
      });
    }

    const { lat, lng, radius = '15000', category = 'All', openNow = 'false' } = req.query;
    if (!lat || !lng) {
      return res.status(400).json({ error: 'lat and lng are required.' });
    }

    const radiusMeters = Math.min(Math.max(parseInt(radius, 10) || 15000, 500), 50000);
    const cat = (category || 'All').toString();
    const useOpenNow = openNow === 'true' || openNow === true;

    const { data } = await fetchGoogleNearbyPlaces({
      lat,
      lng,
      radiusMeters,
      category: cat,
      openNow: useOpenNow,
      apiKey,
    });

    res.json(data);
  } catch (error) {
    console.error('[GymController.getPlacesNearby]', error);
    res.status(500).json({
      status: 'ERROR',
      error: 'Places search failed.',
      results: [],
    });
  }
};

/**
 * GET /api/gyms/:id/partners (gym owner only)
 * Get active partners at the gym owner's gym
 */
exports.getGymPartners = async (req, res) => {
  try {
    const gymId = parseInt(req.params.id, 10);
    const userId = req.user.userId;

    // Verify user is the gym owner
    const GymOwner = require('../models/GymOwner');
    const gymOwner = await GymOwner.findByUserId(userId);
    
    if (!gymOwner || gymOwner.gym_id !== gymId) {
      return res.status(403).json({ error: 'You are not authorized to view partners for this gym.' });
    }

    const query = `
      SELECT ap.*, p.name AS user_name, u.email
      FROM active_partners ap
      JOIN users u ON ap.user_id = u.id
      LEFT JOIN profiles p ON ap.user_id = p.user_id
      WHERE ap.gym_id = ?
      ORDER BY ap.activated_at DESC
    `;
    const [rows] = await pool.query(query, [gymId]);
    
    const partners = rows.map(r => ({
      userId: r.user_id,
      gymId: r.gym_id,
      status: r.status,
      workoutType: r.workout_type || 'General',
      experienceLevel: r.experience_level || 'Intermediate',
      name: r.user_name || r.email.split('@')[0],
      email: r.email,
      activatedAt: r.activated_at
    }));

    res.json({ partners, count: partners.length });
  } catch (error) {
    console.error('[GymController.getGymPartners]', error);
    res.status(500).json({ error: 'Failed to fetch gym partners.' });
  }
};

/**
 * PUT /api/gyms/:id (gym owner only)
 * Update gym details
 */
exports.updateGymDetails = async (req, res) => {
  try {
    const gymId = parseInt(req.params.id, 10);
    const userId = req.user.userId;
    const { 
      gymName,
      gymSubName,
      locationName,
      nearLocation,
      category,
      contactPhone,
      openHours,
      images,
      amenities,
      latitude,
      longitude 
    } = req.body;

    // Verify user is the gym owner
    const GymOwner = require('../models/GymOwner');
    const gymOwner = await GymOwner.findByUserId(userId);
    
    if (!gymOwner || gymOwner.gym_id !== gymId) {
      return res.status(403).json({ error: 'You are not authorized to update this gym.' });
    }

    // Update gym details
    const updates = [];
    const params = [];

    if (gymName) {
      updates.push('name = ?');
      params.push(gymName);
    }
    if (gymSubName !== undefined) {
      updates.push('sub_name = ?');
      params.push(gymSubName || null);
    }
    if (locationName) {
      updates.push('location_name = ?');
      params.push(locationName);
    }
    if (nearLocation !== undefined) {
      updates.push('near_location = ?');
      params.push(nearLocation || null);
    }
    if (category) {
      updates.push('category = ?');
      params.push(category);
    }
    if (contactPhone !== undefined) {
      updates.push('contact_phone = ?');
      params.push(contactPhone || null);
    }
    if (openHours) {
      updates.push('open_hours = ?');
      params.push(openHours);
    }
    if (latitude !== undefined && latitude !== null) {
      updates.push('latitude = ?');
      params.push(latitude);
    }
    if (longitude !== undefined && longitude !== null) {
      updates.push('longitude = ?');
      params.push(longitude);
    }

    if (updates.length > 0) {
      params.push(gymId);
      await pool.query(`UPDATE gyms SET ${updates.join(', ')} WHERE id = ?`, params);
    }

    // Update images if provided
    if (images && Array.isArray(images)) {
      await pool.query('DELETE FROM gym_images WHERE gym_id = ?', [gymId]);
      for (let i = 0; i < images.length; i++) {
        let imageUrl = images[i];
        // If it's base64 without prefix, add it
        if (imageUrl && (imageUrl.startsWith('/9j/') || imageUrl.startsWith('iVBORw'))) {
          const prefix = imageUrl.startsWith('/9j/') ? 'data:image/jpeg;base64,' : 'data:image/png;base64,';
          imageUrl = prefix + imageUrl;
        }
        await pool.query(
          'INSERT INTO gym_images (gym_id, image_url, sort_order) VALUES (?, ?, ?)',
          [gymId, imageUrl, i]
        );
      }
      console.log('[GymController.updateGymDetails] Updated', images.length, 'images for gym', gymId);
    }

    // Update amenities if provided
    if (amenities && Array.isArray(amenities)) {
      await pool.query('DELETE FROM gym_amenities WHERE gym_id = ?', [gymId]);
      for (const amenity of amenities) {
        await pool.query(
          'INSERT INTO gym_amenities (gym_id, name) VALUES (?, ?)',
          [gymId, amenity]
        );
      }
    }

    res.json({ message: 'Gym details updated successfully' });
  } catch (error) {
    console.error('[GymController.updateGymDetails]', error);
    res.status(500).json({ error: 'Failed to update gym details.' });
  }
};
