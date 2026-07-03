import 'dart:ui' show PlatformDispatcher;

/// Whether distances should display in feet/miles instead of
/// meters/kilometers, based on the device's region setting — US shows
/// imperial units, everywhere else (Europe and elsewhere) shows metric.
/// This mirrors how iOS/Android themselves pick measurement units and
/// requires no extra permissions, but reflects the phone's region
/// setting rather than live GPS location.
bool get useImperialUnits =>
    PlatformDispatcher.instance.locale.countryCode == 'US';

/// Formats a distance in kilometers as a short label in the unit system
/// appropriate for the device's region, e.g. "850 FT" / "2.3 MI" on a
/// US-region device, or "850 M" / "2.3 KM" everywhere else.
String formatDistanceKm(double distanceKm) {
  if (useImperialUnits) {
    final miles = distanceKm * 0.621371;
    if (miles < 0.1) {
      return '${(distanceKm * 3280.84).round()} FT';
    }
    return '${_trimTrailingZero(miles)} MI';
  }
  if (distanceKm < 1.0) {
    return '${(distanceKm * 1000).round()} M';
  }
  return '${_trimTrailingZero(distanceKm)} KM';
}

/// "3.0" -> "3", "3.1" -> "3.1" — keeps whole-number preset chips
/// (e.g. radius filters) clean while still showing precision when it
/// matters (e.g. a gym's actual computed distance).
String _trimTrailingZero(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
