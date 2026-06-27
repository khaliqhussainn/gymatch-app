/**
 * Location Service for parsing Google Maps URLs and extracting coordinates
 */
const axios = require('axios');

class LocationService {
  /**
   * Resolve shortened URLs by following redirects and return both final URL and page content
   */
  static async resolveAndFetch(url) {
    try {
      const response = await axios.get(url, {
        maxRedirects: 10,
        timeout: 15000,
        validateStatus: () => true, // Accept any status code
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept-Language': 'en-US,en;q=0.9'
        }
      });
      const finalUrl = response.request?.res?.responseUrl || 
                      response.request?.res?.responseURL || 
                      response.request?.path || 
                      response.config?.url ||
                      url;
      console.log('[LocationService.resolveAndFetch] Original:', url, 'Final:', finalUrl);
      return {
        finalUrl,
        html: response.data
      };
    } catch (error) {
      console.error('[LocationService.resolveAndFetch] Error:', error.message);
      return { finalUrl: url, html: null };
    }
  }

  /**
   * Resolve shortened URLs by following redirects (legacy backward compatibility wrapper)
   */
  static async resolveShortUrl(url) {
    const res = await this.resolveAndFetch(url);
    return res.finalUrl;
  }

  /**
   * Extract coordinates from HTML page contents using various patterns
   */
  static extractFromHtml(html) {
    if (!html || typeof html !== 'string') {
      return null;
    }

    // 1. Look for !2d longitude and !3d latitude (pb parameter / window variables / script data)
    // Matches patterns like %212d67.04988159999999%213d24.9135104 or !2d67.04988159999999!3d24.9135104
    // This is the most accurate place-specific coordinate data in Google Maps previews.
    const pbMatch = html.match(/%212d(-?\d+\.\d+)%213d(-?\d+\.\d+)/) || 
                    html.match(/!2d(-?\d+\.\d+)!3d(-?\d+\.\d+)/);
    if (pbMatch) {
      const lng = parseFloat(pbMatch[1]);
      const lat = parseFloat(pbMatch[2]);
      if (this.validateCoordinates(lat, lng)) {
        return {
          latitude: lat,
          longitude: lng,
          source: 'html_pb'
        };
      }
    }

    // 2. Look for og:image or itemprop="image" content which contains center=lat,lng as a fallback
    const ogImageMatch = html.match(/<meta\s+property="og:image"\s+content="([^"]+)"/i) || 
                         html.match(/<meta\s+content="([^"]+)"\s+property="og:image"/i) ||
                         html.match(/<meta\s+itemprop="image"\s+content="([^"]+)"/i) ||
                         html.match(/<meta\s+content="([^"]+)"\s+itemprop="image"/i);
    if (ogImageMatch) {
      const imageUrl = ogImageMatch[1];
      const centerMatch = imageUrl.match(/center=(-?\d+\.?\d*)(?:%2C|,)(-?\d+\.?\d*)/);
      if (centerMatch) {
        const lat = parseFloat(centerMatch[1]);
        const lng = parseFloat(centerMatch[2]);
        if (this.validateCoordinates(lat, lng)) {
          return {
            latitude: lat,
            longitude: lng,
            source: 'html_og_image'
          };
        }
      }
    }

    // 3. Look for og:url or twitter:url which might contain @lat,lng
    const ogUrlMatch = html.match(/<meta\s+property="og:url"\s+content="([^"]+)"/i) ||
                       html.match(/<meta\s+content="([^"]+)"\s+property="og:url"/i);
    if (ogUrlMatch) {
      const ogUrl = ogUrlMatch[1];
      const urlMatch = ogUrl.match(/@(-?\d+\.?\d*),(-?\d+\.?\d*)/);
      if (ogUrlMatch) {
        const lat = parseFloat(urlMatch[1]);
        const lng = parseFloat(urlMatch[2]);
        if (this.validateCoordinates(lat, lng)) {
          return {
            latitude: lat,
            longitude: lng,
            source: 'html_og_url'
          };
        }
      }
    }

    return null;
  }

  /**
   * Parse Google Maps URL to extract latitude and longitude
   * Supports various Google Maps URL formats
   */
  static async parseGoogleMapsUrl(url) {
    try {
      console.log('[LocationService.parseGoogleMapsUrl] Parsing URL:', url);
      
      let finalUrl = url;
      let htmlContent = null;

      // Handle shortened URLs (maps.app.goo.gl, goo.gl)
      if (url.includes('maps.app.goo.gl') || url.includes('goo.gl')) {
        const resolved = await this.resolveAndFetch(url);
        finalUrl = resolved.finalUrl;
        htmlContent = resolved.html;
        console.log('[LocationService.parseGoogleMapsUrl] Resolved URL:', finalUrl);
      }

      const urlObj = new URL(finalUrl);
      console.log('[LocationService.parseGoogleMapsUrl] URL Object:', {
        pathname: urlObj.pathname,
        search: urlObj.search,
        hash: urlObj.hash
      });
      
      // Format 1: https://maps.google.com/?q=lat,lng
      if (urlObj.searchParams.has('q')) {
        const q = urlObj.searchParams.get('q');
        console.log('[LocationService.parseGoogleMapsUrl] q param:', q);
        const coords = q.match(/^(-?\d+\.?\d*),(-?\d+\.?\d*)$/);
        if (coords) {
          return {
            latitude: parseFloat(coords[1]),
            longitude: parseFloat(coords[2]),
            source: 'url_q_param'
          };
        }
      }

      // Format 2: https://maps.google.com/?ll=lat,lng
      if (urlObj.searchParams.has('ll')) {
        const ll = urlObj.searchParams.get('ll');
        console.log('[LocationService.parseGoogleMapsUrl] ll param:', ll);
        const coords = ll.match(/^(-?\d+\.?\d*),(-?\d+\.?\d*)$/);
        if (coords) {
          return {
            latitude: parseFloat(coords[1]),
            longitude: parseFloat(coords[2]),
            source: 'url_ll_param'
          };
        }
      }

      // Format 3: https://www.google.com/maps/@lat,lng,zoom
      const pathMatch = urlObj.pathname.match(/@(-?\d+\.?\d*),(-?\d+\.?\d*)/);
      if (pathMatch) {
        console.log('[LocationService.parseGoogleMapsUrl] Path match:', pathMatch);
        return {
          latitude: parseFloat(pathMatch[1]),
          longitude: parseFloat(pathMatch[2]),
          source: 'url_path'
        };
      }

      // Format 4: https://maps.google.com/place/.../@lat,lng,zoom
      const placeMatch = urlObj.href.match(/@(-?\d+\.?\d*),(-?\d+\.?\d*)/);
      if (placeMatch) {
        console.log('[LocationService.parseGoogleMapsUrl] Place match:', placeMatch);
        return {
          latitude: parseFloat(placeMatch[1]),
          longitude: parseFloat(placeMatch[2]),
          source: 'url_place'
        };
      }

      // Format 5: Extract from data parameter (new Google Maps format)
      if (urlObj.searchParams.has('data')) {
        const data = urlObj.searchParams.get('data');
        console.log('[LocationService.parseGoogleMapsUrl] data param:', data);
        // Try to extract coordinates from encoded data
        const coordMatch = data.match(/!3d(-?\d+\.?\d*)!4d(-?\d+\.?\d*)/);
        if (coordMatch) {
          return {
            latitude: parseFloat(coordMatch[1]),
            longitude: parseFloat(coordMatch[2]),
            source: 'url_data_param'
          };
        }
      }

      // Format 6: Check hash for coordinates (newer Google Maps format)
      if (urlObj.hash) {
        console.log('[LocationService.parseGoogleMapsUrl] Hash:', urlObj.hash);
        const hashMatch = urlObj.hash.match(/!3d(-?\d+\.?\d*)!4d(-?\d+\.?\d*)/);
        if (hashMatch) {
          return {
            latitude: parseFloat(hashMatch[1]),
            longitude: parseFloat(hashMatch[2]),
            source: 'url_hash'
          };
        }
      }

      // Format 7: Check entire URL for @lat,lng pattern (fallback)
      const urlMatch = finalUrl.match(/@(-?\d+\.?\d*),(-?\d+\.?\d*)/);
      if (urlMatch) {
        console.log('[LocationService.parseGoogleMapsUrl] URL match:', urlMatch);
        return {
          latitude: parseFloat(urlMatch[1]),
          longitude: parseFloat(urlMatch[2]),
          source: 'url_full_match'
        };
      }

      // Format 8: Check HTML content if already fetched (short URLs)
      if (htmlContent) {
        console.log('[LocationService.parseGoogleMapsUrl] Checking htmlContent fallback');
        const parsed = this.extractFromHtml(htmlContent);
        if (parsed) return parsed;
      }

      // Format 9: Fetch HTML content fallback (for long URLs with missing coords e.g. /place/ without coordinates in URL)
      const isGoogleMaps = finalUrl.includes('google.com') || 
                           finalUrl.includes('google.co') || 
                           finalUrl.includes('maps.google') || 
                           finalUrl.includes('goo.gl');
      if (isGoogleMaps && !htmlContent) {
        console.log('[LocationService.parseGoogleMapsUrl] URL parsing failed. Fetching HTML fallback...');
        const resolved = await this.resolveAndFetch(finalUrl);
        const parsed = this.extractFromHtml(resolved.html);
        if (parsed) return parsed;
      }

      console.log('[LocationService.parseGoogleMapsUrl] No matching format found');
      return null;
    } catch (error) {
      console.error('[LocationService.parseGoogleMapsUrl] Error:', error);
      return null;
    }
  }

  /**
   * Validate coordinates
   */
  static validateCoordinates(lat, lng) {
    if (typeof lat !== 'number' || typeof lng !== 'number') {
      return false;
    }
    if (lat < -90 || lat > 90) {
      return false;
    }
    if (lng < -180 || lng > 180) {
      return false;
    }
    return true;
  }

  /**
   * Extract location from URL or return manual coordinates
   */
  static async extractLocation(locationInput) {
    // If input is already coordinates object
    if (typeof locationInput === 'object' && locationInput.latitude && locationInput.longitude) {
      if (this.validateCoordinates(locationInput.latitude, locationInput.longitude)) {
        return {
          latitude: locationInput.latitude,
          longitude: locationInput.longitude,
          source: 'manual'
        };
      }
      return null;
    }

    // If input is a URL, try to parse it
    if (typeof locationInput === 'string' && locationInput.startsWith('http')) {
      const parsed = await this.parseGoogleMapsUrl(locationInput);
      if (parsed && this.validateCoordinates(parsed.latitude, parsed.longitude)) {
        return parsed;
      }
      return null;
    }

    // If input is a string with lat,lng format
    if (typeof locationInput === 'string') {
      const coords = locationInput.match(/^(-?\d+\.?\d*),(-?\d+\.?\d*)$/);
      if (coords) {
        const lat = parseFloat(coords[1]);
        const lng = parseFloat(coords[2]);
        if (this.validateCoordinates(lat, lng)) {
          return {
            latitude: lat,
            longitude: lng,
            source: 'manual_string'
          };
        }
      }
    }

    return null;
  }

  /**
   * Get error message for invalid location input
   */
  static getErrorMessage(input) {
    if (!input) {
      return 'Location is required';
    }

    if (typeof input === 'string' && input.startsWith('http')) {
      return 'Invalid Google Maps URL. Please use a valid Google Maps link with coordinates.';
    }

    if (typeof input === 'string') {
      return 'Invalid coordinates format. Please use format: latitude,longitude (e.g., 24.8607,67.0011)';
    }

    if (typeof input === 'object') {
      if (!input.latitude || !input.longitude) {
        return 'Both latitude and longitude are required';
      }
      return 'Invalid coordinates. Latitude must be between -90 and 90, longitude between -180 and 180';
    }

    return 'Invalid location input';
  }
}

module.exports = LocationService;
