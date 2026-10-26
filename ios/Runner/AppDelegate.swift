import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let mapsKey = dartDefine("GOOGLE_MAPS_IOS_API_KEY")
    if !mapsKey.isEmpty {
      GMSServices.provideAPIKey(mapsKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Reads a Flutter --dart-define from Info.plist DART_DEFINES (base64 pairs).
  private func dartDefine(_ key: String) -> String {
    guard let packed = Bundle.main.object(forInfoDictionaryKey: "DART_DEFINES") as? String
    else { return "" }
    for part in packed.split(separator: ",") {
      guard let data = Data(base64Encoded: String(part)),
            let decoded = String(data: data, encoding: .utf8)
      else { continue }
      let pieces = decoded.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        .map(String.init)
      if pieces.count == 2 && pieces[0] == key {
        return pieces[1]
      }
    }
    return ""
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
