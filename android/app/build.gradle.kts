import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin은 Android와 Kotlin Gradle 플러그인 뒤에 적용해야 합니다.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kintree.weview.weview"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    // 서명 키 정보 로드
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")

    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    } else {
        throw GradleException("key.properties 파일이 존재하지 않습니다.")
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"]?.toString() ?: throw GradleException("keyAlias 값이 없습니다.")
            keyPassword = keystoreProperties["keyPassword"]?.toString() ?: throw GradleException("keyPassword 값이 없습니다.")
            storeFile = file(keystoreProperties["storeFile"]?.toString() ?: throw GradleException("storeFile 경로가 없습니다."))
            storePassword = keystoreProperties["storePassword"]?.toString() ?: throw GradleException("storePassword 값이 없습니다.")
        }
    }

    // 빌드 타입 설정
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")  // release 빌드에 서명 적용
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // 컴파일 옵션 설정
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    // Kotlin 옵션 설정
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // 기본 설정
    defaultConfig {
        applicationId = "com.kintree.weview.weview"  // 앱 ID 설정
        minSdk = 23  // minSdkVersion을 21에서 23으로 변경
        targetSdk = flutter.targetSdkVersion // 타겟 SDK 버전
        versionCode = flutter.versionCode    // 버전 코드
        versionName = flutter.versionName    // 버전 이름
    }
}

flutter {
    source = "../.."  // Flutter 소스 경로 설정
}
