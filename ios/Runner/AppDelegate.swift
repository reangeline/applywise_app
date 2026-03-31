import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

  private let appGroupID = "group.careers.hirefy.app"
  private let sharedTextKey = "sharedJobText"
  private let channelName = "careers.hirefy.app/share"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Call super first so window/rootViewController is fully set up
    let superResult = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Set up MethodChannel so Flutter can read text written by the Share Extension
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }
        if call.method == "getSharedText" {
          // Read directly from App Group — does not depend on URL scheme
          let defaults = UserDefaults(suiteName: self.appGroupID)
          let text = defaults?.string(forKey: self.sharedTextKey)
          result((text?.isEmpty == false) ? text : nil)
          defaults?.removeObject(forKey: self.sharedTextKey)
          defaults?.synchronize()
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return superResult
  }
}
