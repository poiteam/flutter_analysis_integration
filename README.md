# PoilabsAnalysis Flutter Integration

## iOS

### INSTALLATION

To integrate PoilabsAnalysis into your Flutter iOS project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'PoilabsAnalysis', '3.8.13'
```

**SDK Version:** `3.8.13`

Then run:

```bash
cd ios && pod install
```

### PRE-REQUIREMENTS

To integrate this framework you should add some features to your project `Info.plist` file.

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

Bridge the native SDK to Flutter from `ios/Runner/AppDelegate.swift`. Set your
`APPLICATION_ID`, `APPLICATION_SECRET_KEY` and `UNIQUE_ID` where it fits your
app.

Start monitoring:

```swift
PLAnalysisSettings.sharedInstance()?.applicationId = APPLICATION_ID
PLAnalysisSettings.sharedInstance()?.applicationSecret = APPLICATION_SECRET_KEY
PLAnalysisSettings.sharedInstance()?.analysisUniqueIdentifier = UNIQUE_ID

PLConfigManager.sharedInstance().getReadyForTracking(completionHandler: { error in
    if error == nil {
        PLSuspendedAnalysisManager.sharedInstance().stopBeaconMonitoring()
        PLStandardAnalysisManager.sharedInstance().startBeaconMonitoring()
        PLStandardAnalysisManager.sharedInstance().delegate = self
    }
})
```

Stop monitoring:

```swift
PLStandardAnalysisManager.sharedInstance().stopBeaconMonitoring()
PLAnalysisSettings.sharedInstance()?.closeAllActions()
```

**PLAnalysisManagerDelegate**

```swift
func analysisManagerDidFail(withPoiError error: PLError!) { }

func analysisManagerResponse(forBeaconMonitoring response: [AnyHashable: Any]!) { }
```

To start suspended mode that allows track location when application is killed,
call the method below in `didFinishLaunchingWithOptions`:

```swift
if launchOptions?[.location] != nil,
   UIApplication.shared.applicationState == .background {
  PLSuspendedAnalysisManager.sharedInstance().startBeaconMonitoring()
}
```

Expose start/stop and delegate callbacks to Flutter with **MethodChannel** and
**EventChannel**. See the sample `AppDelegate.swift` in this repository.

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
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("androidx.work:work-runtime-ktx:2.9.0")
}
```

3. Enable multi dex in your android project  
   https://developer.android.com/studio/build/multidex

### PRE-REQUIREMENTS

In order to our SDK can work properly we need location permission and bluetooth usage for scanning for beacons.

**Android Manifest file**

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

**Note:** It does not affect the SDK how you request runtime permissions. The samples in documentation are just samples. Feel free to get permissions however you want.

### USAGE

After getting permissions you can now use PoiLabs Analysis SDK.

#### PoiAnalysisConfig

Provide your configuration settings for SDK to work. Constructor takes
`APPLICATION_ID`, `APPLICATION_SECRET_KEY`, `UNIQUE_ID` and they are mandatory.

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
poiAnalysisConfig.setServiceNotificationTitle("Searching for campaigns...")
```

**setForegroundServiceNotificationChannelProperties(String, String)**

```kotlin
poiAnalysisConfig.setForegroundServiceNotificationChannelProperties("Channel Name", "Channel Description")
```

**setForegroundServiceNotificationIconResourceId(Int)**

```kotlin
poiAnalysisConfig.setForegroundServiceNotificationIconResourceId(R.drawable.ic_notification)
```

Initialize in your **Application** class `onCreate()` — first access to
`PoiAnalysis.getInstance()` must happen here:

```kotlin
PoiAnalysis.getInstance(this, poiAnalysisConfig)
PoiAnalysis.getInstance().enable()
```

#### PoiAnalysis

For callbacks from SDK implement **PoiResponseCallback**:

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

After user login, update the unique id for better classification:

```kotlin
PoiAnalysis.getInstance().updateUniqueId(NEW_UNIQUE_ID)
```

Bridge start/stop and `PoiResponseCallback` to Flutter with **MethodChannel** and
**EventChannel** from `MainActivity`. See the sample files in this repository.

---

## Flutter

Import platform channels:

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

Listen for SDK responses (node ids, errors):

```dart
_eventChannel.receiveBroadcastStream().listen((event) {
  final data = Map<dynamic, dynamic>.from(event as Map);
  if (data['type'] == 'response') {
    final nodeIds = (data['nodeIds'] as List?)?.cast<String>() ?? [];
    print('Node IDs: $nodeIds');
  }
});
```

Channel names used in the sample app:

- MethodChannel: `com.poilabs.analysis/poi_analysis`
- EventChannel: `com.poilabs.analysis/poi_events`
