// Top-level build file where you can add configuration options common to all sub-projects/modules.

// All plugins are now managed in settings.gradle.kts
// This file is kept for backward compatibility but doesn't define plugins
plugins {
    // All plugins (Android, Kotlin, Google Services) are defined in settings.gradle.kts
    // to avoid version conflicts
}

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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
