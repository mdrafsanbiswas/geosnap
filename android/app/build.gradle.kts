import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use(::load)
    }
}

val mapsApiKeyProperties = Properties().apply {
    val mapsApiKeyFile = rootProject.file("maps-api-key.properties")
    if (mapsApiKeyFile.exists()) {
        mapsApiKeyFile.inputStream().use(::load)
    }
}

val mapsApiKey =
    mapsApiKeyProperties.getProperty("MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: (project.findProperty("MAPS_API_KEY") as String?)?.takeIf { it.isNotBlank() }
        ?: localProperties.getProperty("MAPS_API_KEY")?.takeIf { it.isNotBlank() }
        ?: System.getenv("MAPS_API_KEY")?.takeIf { it.isNotBlank() }

if (mapsApiKey == null) {
    logger.warn(
        "MAPS_API_KEY is not set. Google Maps will appear blank in the app.",
    )
}

android {
    namespace = "com.example.geosnap"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.geosnap"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey ?: ""
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
