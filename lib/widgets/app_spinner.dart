import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../config/theme.dart';

/// Branded loading spinner using flutter_spinkit.
/// Replaces all [CircularProgressIndicator] usages across the app.
class AppSpinner extends StatelessWidget {
  final double size;
  final Color? color;

  const AppSpinner({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryColor;
    return SpinKitFadingCircle(
      color: effectiveColor,
      size: size,
    );
  }
}

/// Small inline spinner (24 px) — for buttons and tight spaces.
class AppSpinnerSmall extends StatelessWidget {
  final Color? color;

  const AppSpinnerSmall({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return AppSpinner(size: 24, color: color ?? Colors.white);
  }
}
