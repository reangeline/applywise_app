import 'package:home_widget/home_widget.dart';

/// Manages data written to the iOS WidgetKit shared container.
///
/// The App Group identifier must match the one configured in Xcode
/// for both the Runner target and the HirefyWidget extension.
class WidgetService {
  WidgetService._();

  static const _appGroupId = 'group.careers.hirefy.app';
  static const _iOSWidgetName = 'HirefyWidgetExtension';

  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (_) {
      // Native side not configured yet (e.g. missing pod install or Xcode target).
    }
  }

  /// Push latest snapshot to the home screen widget.
  static Future<void> update({
    required String userName,
    required bool isPro,
    required int credits,
    required int resumeCount,
  }) async {
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<String>('userName', userName),
        HomeWidget.saveWidgetData<bool>('isPro', isPro),
        HomeWidget.saveWidgetData<int>('credits', credits),
        HomeWidget.saveWidgetData<int>('resumeCount', resumeCount),
      ]);
      await HomeWidget.updateWidget(iOSName: _iOSWidgetName);
    } catch (_) {
      // Silent — widget updates are best-effort.
    }
  }
}
