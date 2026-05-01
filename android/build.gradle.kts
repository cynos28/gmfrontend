allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy {
            force("androidx.concurrent:concurrent-futures:1.1.0")
            force("com.google.ar:core:1.33.0")
            force("com.google.ar.sceneform:core:1.17.1")
            force("com.google.ar.sceneform:assets:1.17.1")
            force("com.google.ar.sceneform.ux:sceneform-ux:1.17.1")
        }
        // Force add the dependency to implementation and api configurations if they exist
        if (name == "implementation" || name == "api") {
            dependencies.add(project.dependencies.create("androidx.concurrent:concurrent-futures:1.1.0"))
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
