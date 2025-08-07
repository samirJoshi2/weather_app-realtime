// android/build.gradle.kts

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.0.2")  // Use your current gradle plugin version
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.10")  // Kotlin plugin version
        classpath("com.google.gms:google-services:4.4.3")  // Google services plugin
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
<<<<<<< HEAD
=======
dependencies{
    classpath 'com.google.gms.google-services: 3.32.0' 
}
>>>>>>> 553bb64 (first commit)

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
