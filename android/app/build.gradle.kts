import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
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
            "\"${localProperties.getProperty("poiAppId", "")}\"",
        )
        buildConfigField(
            "String",
            "POI_APP_SECRET",
            "\"${localProperties.getProperty("poiAppSecret", "")}\"",
        )
        buildConfigField(
            "String",
            "POI_UNIQUE_ID",
            "\"${localProperties.getProperty("poiUniqueId", "")}\"",
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
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("androidx.work:work-runtime-ktx:2.9.0")
}
