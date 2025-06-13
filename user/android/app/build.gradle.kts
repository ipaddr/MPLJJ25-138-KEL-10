// Path: android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // FlutterFire: Google Services plugin
    id("com.google.gms.google-services") version "4.4.1" apply false
}

android {
    namespace = "com.example.user"
    compileSdk = 34 // Atau sesuai kebutuhan

    defaultConfig {
        applicationId = "com.example.user"
        minSdk = 21 // Firebase butuh minSdk 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            // Jika belum punya release signingConfig, gunakan debug
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

// Terapkan plugin Google Services setelah konfigurasi Android
apply(plugin = "com.google.gms.google-services")
