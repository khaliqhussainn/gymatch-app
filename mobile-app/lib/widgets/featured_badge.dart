import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable FEATURED badge shown on gym cards and detail screens.
class FeaturedBadge extends StatelessWidget {
  final double fontSize;
  final EdgeInsets padding;

  const FeaturedBadge({
    super.key,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'FEATURED',
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
