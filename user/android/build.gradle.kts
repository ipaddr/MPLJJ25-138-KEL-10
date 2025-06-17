// Path: android/build.gradle.kts

buildscript {
    // Definisi variabel menggunakan 'val' di Kotlin DSL, bukan 'ext'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Versi Android Gradle Plugin (AGP) - PENTING!
        // Untuk Flutter 3.32.x dan Kotlin 1.9.x, AGP 8.x sangat direkomendasikan.
        // Anda mungkin perlu menyesuaikan ini jika ada error build di masa depan.
        classpath("com.android.tools.build:gradle:8.4.0") // <-- UBAH KE SINTAKS KOTLIN DSL

        // Firebase Google Services Plugin (versi Anda sudah cukup baru)
        classpath("com.google.gms:google-services:4.3.15")

        // Kotlin Gradle Plugin (versi Anda sudah cukup baru)
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    }
}

// Global properties untuk project (Kotlin DSL approach)
// Ini akan membuat properti tersedia untuk sub-proyek (misalnya app/build.gradle.kts)
// dengan mengakses `rootProject.extra["propertyName"]`
// Atau lebih baik, langsung tentukan di `app/build.gradle.kts` menggunakan `flutter.compileSdkVersion`
// jika Anda menggunakan plugin Flutter terbaru.
// Contoh:
// rootProject.extra["compileSdkVersion"] = 34
// rootProject.extra["minSdkVersion"] = 21
// rootProject.extra["targetSdkVersion"] = 34


allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Optional: Memindahkan build directory ke luar folder android
// Pastikan path ini benar dan valid di sistem Anda.
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    project.layout.buildDirectory.set(newBuildDir.dir(project.name))
    // evaluationDependsOn(':app') sering tidak diperlukan lagi di proyek Flutter modern
    // jika Anda menggunakan `flutter.compileSdkVersion` dan sejenisnya.
    // Jika ada error, Anda bisa mencoba mengaktifkan kembali ini.
    // project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}