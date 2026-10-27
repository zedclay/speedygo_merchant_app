plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.speedygo.speedygo_merchant_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.speedygo.speedygo_merchant_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleMapsApiKey"] = androidMapsSdkKey()
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

fun androidMapsSdkKey(): String {
    val fromEnv = System.getenv("GOOGLE_MAPS_ANDROID_API_KEY")?.trim().orEmpty()
    if (fromEnv.isNotEmpty()) {
        return fromEnv
    }
    val packed = (project.findProperty("dart-defines") as? String)
        ?: System.getenv("DART_DEFINES")
        ?: return ""
    packed.split(",").forEach { encoded ->
        val decoded = runCatching {
            String(java.util.Base64.getDecoder().decode(encoded), Charsets.UTF_8)
        }.getOrNull() ?: return@forEach
        val idx = decoded.indexOf("=")
        if (idx > 0 && decoded.substring(0, idx) == "GOOGLE_MAPS_ANDROID_API_KEY") {
            return decoded.substring(idx + 1)
        }
    }
    return ""
}
