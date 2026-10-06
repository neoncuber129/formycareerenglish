allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// AGP 8+ requires namespace on every library. Some Flutter plugins (e.g. isar_flutter_libs)
// still omit it; infer from Gradle `group`, which matches their AndroidManifest package.
subprojects {
    plugins.withId("com.android.library") {
        val androidExt = extensions.findByName("android") ?: return@withId
        val namespaceGetter = runCatching { androidExt.javaClass.getMethod("getNamespace") }.getOrNull()
        val current = runCatching { namespaceGetter?.invoke(androidExt) as String? }.getOrNull()
        if (current.isNullOrEmpty()) {
            val g = project.group?.toString().orEmpty()
            if (g.isNotEmpty() && g != "unspecified") {
                runCatching {
                    androidExt.javaClass.getMethod("setNamespace", String::class.java)
                        .invoke(androidExt, g)
                }
            }
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
