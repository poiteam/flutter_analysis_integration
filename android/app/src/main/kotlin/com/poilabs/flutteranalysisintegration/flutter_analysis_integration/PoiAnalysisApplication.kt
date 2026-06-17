package com.poilabs.flutteranalysisintegration.flutter_analysis_integration

import android.app.Application
import android.content.Intent
import getpoi.com.poibeaconsdk.PoiAnalysis
import getpoi.com.poibeaconsdk.models.PoiAnalysisConfig

class PoiAnalysisApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        initializeSdk()
    }

    private fun initializeSdk() {
        try {
            val config = PoiAnalysisConfig(
                BuildConfig.POI_APP_ID,
                BuildConfig.POI_APP_SECRET,
                BuildConfig.POI_UNIQUE_ID,
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
        } catch (exception: Exception) {
            exception.printStackTrace()
        }
    }
}
