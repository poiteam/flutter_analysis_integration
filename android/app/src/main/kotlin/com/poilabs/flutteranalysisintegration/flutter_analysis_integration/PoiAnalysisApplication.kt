package com.poilabs.flutteranalysisintegration.flutter_analysis_integration

import android.app.Application
import android.content.Intent
import android.provider.Settings
import android.util.Log
import getpoi.com.poibeaconsdk.PoiAnalysis
import getpoi.com.poibeaconsdk.models.PoiAnalysisConfig

class PoiAnalysisApplication : Application() {

    var sdkInitialized: Boolean = false
        private set
    var currentUniqueId: String = ""
        private set

    override fun onCreate() {
        super.onCreate()
        initializeSdk()
    }

    private fun initializeSdk() {
        // SDK requires a non-empty unique id. If build-time value is missing,
        // fall back to device id so initialization cannot fail on empty unique id.
        val uniqueId = BuildConfig.POI_UNIQUE_ID
            .takeIf { it.isNotBlank() }
            ?: Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
            ?: packageName
        currentUniqueId = uniqueId

        try {
            val config = PoiAnalysisConfig(
                BuildConfig.POI_APP_ID,
                BuildConfig.POI_APP_SECRET,
                uniqueId,
            )
            config.setEnabled(true)
            config.setOpenSystemBluetooth(false)
            config.setForegroundServiceIntent(
                Intent(this, MainActivity::class.java),
            )
            config.enableForegroundService()
            config.setServiceNotificationTitle("Searching for campaigns...")
            config.setForegroundServiceNotificationChannelProperties(
                "Poilabs Analysis",
                "Beacon scanning service",
            )
            PoiAnalysis.getInstance(this, config)
            PoiAnalysis.getInstance().enable()
            sdkInitialized = true
        } catch (exception: Exception) {
            sdkInitialized = false
            Log.e("PoiAnalysisApplication", "PoiAnalysis initialization failed", exception)
        }
    }

    fun updateCurrentUniqueId(value: String) {
        // Keep native-side value in sync with runtime updates from Flutter.
        currentUniqueId = value
    }
}
