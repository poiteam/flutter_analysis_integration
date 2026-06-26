package com.poilabs.flutteranalysisintegration.flutter_analysis_integration

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

class MainActivity : FlutterActivity(), PoiResponseCallback {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Guard every SDK access: getInstance() throws if init failed in Application.
        if (!isSdkReady()) {
            return
        }
        PoiAnalysis.getInstance().setPoiResponseListener(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPlatform" -> result.success("android")
                "getUniqueId" -> {
                    result.success((application as? PoiAnalysisApplication)?.currentUniqueId ?: "")
                }
                "requestPermissions" -> {
                    requestRuntimePermissions()
                    result.success(true)
                }
                "updateUniqueId" -> {
                    val uniqueId = call.argument<String>("uniqueId")
                    if (uniqueId.isNullOrEmpty()) {
                        result.error(
                            "INVALID_ARGUMENT",
                            "uniqueId is required",
                            null,
                        )
                    } else {
                        if (!isSdkReady()) {
                            result.error(
                                "SDK_NOT_READY",
                                "PoiAnalysis SDK is not initialized",
                                null,
                            )
                        } else {
                            PoiAnalysis.getInstance().updateUniqueId(uniqueId)
                            (application as? PoiAnalysisApplication)?.updateCurrentUniqueId(uniqueId)
                            result.success(true)
                        }
                    }
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

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            },
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (grantResults.isEmpty()) {
            return
        }

        when (requestCode) {
            REQUEST_FOREGROUND_LOCATION,
            REQUEST_BACKGROUND_LOCATION,
            REQUEST_COARSE_LOCATION,
            REQUEST_BLUETOOTH_PERMISSION,
            REQUEST_NOTIFICATION_PERMISSION,
            -> {
                if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    requestRuntimePermissions()
                }
            }
        }
    }

    override fun onResponse(nodeIds: List<String>) {
        mainHandler.post {
            eventSink?.success(
                mapOf(
                    "type" to "response",
                    "nodeIds" to nodeIds,
                ),
            )
        }
    }

    override fun onFail(cause: Exception) {
        mainHandler.post {
            eventSink?.success(
                mapOf(
                    "type" to "error",
                    "message" to (cause.message ?: "Unknown error"),
                ),
            )
        }
    }

    private fun requestRuntimePermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (
                ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.ACCESS_FINE_LOCATION,
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                    REQUEST_FOREGROUND_LOCATION,
                )
                return
            }

            if (
                ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.ACCESS_BACKGROUND_LOCATION,
                ) != PackageManager.PERMISSION_GRANTED
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
                return
            }

            requestNotificationPermissionIfNeeded()
        } else if (
            ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION),
                REQUEST_COARSE_LOCATION,
            )
            return
        }

        requestNotificationPermissionIfNeeded()
    }

    private fun requestBluetoothPermissionsIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            requestNotificationPermissionIfNeeded()
            return
        }

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
            return
        }

        requestNotificationPermissionIfNeeded()
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return
        }

        val hasPermission = ActivityCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED

        if (!hasPermission) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                REQUEST_NOTIFICATION_PERMISSION,
            )
        }
    }

    private fun startScan() {
        if (!isSdkReady()) {
            eventSink?.success(
                mapOf(
                    "type" to "error",
                    "message" to "PoiAnalysis SDK is not initialized",
                ),
            )
            return
        }
        try {
            PoiAnalysis.getInstance().enable()
            // Mirror SDK sample: short delay before scanning after enable/permission flow.
            mainHandler.postDelayed({
                PoiAnalysis.getInstance().startScan(applicationContext)
                eventSink?.success(
                    mapOf(
                        "type" to "status",
                        "message" to "Scan started",
                    ),
                )
            }, SCAN_START_DELAY_MS)
        } catch (exception: SecurityException) {
            eventSink?.success(
                mapOf(
                    "type" to "error",
                    "message" to (exception.message ?: "Security exception"),
                ),
            )
        }
    }

    private fun stopScan() {
        if (!isSdkReady()) {
            return
        }
        PoiAnalysis.getInstance().stopScan()
        eventSink?.success(
            mapOf(
                "type" to "status",
                "message" to "Scan stopped",
            ),
        )
    }

    private fun isSdkReady(): Boolean {
        // Single source of truth for SDK init state set in Application.onCreate.
        return (application as? PoiAnalysisApplication)?.sdkInitialized == true
    }

    companion object {
        private const val METHOD_CHANNEL = "com.poilabs.analysis/poi_analysis"
        private const val EVENT_CHANNEL = "com.poilabs.analysis/poi_events"
        private const val SCAN_START_DELAY_MS = 5000L

        private const val REQUEST_FOREGROUND_LOCATION = 56
        private const val REQUEST_BACKGROUND_LOCATION = 57
        private const val REQUEST_COARSE_LOCATION = 58
        private const val REQUEST_BLUETOOTH_PERMISSION = 59
        private const val REQUEST_NOTIFICATION_PERMISSION = 60
    }
}
