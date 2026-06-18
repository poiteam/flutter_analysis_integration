# PoilabsAnalysis Flutter Integration

This guide explains how to integrate the **PoilabsAnalysis** SDK into a Flutter
application on both **iOS** and **Android**, and how to drive it from Dart over
platform channels.

---

## iOS

### INSTALLATION

To integrate PoilabsAnalysis into your Flutter iOS project using CocoaPods, add
it to your `ios/Podfile`:

```ruby
pod 'PoilabsAnalysis', '3.8.13'
```

**SDK Version:** `3.8.13`

Then run:

```bash
cd ios && pod install
```

### PRE-REQUIREMENTS

To integrate this framework you should add some features to your project
`Info.plist` file.

Privacy - Location When In Use Usage Description

Privacy - Location Always Usage Description

Privacy - Location Always and When In Use Usage Description

Add the following values under `UIBackgroundModes`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>bluetooth-central</string>
</array>
```

### USAGE

Update your `ios/Runner/AppDelegate.swift` to bridge the native SDK to Flutter.
Set your Poilabs credentials where it fits your app (constants below, a config
file, environment variables, etc.).

```swift
import Flutter
import UIKit
import CoreLocation
import PoilabsAnalysis

private let methodChannelName = "com.poilabs.analysis/poi_analysis"
private let eventChannelName = "com.poilabs.analysis/poi_events"

@main
@objc class AppDelegate: FlutterAppDelegate, PLAnalysisManagerDelegate {
  private var eventSink: FlutterEventSink?
  private let locationManager = CLLocationManager()

  private let appId = "YOUR_APPLICATION_ID"
  private let applicationSecret = "YOUR_APPLICATION_SECRET"
  private let uniqueId = "YOUR_UNIQUE_ID"

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

