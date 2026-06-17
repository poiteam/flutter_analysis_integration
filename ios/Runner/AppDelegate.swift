import Flutter
import UIKit
import CoreLocation
import PoilabsAnalysis

private let methodChannelName = "com.poilabs.analysis/poi_analysis"
private let eventChannelName = "com.poilabs.analysis/poi_events"

@main
@objc class AppDelegate: FlutterAppDelegate, PLAnalysisManagerDelegate {
  private var eventSink: FlutterEventSink?
  private var isMonitoring = false
  private let locationManager = CLLocationManager()

  private var appId: String {
    Bundle.main.object(forInfoDictionaryKey: "POIAppId") as? String ?? ""
  }

  private var applicationSecret: String {
    Bundle.main.object(forInfoDictionaryKey: "POIAppSecret") as? String ?? ""
  }

  private var uniqueId: String {
    Bundle.main.object(forInfoDictionaryKey: "POIUniqueId") as? String ?? ""
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if launchOptions?[.location] != nil,
       UIApplication.shared.applicationState == .background {
      PLSuspendedAnalysisManager.sharedInstance().startBeaconMonitoring()
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      setupChannels(controller: controller)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
  }

  private func setupChannels(controller: FlutterViewController) {
    let methodChannel = FlutterMethodChannel(
      name: methodChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate released", details: nil))
        return
      }

      switch call.method {
      case "getPlatform":
        result("ios")
      case "requestPermissions":
        self.requestLocationPermissions()
        result(true)
      case "startScan":
        self.startMonitoring()
        result(true)
      case "stopScan":
        self.stopMonitoring()
        result(true)
      case "getSdkVersion":
        result(PLAnalysisSettings.sharedInstance()?.getpoilabsAnalysisVersionNumber() ?? "unknown")
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let eventChannel = FlutterEventChannel(
      name: eventChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    eventChannel.setStreamHandler(self)
  }

  private func requestLocationPermissions() {
    locationManager.requestWhenInUseAuthorization()
    locationManager.requestAlwaysAuthorization()
  }

  private func startMonitoring() {
    let settings = PLAnalysisSettings.sharedInstance()
    settings?.applicationId = appId
    settings?.applicationSecret = applicationSecret
    settings?.analysisUniqueIdentifier = uniqueId

    PLConfigManager.sharedInstance().getReadyForTracking(completionHandler: { [weak self] error in
      guard let self else { return }

      DispatchQueue.main.async {
        if let error {
          self.emitEvent([
            "type": "error",
            "message": error.errorDescription ?? "Config error",
          ])
          return
        }

        PLSuspendedAnalysisManager.sharedInstance().stopBeaconMonitoring()
        PLStandardAnalysisManager.sharedInstance().startBeaconMonitoring()
        PLStandardAnalysisManager.sharedInstance().delegate = self
        self.isMonitoring = true
        self.emitEvent([
          "type": "status",
          "message": "Scan started",
        ])
      }
    })
  }

  private func stopMonitoring() {
    PLStandardAnalysisManager.sharedInstance().stopBeaconMonitoring()
    PLAnalysisSettings.sharedInstance()?.closeAllActions()
    isMonitoring = false
    emitEvent([
      "type": "status",
      "message": "Scan stopped",
    ])
  }

  private func emitEvent(_ payload: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(payload)
    }
  }

  private func parseNodeIds(from response: [AnyHashable: Any]) -> [String] {
    guard let data = response["data"] else {
      return []
    }

    if let nodeIds = data as? [String] {
      return nodeIds
    }

    if let nested = data as? [[String]] {
      return nested.flatMap { $0 }
    }

    if let nestedAny = data as? [Any] {
      return nestedAny.flatMap { item -> [String] in
        if let strings = item as? [String] {
          return strings
        }
        if let value = item as? String {
          return [value]
        }
        return []
      }
    }

    return []
  }

  func analysisManagerDidFail(withPoiError error: PLError!) {
    emitEvent([
      "type": "error",
      "message": error.errorDescription ?? "Analysis error",
    ])
  }

  func analysisManagerResponse(forBeaconMonitoring response: [AnyHashable: Any]!) {
    let nodeIds = parseNodeIds(from: response)
    if nodeIds.isEmpty {
      emitEvent([
        "type": "response",
        "rawResponse": String(describing: response ?? [:]),
      ])
      return
    }

    emitEvent([
      "type": "response",
      "nodeIds": nodeIds,
    ])
  }
}

extension AppDelegate: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
