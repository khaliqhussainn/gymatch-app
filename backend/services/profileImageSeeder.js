'use strict';

const fs = require('fs');
const path = require('path');

/**
 * Stock AI-generated headshots checked into the mobile app's asset folder,
 * reused here so dummy/seeded users get a profile picture instead of a
 * blank avatar. Grouped by the gender they read as; pickProfileImage()
 * cycles through the pool with modulo so any number of seeded users can
 * share this small set of images.
 */
const IMAGE_DIR = path.join(__dirname, '..', '..', 'mobile-app', 'assets', 'images');
const FEMALE_FILES = ['pro1.jfif', 'pro3.jfif', 'pro4.jfif', 'pro5.jfif'];
const MALE_FILES = ['pro2.jfif', 'pro6.jfif', 'pro7.jfif'];

let femaleImages = null;
let maleImages = null;

function loadBase64(files) {
  return files.map((f) => fs.readFileSync(path.join(IMAGE_DIR, f)).toString('base64'));
}

/**
 * Returns a base64-encoded stock headshot for the given gender, cycling
 * through that gender's pool by index. Any gender other than 'female'
 * falls back to the male pool.
 */
function pickProfileImage(gender, index) {
  if (femaleImages === null) femaleImages = loadBase64(FEMALE_FILES);
  if (maleImages === null) maleImages = loadBase64(MALE_FILES);
  const pool = gender === 'female' ? femaleImages : maleImages;
  return pool[index % pool.length];
}

module.exports = { pickProfileImage };
