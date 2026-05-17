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
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            val androidExtensions = extensions.getByName("android") as com.android.build.gradle.LibraryExtension
            if (androidExtensions.namespace == null) {
                androidExtensions.namespace = project.group.toString()
            }

            // 👇 TAMBAHKAN BARIS INI: Memaksa semua plugin eksternal pakai SDK 34
            androidExtensions.compileSdk = 34
        }
    }

    // 👇 TAMBAHKAN BLOK INI: Memaksa compiler menggunakan Java 17 agar warning hilang
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
