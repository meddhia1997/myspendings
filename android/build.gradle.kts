allprojects {
    repositories {
        google()
        mavenCentral()
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

// Some plugins (e.g. file_picker's flutter_plugin_android_lifecycle dependency)
// require compileSdk 36+, but their own Gradle module still resolves
// flutter.compileSdkVersion to Flutter's older bundled default. Force every
// Android library subproject to compile against 36 regardless of what it asked
// for itself. Hooked via plugins.withId (fires at plugin-apply time) rather than
// afterEvaluate, since evaluationDependsOn(":app") above means some subprojects
// are already evaluated by the time a plain `subprojects { afterEvaluate {} }`
// would run, which Gradle rejects.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileSdk = 36
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
