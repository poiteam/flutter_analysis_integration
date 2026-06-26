plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.poilabs.flutteranalysisintegration.flutter_analysis_integration"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.poilabs.flutteranalysisintegration.flutter_analysis_integration"
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true

        buildConfigField(
            "String",
            "POI_APP_ID",
            "\"YOUR_PLACE_APP_ID\"",
        )
        buildConfigField(
            "String",
            "POI_APP_SECRET",
            "\"YOUR_PLACE_APP_SECRET\"",
        )
        buildConfigField(
            "String",
            "POI_UNIQUE_ID",
            "\"\"",
        )
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.github.poiteam:Android-Analysis-SDK:v3.11.6")
}
