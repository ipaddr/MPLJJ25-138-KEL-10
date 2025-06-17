// Path: android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // FlutterFire: Google Services plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.user"
    compileSdk = 35 // Atau sesuai kebutuhan
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.user"
        minSdk = 21 // Firebase butuh minSdk 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true 
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
