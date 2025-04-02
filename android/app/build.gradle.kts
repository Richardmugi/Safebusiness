plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.safebusiness"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.safebusiness"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    signingConfigs {
        create("release") {
            // Path to your keystore file
            storeFile = file("../app/my-release-key.jks")
            storePassword = "R1C@rd0$"
            keyAlias = "my-key-alias"
            keyPassword = "R1C@rd0$"
        }
    }

    buildTypes {
        release {
            // Enable code shrinking (Proguard/R8)
            minifyEnabled true
            // Shrink unused resources
            shrinkResources true
            // Add your release signing config here
            signingConfig signingConfigs.release
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.8.22") // Ensure this matches your Kotlin version
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))
    implementation("com.google.firebase:firebase-analytics")
    // Firebase Cloud Messaging (FCM) - Required for push notifications
    implementation("com.google.firebase:firebase-messaging")
    implementation("androidx.work:work-runtime:2.8.1")
    // Add other dependencies here
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

flutter {
    source = "../.."
}
