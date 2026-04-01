allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    // This allows us to configure the subproject even if it's already evaluated
    plugins.withType<com.android.build.gradle.api.AndroidBasePlugin> {
        configure<com.android.build.gradle.BaseExtension> {
            if (namespace == null) {
                // Set the namespace to the project's group ID (e.g., com.solana.mobile)
                namespace = project.group.toString()
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
