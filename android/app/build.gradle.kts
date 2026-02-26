/*
 * 文件用途：Android App 模块构建脚本（Kotlin DSL），用于配置编译选项与依赖。
 * 作者：Codex CLI（自动维护）
 * 创建日期：未知（项目初始化时生成）
 */

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.yike"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications 依赖要求开启 core library desugaring，用于在低版本 Android 上使用部分 Java 8+ API。
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.yike"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
    // 开启 core library desugaring 所需的运行库（与 compileOptions.isCoreLibraryDesugaringEnabled 配套）。
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // 说明：`google_mlkit_text_recognition` 插件将多语言识别器依赖声明为 compileOnly，
    // release 启用 R8 时会因“缺失类”直接失败。这里显式把可选模块加入到应用依赖中，
    // 以保证构建与运行期都具备对应实现。
    implementation("com.google.mlkit:text-recognition-chinese:16.0.0")
    implementation("com.google.mlkit:text-recognition-devanagari:16.0.0")
    implementation("com.google.mlkit:text-recognition-japanese:16.0.0")
    implementation("com.google.mlkit:text-recognition-korean:16.0.0")
}
