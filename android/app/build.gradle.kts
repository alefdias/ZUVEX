import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    // Firebase BoM — gerencia versões de todas as bibliotecas Firebase
    // BoM 33.7.0 = última versão compatível com Kotlin 2.0.x (Flutter 3.29)
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))

    // Bibliotecas Firebase usadas pelo ZUVEX (versões gerenciadas pelo BoM)
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
    implementation("com.google.firebase:firebase-analytics")
}

android {
    namespace = "com.zuvex.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // exigido pelos plugins Firebase/Flutter

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // kotlinOptions migrado para o bloco kotlin { compilerOptions } abaixo do bloco android

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.zuvex.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24 // Firebase Auth 25+ requer mínimo 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("zuvex-release.jks")
            storePassword = "zuvex123456"
            keyAlias = "zuvex"
            keyPassword = "zuvex123456"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
        freeCompilerArgs.add("-Xskip-metadata-version-check")
    }
}
