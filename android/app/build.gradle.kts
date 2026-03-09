import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    println("Loading global key.properties from: " + keystorePropertiesFile.absolutePath)
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    println("Global key.properties NOT FOUND at: " + keystorePropertiesFile.absolutePath)
    // Try local (app module) just in case
    val localProps = file("key.properties")
    if (localProps.exists()) {
         println("Loading local key.properties from: " + localProps.absolutePath)
         keystoreProperties.load(FileInputStream(localProps))
    }
}

android {
    namespace = "com.example.gravity_app"
    compileSdk = 36
    println("Compile SDK: $compileSdk")
    ndkVersion = flutter.ndkVersion

    lint {
        baseline = file("lint-baseline.xml")
        checkReleaseBuilds = false
        abortOnError = false
    }

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
        applicationId = "com.example.gravity_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            val keyAliasVal = keystoreProperties["keyAlias"] as String? ?: "key"
            val keyPasswordVal = keystoreProperties["keyPassword"] as String? ?: ""
            val storePasswordVal = keystoreProperties["storePassword"] as String? ?: ""
            
            println("DEBUG: keyAlias=$keyAliasVal")
            println("DEBUG: keyPassword=${if (keyPasswordVal.isNotEmpty()) "***SET***" else "EMPTY"}")
            println("DEBUG: storePassword=${if (storePasswordVal.isNotEmpty()) "***SET***" else "EMPTY"}")
            println("DEBUG: Forcing storeFile to 'release.keystore'")
            
            keyAlias = keyAliasVal
            keyPassword = keyPasswordVal
            storePassword = storePasswordVal
            
            // Hardcode to the file we know exists in this directory
            storeFile = file("release.keystore")
        }
    }

    buildTypes {
        release {
            // Enable R8 shrinking and obfuscation
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            // TEMPORARY: Using debug signing until key.properties is properly configured
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
}
