import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties().apply {
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.isFile) {
        propertiesFile.inputStream().use { load(it) }
    }
}

val communitySigningDefaults = mapOf(
    "storeFile" to "community.jks",
    "storePassword" to "CommunityKey",
    "keyAlias" to "communitykey",
    "keyPassword" to "CommunityKey",
)

fun signingValue(prefix: String, key: String): String? {
    val propertyValue = signingProperties.getProperty("$prefix.$key")
    if (!propertyValue.isNullOrBlank()) {
        return propertyValue
    }

    val envKey = "NLPA_${prefix.uppercase()}_${
        key.replace(Regex("([a-z])([A-Z])"), "$1_$2").uppercase()
    }"
    val envValue = System.getenv(envKey)?.takeIf { it.isNotBlank() }
    if (envValue != null) {
        return envValue
    }

    return if (prefix == "community") communitySigningDefaults[key] else null
}

fun hasSigningValues(prefix: String): Boolean {
    return listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        .all { !signingValue(prefix, it).isNullOrBlank() }
}

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
            signingValue("community", "storeFile")?.let { storeFile = file(it) }
            storePassword = signingValue("community", "storePassword")
            keyAlias = signingValue("community", "keyAlias")
            keyPassword = signingValue("community", "keyPassword")
        }
    }

    flavorDimensions += "version"

    productFlavors {
        create("community") {
            dimension = "version"
            applicationId = "ee.nekoko.nlpa2.open"
            manifestPlaceholders["appName"] = "NekokoLPA 2 Community"
            if (hasSigningValues("community")) {
                signingConfig = signingConfigs.getByName("community")
            }
        }

        create("privileged") {
            dimension = "version"
            applicationId = "ee.nekoko.nlpa2"
            manifestPlaceholders["appName"] = "NekokoLPA 2 Community Rooted"
            if (hasSigningValues("community")) {
                signingConfig = signingConfigs.getByName("community")
            }
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
            if (hasSigningValues("community")) {
                signingConfig = signingConfigs.getByName("community")
            }
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
