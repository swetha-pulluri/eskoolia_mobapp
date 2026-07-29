pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Pinned below AGP 9's "built-in Kotlin" cutover: several plugin
    // dependencies (flutter_plugin_android_lifecycle, share_plus, ...) still
    // apply `org.jetbrains.kotlin.android` themselves unconditionally, which
    // AGP 9 rejects once built-in Kotlin takes over, while file_picker 11.x
    // conversely *relies* on built-in Kotlin once AGP >= 9. 8.11.1 is the top
    // of Flutter 3.44.1's fully-supported (zero-warning) AGP range and avoids
    // that conflict entirely — see DependencyVersionChecker.kt's warnAGPVersion.
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
