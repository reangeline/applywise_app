import 'package:flutter/services.dart';

/// Centralizes all haptic feedback calls.
/// Use named methods to convey intent at the call site.
class HapticService {
  HapticService._();

  /// Light tap — navigation, selection changes, minor interactions.
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Selection click — toggling options, tab switches, step changes.
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Medium impact — confirmations, save success.
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Heavy impact — purchases, deletions, major completions.
  static Future<void> heavy() => HapticFeedback.heavyImpact();

  /// Error vibration — failed actions, validation errors.
  static Future<void> error() => HapticFeedback.vibrate();
}
