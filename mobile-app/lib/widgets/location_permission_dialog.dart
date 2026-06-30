import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/location_service.dart';

/// Shows an Apple-compliant pre-permission explanation dialog.
/// Returns `true` if the user tapped Continue and the system permission
/// flow should proceed.
Future<bool> showLocationPermissionRationale(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF151515),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.location_on_rounded, color: AppColors.primary, size: 26),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Location Access',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: const Text(
        'GYMatch uses your location to show nearby gyms and accurate distance. '
        'Your exact location is never shared with other users.',
        style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 14),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Banner shown when location permission is denied or permanently denied.
class LocationPermissionBanner extends StatelessWidget {
  final LocationPermissionStatus status;
  final VoidCallback onOpenSettings;
  final VoidCallback? onRetry;

  const LocationPermissionBanner({
    super.key,
    required this.status,
    required this.onOpenSettings,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (status == LocationPermissionStatus.granted) {
      return const SizedBox.shrink();
    }

    final isPermanent = status == LocationPermissionStatus.deniedForever;
    final isServiceDisabled = status == LocationPermissionStatus.serviceDisabled;

    final message = isServiceDisabled
        ? 'Location services are turned off. Enable them in Settings to see nearby gyms.'
        : isPermanent
            ? 'Location access is disabled. Open Settings to enable nearby gym discovery.'
            : 'Location access is off. Enable it to see gyms near you.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_off_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          if (!isPermanent && !isServiceDisabled && onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          TextButton(
            onPressed: onOpenSettings,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
