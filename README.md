# PoilabsAnalysis Flutter Integration

PoiLabs Analysis SDK is a data analysis library. It provides data for analysing POI Beacons data.

- [iOS](#ios)
- [Android](#android)
- [Flutter](#flutter)

---

## iOS

### INSTALLATION

#### CocoaPods

To integrate PoilabsAnalysis into your Flutter iOS project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'PoilabsAnalysis', '3.8.28'
```

**SDK Version:** `3.8.28`

Then run:

```bash
cd ios && pod install
```

#### Manually

You can add PoilabsAnalysis.xcframework file to your "Frameworks, Libraries, and Embedded Content" in your Project's General tab.

### PRE-REQUIREMENTS

To integrate this framework you should add some features to your project `Info.plist` file.

#### Location Permission

This framework give support both Always and WhenInUse authorization.

- Privacy - Location Usage Description
- Privacy - Location When In Use Usage Description
- Privacy - Location Always Usage Description
- Privacy - Location Always and When In Use Usage Description

#### Required Background Modes

You should add "Location updates" and "Uses Bluetooth LE accessories" Background Modes from Project's Signing & Capabilities tab.

### USAGE

You should import framework in your `AppDelegate.swift`:

```swift
import PoilabsAnalysis
```

In `applicationDidBecomeActive:` method you should activate the framework:

```swift
PLAnalysisSettings.sharedInstance().applicationId = APPLICATION_ID
PLAnalysisSettings.sharedInstance().applicationSecret = APPLICATION_SECRET_KEY
PLAnalysisSettings.sharedInstance().analysisUniqueIdentifier = UNIQUE_ID

PLConfigManager.sharedInstance().getReadyForTracking(completionHandler: { error in
    if error != nil {
        if let anError = error {
            print("Error Desc \(anError)")
        }
    } else {
        print("Error Nil")
        PLSuspendedAnalysisManager.sharedInstance()?.stopBeaconMonitoring()
        PLStandardAnalysisManager.sharedInstance()?.startBeaconMonitoring()
        PLStandardAnalysisManager.sharedInstance().delegate = self as? PLAnalysisManagerDelegate
    }
})
```

#### For background tracking

In `didFinishLaunchingWithOptions:` method you should activate the framework:

```swift
if launchOptions?[UIApplication.LaunchOptionsKey.location] != nil {
    if application.applicationState == UIApplication.State.background {
        PLSuspendedAnalysisManager.sharedInstance()?.startBeaconMonitoring()
    }
}
```

#### Close All Actions

If you want to close all location services and regions for SDK you can call this method:

```swift
PLAnalysisSettings.sharedInstance()?.closeAllActions()
```

#### Flutter bridge

Register **MethodChannel** and **EventChannel** in `AppDelegate.swift`, call the SDK methods above from the channel handler, and forward `PLAnalysisManagerDelegate` callbacks to Flutter:

```swift
private let methodChannelName = "com.poilabs.analysis/poi_analysis"
private let eventChannelName = "com.poilabs.analysis/poi_events"

// MethodChannel: requestPermissions, startScan, stopScan
// EventChannel: forward nodeIds / errors from PLAnalysisManagerDelegate
```

See `ios/Runner/AppDelegate.swift` in this repository for the full implementation.

### TESTING

You can only test PoilabsAnalysis sdk with real device. You can run on simulator but for testing you should **run on a iPhone**.

Some test cases are only for versions **3.8.2 or above**. For better test cases, please update PoilabsAnalysis if you integrated a lower version.

#### Initialization

Error of below method should be nil.

```swift
PLConfigManager.sharedInstance().getReadyForTracking(completionHandler: { error in

})
```

##### Error descriptions

1. Request failed: forbidden (403)
   - Please check APPLICATION ID and APPLICATION SECRET KEY
2. Your Application id is Unavailable
   - Set `PLAnalysisSettings.sharedInstance().applicationId`
3. Your Application secret is Unavailable
   - Set `PLAnalysisSettings.sharedInstance().applicationSecret`
4. Your Analysis uniqueId is Unavailable
   - Set `PLAnalysisSettings.sharedInstance().analysisUniqueIdentifier`

#### Foreground Monitoring

Foreground monitoring means scaning beacon and returning relevant node's id when application is active. If you initilize PoilabsAnalysis sdk with nil error and start beacon monitoring of **PLStandardAnalysisManager**, node ids will return to callback below.

```swift
extension AppDelegate: PLAnalysisManagerDelegate {
    func analysisManagerResponse(forBeaconMonitoring response: [AnyHashable : Any]!) {
        print(response)
    }
}
```

For getting response, you have to be **nearby of a beacon** with data which are shared by PoiLabs.

Trigger of this callback can take time, please wait for minimum 30 seconds after start monitoring.

Example response:

```json
{
  "data": [
    ["nodeid1", "nodeid2"],
    ["nodeid1"],
    ["nodeid1"]
  ],
  "status": 1
}
```

If you can get a response like this, foreground monitoring is successfully integrated.

In Flutter, the same payload is forwarded on EventChannel as `nodeIds`.

#### Background Monitoring

Background monitoring means scaning beacon when application is killed.

Before start to test please make sure **always location permission** is given.

To activate background mode, you should kill application and lock the screen. After you show the lock screen or unlock your iPhone, background monitoring will start if you integrate it, like in the section **USAGE / For background tracking**.

For getting response, you have to be **nearby of a beacon** with data which are shared by PoiLabs.

You can test background monitoring on Console. Open Console application on your Mac. Type **PLAnalysisSdk** to search field. Select your iPhone from Devices section on the left. Press start button.

First you will see start log and then if sdk find any beacon and get its id, you will see response log. Examples of logs are below.

```
PLAnalysisSdk <PLSuspendedAnalysisManager: 0x...>->SuspendedAnalysisManager startBeaconMonitoring

PLAnalysisSdk <PLSuspendedAnalysisManager: 0x...>->Response {
    data =     ( ( "nodeid1", "nodeid2" ),
                ( "nodeid1" )
    );
    status = 1;
}
```

If you get these log, background monitoring is successfully integrated.

---

## Android

### INSTALLATION

You can download our SDK via Gradle with following below steps.

**SDK Version:** `v3.11.6`

1. Add jitpack dependency to your project level `build.gradle.kts` file with their tokens.  
   **JITPACK_TOKEN** is a token that PoiLabs will provide for you it will allow you to download our sdk.

```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://jitpack.io")
            credentials { username = "JITPACK_TOKEN" }
        }
    }
}
```

2. Add PoiLabs Analysis SDK dependency to your app level `build.gradle.kts` file

```kotlin
dependencies {
    implementation("com.github.poiteam:Android-Analysis-SDK:v3.11.6")
}
```

3. Enable multi dex in your android project (`multiDexEnabled = true` in `defaultConfig`)  
   https://developer.android.com/studio/build/multidex

4. Minimum requirements

| Supported Minimum Android |
| --- |
| Android 4.3 (API level 18) |

### PRE-REQUIREMENTS

In order to our SDK can work properly we need location permission and bluetooth usage for scanning for beacons.

1. **Android Manifest file**

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

2. Request runtime permissions before starting scan. See `MainActivity.kt` in this repository for a sample permission flow.

**Note:** It does not affect the SDK how you request runtime permissions. The samples in documentation are just samples. Feel free to get permissions however you want.

### USAGE

After getting permissions you can now use PoiLabs Analysis SDK.

#### PoiAnalysisConfig

Constructor takes `APPLICATION_ID`, `APPLICATION_SECRET_KEY`, `UNIQUE_ID` and they are mandatory.

```kotlin
val poiAnalysisConfig = PoiAnalysisConfig("APPLICATION_ID", "APPLICATION_SECRET_KEY", "UNIQUE_ID")
```

**setEnabled(true/false)**

```kotlin
poiAnalysisConfig.setEnabled(true)
```

**setOpenSystemBluetooth(true/false)**  
Using this method needs `BLUETOOTH_CONNECT` permission. Without it, your app will crash on Android 12. Use with caution.

```kotlin
poiAnalysisConfig.setOpenSystemBluetooth(false)
```

**setForegroundServiceIntent(Intent)**

```kotlin
poiAnalysisConfig.setForegroundServiceIntent(Intent(this, MainActivity::class.java))
```

**enableForegroundService()**

```kotlin
poiAnalysisConfig.enableForegroundService()
```

**setServiceNotificationTitle(String)**

```kotlin
poiAnalysisConfig.setServiceNotificationTitle(FORE_GROUND_SERVICE_NOTIFICATION_TITLE)
```

**setForegroundServiceNotificationChannelProperties(String, String)**

```kotlin
poiAnalysisConfig.setForegroundServiceNotificationChannelProperties(CHANNEL_NAME, CHANNEL_DESCRIPTION)
```

**setForegroundServiceNotificationIconResourceId(Int)**

```kotlin
poiAnalysisConfig.setForegroundServiceNotificationIconResourceId(R.drawable.ic_notification)
```

Initialize in your **Application** class `onCreate()` — first access to `PoiAnalysis.getInstance()` must happen here:

```kotlin
PoiAnalysis.getInstance(this, poiAnalysisConfig)
PoiAnalysis.getInstance().enable()
```

#### PoiAnalysis

For callbacks implement **PoiResponseCallback**:

1. `onResponse(nodeIds: List<String>)` — node ids of detected beacons  
2. `onFail(cause: Exception)` — error from SDK

```kotlin
PoiAnalysis.getInstance().setPoiResponseListener(object : PoiResponseCallback {
    override fun onResponse(nodeIds: List<String>) { }
    override fun onFail(cause: Exception) { }
})
```

#### Starting or Stopping SDK

**Disclaimer: THE ANALYSIS SDK WILL WORK ONLY IF YOU START SCAN**

```kotlin
PoiAnalysis.getInstance().enable()
PoiAnalysis.getInstance().startScan(applicationContext)
PoiAnalysis.getInstance().stopScan()
```

#### Update Unique Id

```kotlin
PoiAnalysis.getInstance().updateUniqueId(NEW_UNIQUE_ID)
```

#### Flutter bridge

**`PoiAnalysisApplication.kt`** — SDK init (see above).

**`MainActivity.kt`** — register channels and forward SDK callbacks:

```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.poilabs.analysis/poi_analysis")
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "requestPermissions" -> { /* ... */ result.success(true) }
            "startScan" -> { /* PoiAnalysis.getInstance().startScan(...) */ result.success(true) }
            "stopScan" -> { /* PoiAnalysis.getInstance().stopScan() */ result.success(true) }
            else -> result.notImplemented()
        }
    }

