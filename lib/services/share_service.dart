import 'package:flutter/services.dart';

/// Handles incoming shared text from the iOS Share Extension.
/// The native side writes the job text to the App Group and opens
/// the app via `hirefyapp://share`. Flutter polls on resume to
/// retrieve and clear the pending text via MethodChannel.
class ShareService {
  ShareService._();

  static const _channel = MethodChannel('careers.hirefy.app/share');

  /// Returns the job text shared from Safari/LinkedIn, or null if none pending.
  static Future<String?> getSharedText() async {
    try {
      final text = await _channel.invokeMethod<String>('getSharedText');
      return (text != null && text.isNotEmpty) ? text : null;
    } catch (_) {
      return null;
    }
  }
}
