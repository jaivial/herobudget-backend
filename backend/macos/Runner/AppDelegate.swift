import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Handle Google Sign In callback URLs
    let controller : FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
    _ = FlutterMethodChannel(name: "plugins.flutter.io/google_sign_in", binaryMessenger: controller.engine.binaryMessenger)
    
    super.applicationDidFinishLaunching(notification)
  }
  
  override func application(_ application: NSApplication, open urls: [URL]) {
    // Handle URL scheme for Google Sign In redirects
    for url in urls {
      if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
        if components.scheme?.lowercased().contains("google") == true {
          // Pass the URL to the Google Sign In plugin
          let controller : FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
          let googleSignInChannel = FlutterMethodChannel(name: "plugins.flutter.io/google_sign_in", binaryMessenger: controller.engine.binaryMessenger)
          googleSignInChannel.invokeMethod("url_launched", arguments: url.absoluteString)
        }
      }
    }
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