// EventChannel: send nodeIds from onResponse / errors from onFail
```

See `android/app/src/main/kotlin/.../MainActivity.kt` in this repository for the full implementation.

### Proguard Rules

```
-keep public class getpoi.com.poibeaconsdk.PoiAnalysis
-keep public interface getpoi.com.poibeaconsdk.models.BeaconScanCallback
-keep public interface getpoi.com.poibeaconsdk.models.PoiResponseCallback
-keep class getpoi.com.poibeaconsdk.PoiScanner* { *; }
-keep class getpoi.com.poibeaconsdk.models.** { *; }
-keep class getpoi.com.poibeaconsdk.models.PoiAnalysisConfig { *; }
-dontwarn getpoi.com.poibeaconsdk.**
-dontwarn com.poilabs.poiutil.**
```

### F.A.Q

**Why am I getting `failed to resolve` error in Gradle?**  
Check that the JitPack token is correct. Common codes: 401 (no token), 403 (no access), 404 (wrong version/tag).

**Will my app crash if user rejects permissions?**  
No. If permissions are not granted the SDK waits and works on the next session once permissions are granted.

**Which permissions does the app need?**

- Location Permission (Precise location)
- Background Location Permission
- BLUETOOTH_SCAN Permission
- BLUETOOTH_CONNECT Permission (if you auto-enable bluetooth)
- Push notification Permission (if you enable foreground scan)

---

## Flutter

Call the native SDK from Dart over platform channels.

```dart
import 'package:flutter/services.dart';

const _methodChannel = MethodChannel('com.poilabs.analysis/poi_analysis');
const _eventChannel = EventChannel('com.poilabs.analysis/poi_events');
```

Request permissions and start scanning:

```dart
await _methodChannel.invokeMethod('requestPermissions');
await _methodChannel.invokeMethod('startScan');
```

Stop scanning:

```dart
await _methodChannel.invokeMethod('stopScan');
```

Listen for node ids:

```dart
_eventChannel.receiveBroadcastStream().listen((event) {
  final data = Map<dynamic, dynamic>.from(event as Map);
  if (data['type'] == 'response') {
    final nodeIds = (data['nodeIds'] as List?)?.cast<String>() ?? [];
    print('Node IDs: $nodeIds');
  }
});
```

Channel names:

- MethodChannel: `com.poilabs.analysis/poi_analysis`
- EventChannel: `com.poilabs.analysis/poi_events`
