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
    // Only configure the custom build directory for the 'app' module.
    // We leave plugins to use their default build directory (which might be in the Pub cache)
    // to avoid "different roots" errors on Windows when the project and cache are on different drives.
    if (project.name == "app") {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    } else {
        // For plugins, disable unit tests to avoid "different roots" issues during task creation
        // and because they are not needed for the app build.
        project.afterEvaluate {
            project.tasks.configureEach {
                if (name.contains("UnitTest", ignoreCase = true)) {
                    enabled = false
                }
            }
            val android = project.extensions.findByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                android.compileSdkVersion(36)
                if (android.namespace == null) {
                    val groupName = project.group.toString()
                    if (groupName.isEmpty() || groupName == "unspecified") {
                        android.namespace = "com.example.${project.name.replace("-", "_")}"
                    } else {
                        android.namespace = groupName
                    }
                }
            }
        }
        // Plugins usually depend on :app being evaluated to get configuration
        project.evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
