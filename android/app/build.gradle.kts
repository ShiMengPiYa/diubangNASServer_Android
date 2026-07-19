import java.io.FileInputStream
import java.util.Properties
import com.android.build.gradle.internal.api.ApkVariantOutputImpl

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.diubang.nasserver"
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
        applicationId = "com.diubang.nasserver"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "/META-INF/versions/9/OSGI-INF/MANIFEST.MF"
            excludes += "/META-INF/*.SF"
            excludes += "/META-INF/*.DSA"
            excludes += "/META-INF/*.RSA"
            excludes += "/META-INF/*.EC"
        }
    }
}

@Suppress("DEPRECATION")
android.applicationVariants.configureEach {
    if (buildType.name == "release") {
        outputs.configureEach {
            (this as ApkVariantOutputImpl).outputFileName =
                "diubang_nasserver_${versionName}.apk"
        }
    }
}

afterEvaluate {
    tasks.named("assembleRelease").configure {
        doLast {
            val version = android.defaultConfig.versionName ?: "1.0.0"
            val fileName = "diubang_nasserver_${version}.apk"
            val releaseApk = layout.buildDirectory.file("outputs/apk/release/$fileName").get().asFile
            val flutterApkDir =
                rootProject.projectDir.parentFile.resolve("build/app/outputs/flutter-apk")
            if (releaseApk.exists()) {
                flutterApkDir.mkdirs()
                releaseApk.copyTo(flutterApkDir.resolve(fileName), overwrite = true)
            }
        }
    }
}

flutter {
    source = "../.."
}
