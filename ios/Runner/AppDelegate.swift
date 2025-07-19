import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var methodChannel: FlutterMethodChannel?
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
      let controller = window?.rootViewController as! FlutterViewController
      let whisperEventChannel = FlutterEventChannel(
        name: "whisper_events",
        binaryMessenger: controller.binaryMessenger
      )
      
      // Setup the MethodChannel with name matching Dart side
      methodChannel = FlutterMethodChannel(
        name: "whisper_method_channel",
        binaryMessenger: controller.binaryMessenger
      )
      
      methodChannel?.setMethodCallHandler { call, result in
          // Forward calls to your existing handler
          WhisperFlutterBridge.shared.handleMethodCall(call, result: result)
      }
      
      whisperEventChannel.setStreamHandler(WhisperFlutterBridge.shared)
      
      GeneratedPluginRegistrant.register(with: self)
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