    FlutterEventChannel(
      name: eventChannelName,
      binaryMessenger: controller.binaryMessenger
    ).setStreamHandler(self)
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
          self.emitEvent(["type": "error", "message": error.errorDescription ?? "Config error"])
          return
        }

        PLSuspendedAnalysisManager.sharedInstance().stopBeaconMonitoring()
        PLStandardAnalysisManager.sharedInstance().startBeaconMonitoring()
        PLStandardAnalysisManager.sharedInstance().delegate = self
        self.emitEvent(["type": "status", "message": "Scan started"])
      }
    })
  }

  private func stopMonitoring() {
    PLStandardAnalysisManager.sharedInstance().stopBeaconMonitoring()
    PLAnalysisSettings.sharedInstance()?.closeAllActions()
    emitEvent(["type": "status", "message": "Scan stopped"])
  }

  private func emitEvent(_ payload: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(payload)
    }
  }

  func analysisManagerDidFail(withPoiError error: PLError!) {
    emitEvent(["type": "error", "message": error.errorDescription ?? "Analysis error"])
  }

  func analysisManagerResponse(forBeaconMonitoring response: [AnyHashable: Any]!) {
    emitEvent(["type": "response", "nodeIds": parseNodeIds(from: response)])
  }

  private func parseNodeIds(from response: [AnyHashable: Any]) -> [String] {
    guard let data = response["data"] else { return [] }
    if let nodeIds = data as? [String] { return nodeIds }
    if let nested = data as? [[String]] { return nested.flatMap { $0 } }
    return []
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
```

To start suspended mode that allows tracking location when the application is
killed, you should call the method below in `didFinishLaunchingWithOptions`:

```swift
if launchOptions?[.location] != nil,
   UIApplication.shared.applicationState == .background {
  PLSuspendedAnalysisManager.sharedInstance().startBeaconMonitoring()
}
```

---

## Android

### INSTALLATION

You can download our SDK via Gradle with the steps below.

**SDK Version:** `v3.11.6`

1. Add jitpack dependency to your project level `android/build.gradle.kts` with
   your token. **JITPACK_TOKEN** is a token that PoiLabs will provide for you;
   it allows you to download our SDK.

```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://jitpack.io")
            credentials {
                username = "JITPACK_TOKEN"
            }
        }
    }
}
```

2. Add the PoiLabs Analysis SDK dependency to your app level
   `android/app/build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.github.poiteam:Android-Analysis-SDK:v3.11.6")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("androidx.work:work-runtime-ktx:2.9.0")
}
```

3. The SDK needs location and bluetooth permissions to scan for beacons. Add the
   following to your **Android Manifest** file:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

Register your custom Application class:

```xml
<application android:name=".PoiAnalysisApplication" ...>
```

### USAGE

#### PoiAnalysisApplication.kt

Initialize the SDK in your Application class. The first access to
`PoiAnalysis.getInstance()` must happen in `Application.onCreate()`. Pass your
Poilabs credentials (hard-coded, `BuildConfig`, remote config, etc.):

```kotlin
class PoiAnalysisApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        val config = PoiAnalysisConfig(
            "YOUR_APPLICATION_ID",
            "YOUR_APPLICATION_SECRET",
            "YOUR_UNIQUE_ID",
        )
        config.setEnabled(true)
        config.setOpenSystemBluetooth(false)
        config.setForegroundServiceIntent(Intent(this, MainActivity::class.java))
        config.enableForegroundService()
        config.setServiceNotificationTitle("Searching for campaigns...")
        config.setForegroundServiceNotificationChannelProperties("Poilabs Analysis", "Beacon scanning service")

        PoiAnalysis.getInstance(this, config)
        PoiAnalysis.getInstance().enable()
    }
}
```

#### MainActivity.kt

Add the platform channel bridge and the runtime permission flow to your
`MainActivity.kt`. The permission flow is requested step by step
(fine location → background location → bluetooth) and continues from the result
callback as each permission is granted.

```kotlin
class MainActivity : FlutterActivity(), PoiResponseCallback {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        PoiAnalysis.getInstance().setPoiResponseListener(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPlatform" -> result.success("android")
                    "requestPermissions" -> {
                        requestRuntimePermissions()
                        result.success(true)
                    }
                    "startScan" -> {
                        startScan()
                        result.success(true)
                    }
                    "stopScan" -> {
                        stopScan()
                        result.success(true)
                    }
                    "getSdkVersion" -> result.success("3.11.6")
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (grantResults.isEmpty()) return

        when (requestCode) {
            REQUEST_FOREGROUND_LOCATION,
            REQUEST_BACKGROUND_LOCATION,
            REQUEST_COARSE_LOCATION,
            REQUEST_BLUETOOTH_PERMISSION,
            -> {
                if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    requestRuntimePermissions()
                }
            }
        }
    }

    private fun requestRuntimePermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                    REQUEST_FOREGROUND_LOCATION,
                )
                return
            }

            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_BACKGROUND_LOCATION)
                != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
                    REQUEST_BACKGROUND_LOCATION,
                )
                return
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                requestBluetoothPermissionsIfNeeded()
            }
        } else if (
            ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION),
                REQUEST_COARSE_LOCATION,
            )
        }
    }

    private fun requestBluetoothPermissionsIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return

        val hasBluetoothPermission = ActivityCompat.checkSelfPermission(
            this,
            Manifest.permission.BLUETOOTH_CONNECT,
        ) == PackageManager.PERMISSION_GRANTED

        if (!hasBluetoothPermission) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.BLUETOOTH_CONNECT,
                    Manifest.permission.BLUETOOTH_SCAN,
                ),
                REQUEST_BLUETOOTH_PERMISSION,
            )
        }
    }

    private fun startScan() {
        try {
            PoiAnalysis.getInstance().enable()
            mainHandler.postDelayed({
                PoiAnalysis.getInstance().startScan(applicationContext)
                eventSink?.success(mapOf("type" to "status", "message" to "Scan started"))
            }, SCAN_START_DELAY_MS)
        } catch (exception: SecurityException) {
            eventSink?.success(
                mapOf("type" to "error", "message" to (exception.message ?: "Security exception")),
            )
        }
    }

    private fun stopScan() {
        PoiAnalysis.getInstance().stopScan()
        eventSink?.success(mapOf("type" to "status", "message" to "Scan stopped"))
    }

    override fun onResponse(nodeIds: List<String>) {
        mainHandler.post {
            eventSink?.success(mapOf("type" to "response", "nodeIds" to nodeIds))
        }
    }

    override fun onFail(cause: Exception) {
        mainHandler.post {
            eventSink?.success(mapOf("type" to "error", "message" to (cause.message ?: "Unknown error")))
        }
    }

    companion object {
        private const val METHOD_CHANNEL = "com.poilabs.analysis/poi_analysis"
        private const val EVENT_CHANNEL = "com.poilabs.analysis/poi_events"
        private const val SCAN_START_DELAY_MS = 5000L

        private const val REQUEST_FOREGROUND_LOCATION = 56
        private const val REQUEST_BACKGROUND_LOCATION = 57
        private const val REQUEST_COARSE_LOCATION = 58
        private const val REQUEST_BLUETOOTH_PERMISSION = 59
    }
}
```

Required imports for `MainActivity.kt`:

```kotlin
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import getpoi.com.poibeaconsdk.PoiAnalysis
import getpoi.com.poibeaconsdk.models.PoiResponseCallback
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
```

---

## Flutter

The native side communicates with Dart over two channels:

- a **MethodChannel** (`com.poilabs.analysis/poi_analysis`) for commands you send
  to the SDK, and
- an **EventChannel** (`com.poilabs.analysis/poi_events`) for the events the SDK
  streams back.

### Methods you can call

| Method | Returns | Description |
|--------|---------|-------------|
| `getPlatform` | `String` | `"ios"` / `"android"` |
| `getSdkVersion` | `String` | Native SDK version |
| `requestPermissions` | `bool` | Triggers the runtime permission flow |
| `startScan` | `bool` | Starts beacon scanning |
| `stopScan` | `bool` | Stops beacon scanning |

### Events you receive

Every event is a map with a `type` field. Handle **all** types — errors and
status updates also arrive on this stream, not only beacon responses:

| `type` | Extra fields | Meaning |
|--------|--------------|---------|
| `response` | `nodeIds: List<String>` **or** `rawResponse: String` | Detected beacon node ids. On iOS, when ids can't be parsed the raw payload is sent as `rawResponse`. |
| `error` | `message: String` | SDK / config / permission failure |
| `status` | `message: String` | Lifecycle info, e.g. `"Scan started"`, `"Scan stopped"` |

### Import the platform channels

```dart
import 'package:flutter/services.dart';

