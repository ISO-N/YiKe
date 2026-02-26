allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 文件用途：Android 工程通用构建配置（为部分第三方插件做兼容性补丁）。
// 作者：Codex
// 创建日期：2026-02-26
//
// 说明：
// - `google_mlkit_commons` 旧版本插件的 Android 工程硬编码 `compileSdkVersion 29`，在 release 资源校验阶段
//   会因为缺少 `android:attr/lStar`（API 31 引入）导致 AAPT 链接失败。
// - 这里对指定子工程做“compileSdk 下限”提升，避免需要修改 Pub 缓存（不可提交/不可复用）。
subprojects {
    afterEvaluate {
        // 仅对问题插件打补丁，避免影响其它模块的构建配置。
        if (project.name != "google_mlkit_commons") return@afterEvaluate

        val androidExt = project.extensions.findByName("android") ?: return@afterEvaluate

        // 兼容 AGP 7/8：优先调用 `setCompileSdkVersion(int)`，若不存在则尝试 `setCompileSdk(int)`。
        val methods = androidExt.javaClass.methods
        val setCompileSdkVersion =
            methods.firstOrNull {
                it.name == "setCompileSdkVersion" &&
                    it.parameterTypes.size == 1 &&
                    (it.parameterTypes[0] == Int::class.javaPrimitiveType ||
                        it.parameterTypes[0] == Int::class.javaObjectType)
            }
        val setCompileSdk =
            methods.firstOrNull {
                it.name == "setCompileSdk" &&
                    it.parameterTypes.size == 1 &&
                    (it.parameterTypes[0] == Int::class.javaPrimitiveType ||
                        it.parameterTypes[0] == Int::class.javaObjectType)
            }

        // 取 34 作为下限：本机已安装 android-34，且与 Flutter 默认 compileSdk 保持一致。
        val compileSdkMin = 34
        when {
            setCompileSdkVersion != null -> setCompileSdkVersion.invoke(androidExt, compileSdkMin)
            setCompileSdk != null -> setCompileSdk.invoke(androidExt, compileSdkMin)
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
