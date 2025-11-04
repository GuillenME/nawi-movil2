import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configurar Google Maps API Key
    // ⚠️ REEMPLAZA "TU_API_KEY_AQUI" con tu API Key real de Google Maps
    GMSServices.provideAPIKey("AIzaSyCaZFeEmON_iOVCBO24V1FmQu0pQ2QrxhU")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