const _methodChannel = MethodChannel('com.poilabs.analysis/poi_analysis');
const _eventChannel = EventChannel('com.poilabs.analysis/poi_events');
```

### Listen for every event type

```dart
_eventChannel.receiveBroadcastStream().listen((event) {
  final data = Map<dynamic, dynamic>.from(event as Map);

  switch (data['type']) {
    case 'response':
      final nodeIds = (data['nodeIds'] as List?)?.cast<String>() ?? [];
      if (nodeIds.isNotEmpty) {
        print('Node IDs: $nodeIds');
      } else if (data['rawResponse'] != null) {
        print('Raw response: ${data['rawResponse']}');
      }
    case 'status':
      print('Status: ${data['message']}');
    case 'error':
      print('Error: ${data['message']}');
  }
});
```

### Read platform info (optional)

```dart
final platform = await _methodChannel.invokeMethod<String>('getPlatform');
final sdkVersion = await _methodChannel.invokeMethod<String>('getSdkVersion');
```

### Request permissions, then start scanning

Request permissions first and start the scan from a **separate user action**
(e.g. a button). The permission dialog is asynchronous, so do not assume the
permission is already granted on the line right after `requestPermissions`:

```dart
// On startup:
await _methodChannel.invokeMethod('requestPermissions');

// Later, after the user grants permission (e.g. on a "Start" button):
await _methodChannel.invokeMethod('startScan');
```

Stop scanning:

```dart
await _methodChannel.invokeMethod('stopScan');
```

> **Reference app.** This repository contains a working sample under
> `lib/core/platform` and `lib/features/analysis`. Credentials and the JitPack
> token in that sample are loaded from local config files so they are not
> committed to this repo; use the same approach or hard-code values in your own
> project as you prefer.
