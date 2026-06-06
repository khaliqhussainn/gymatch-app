import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showWhite;

  const AppLogo({
    super.key,
    this.size = 72,
    this.showWhite = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/logo.PNG',
        fit: BoxFit.contain,
      ),
    );
  }
}
