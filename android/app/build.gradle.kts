plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Community builds always use the committed public key. Local properties and
// NLPA_* signing overrides belong to private brand builds, not this recipe.

android {
    namespace = "ee.nekoko.nlpa2"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        buildConfig = true
        // The QRTR user service is described by an AIDL interface.
        aidl = true
    }


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    signingConfigs {
        create("community") {
            storeFile = file("community.jks")
            storePassword = "CommunityKey"
            keyAlias = "communitykey"
            keyPassword = "CommunityKey"
        }
    }

    flavorDimensions += "version"

    productFlavors {
        create("community") {
            dimension = "version"
            applicationId = "ee.nekoko.nlpa2.open"
            manifestPlaceholders["appName"] = "NekokoLPA 2 Community"
            signingConfig = signingConfigs.getByName("community")
        }

        create("privileged") {
            dimension = "version"
            applicationId = "ee.nekoko.nlpa2"
            manifestPlaceholders["appName"] = "NekokoLPA 2 Community Rooted"
            signingConfig = signingConfigs.getByName("community")
        }

    }

    // Public rooted builds share the Community dolphin artwork.
    sourceSets {
        getByName("privileged") {
            res.setSrcDirs(listOf("src/community/res"))
        }
    }

    defaultConfig {
        applicationId = "ee.nekoko.nlpa2.open"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Force version code to match flutter.versionCode, preventing ABI splitting logic from changing it
            applicationVariants.all {
                outputs.all {
                    (this as? com.android.build.gradle.internal.api.ApkVariantOutputImpl)?.versionCodeOverride = flutter.versionCode
                }
            }
        }
        debug {
            signingConfig = signingConfigs.getByName("community")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Only the `shell` user may open a QRTR socket, so the app asks Shizuku to
    // run a service there and takes the descriptor back over Binder.
    implementation("dev.rikka.shizuku:api:13.1.5")
    implementation("dev.rikka.shizuku:provider:13.1.5")

    testImplementation("junit:junit:4.13.2")
}
