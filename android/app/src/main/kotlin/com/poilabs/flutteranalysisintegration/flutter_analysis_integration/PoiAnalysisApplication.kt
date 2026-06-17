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
            val config = PoiAnalysisConfig(APP_ID, SECRET_ID, UNIQUE_ID)
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

    companion object {
        const val APP_ID = "d0ba2050-8754-4776-8c62-7a93dcba0da2"
        const val SECRET_ID = "b7cfb418-8211-4773-ae1a-97ec308165ce"
        const val UNIQUE_ID = "android_config_timer_test"
    }
}
