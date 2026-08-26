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

// Some plugins (file_picker's flutter_plugin_android_lifecycle dependency)
// publish an AAR whose baked-in metadata demands compileSdk 36+, while their
// own build.gradle still resolves flutter.compileSdkVersion to a lower value
// at our Flutter SDK's default. Force every Android library subproject to 36.
//
// plugins.withId alone isn't enough: it fires the moment the android-library
// plugin is applied, which is *before* that module's own `android { compileSdk
// = ... }` line runs later in the same script — so that line clobbers our
// override right back down. We need to additionally set it after the module's
// own script finishes. But evaluationDependsOn(":app") above forces some
// subprojects to fully evaluate eagerly, before this block even registers on
// them, and calling afterEvaluate on an already-evaluated project throws — so
// branch: already evaluated -> set immediately; still pending -> afterEvaluate.
subprojects {
    plugins.withId("com.android.library") {
        val libraryExtension = extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        fun forceCompileSdk() {
            libraryExtension.compileSdk = 36
        }
        if (project.state.executed) {
            forceCompileSdk()
        } else {
            afterEvaluate { forceCompileSdk() }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
