---
weight: 700
title: "DevOps"
description: "DevOps practices and tools"
icon: "Rocket_Launch"
draft: false
mermaid: true
toc: true
---

## Build Automation

Since all microservices are JVM-based **Gradle** have been chosen as the build automation tool.
However, while in Kotlin using Gradle is a no-brainer choice and there exist a plethora of plugins and tools to automate the build process, in Scala the situation is a bit different.
For this reason, we have chosen to implement a custom Gradle plugin, called `scala-extras` to enhance the configuration and build process of all the Scala projects in one place.

The team has decided to implement the microservices using a one-repository-per-service approach, with each service managed as an independent Gradle project.
As a result, the shared kernel is published and included as a Gradle dependency by all other microservices, ensuring consistency and reusability across the architecture.
Since the code is tightly bound to the project and not intended for public reuse, **GitHub Packages** was selected as the publishing repository.

{{< alert context="warning" text="This requires to authenticate with a valid github username and personal access token, which is stored in the Gradle properties file or in an env variables named `USERNAME` and `TOKEN`." />}}

```kotlin
repositories {
    mavenCentral()
    maven {
        url = uri("https://maven.pkg.github.com/position-pal/shared-kernel")
        credentials {
            username = project.findProperty("gpr.user") as String? ?: System.getenv("USERNAME")
            password = project.findProperty("gpr.key") as String? ?: System.getenv("TOKEN")
        }
    }
}
```

For what concerns how the single microservices structure, they uses Gradle sub-projects, mapping each layer and adapter in the Hexagonal Architecture to a sub-project.

Regarding the frontend and the gateway, since they are both written in Javascript, the team has chosen `npm` as the build automation tool.

### Scala Extras

The [Scala Extras plugin](https://github.com/tassiluca/gradle-scala-extras) is a custom Gradle plugin published on Maven Central and on Gradle Plugin Portal that enhances the build process of Scala projects with the following features:

- Support for [_Scalafix_](https://scalacenter.github.io/scalafix/) and [_Scalafmt_](https://scalameta.org/scalafmt/) with a default configuration that can be possibly overridden;
- Aggressive Scala compiler option to treat warnings as errors is applied by default (still configurable);
- Out-of-the-box configuration to generate aggregated subprojects [_scaladoc_](https://docs.scala-lang.org/style/scaladoc.html) (which is not supported by default in the Scala Gradle plugin).

By default, applying the plugin to a project is sufficient to enable all the features with the default configuration.
In accordance with the standard practices of the Scala community, the plugin will automatically use the `.scalafix.conf` and/or `.scalafmt.conf` files if they are present in the root directory of the project.
Otherwise, the plugin provides a way to override the default configuration, if needed:

```kotlin
scalaExtras {
    qa { 
        allWarningsAsErrors = false
        scalafix {
            configFile = "stringified path to the scalafix configuration"
        }
        scalafmt {
            configFile = "stringified path to the scalafmt configuration"
        } 
    }
}
```

The plugin add the following tasks to the project:

- `format` to automatically format the Scala source code adhering to the QA supported tools configuration;
- `aggregateScaladoc` to generate the aggregated _scaladoc_ for all the subprojects, including the root one.

Moreover, the `check` task is enhanced to run all the QA tools before the tests, ensuring that the code is compliant with the standards:

## Version control

## DVCS workflow

We have chosen to work with a single stable branch, the `main` branch, which always contains the latest working version of the code.
All development is done in separate branches, such as `feature/name` for new features, `fix/name` for bug fixes.
Once the changes are ready, they are submitted through pull requests to be merged into the main branch.
Each pull request is reviewed and must be approved by at least one other developer before it's merged.
The main branch is also where all releases are made, ensuring consistency in the release process.

Commits are structured following the **[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)** standard, which allows for automatic versioning and changelog generation.

## Continuous Integration and Delivery

```mermaid
graph TB;
  dispatcher(["0. dispatcher"])
  dispatcher --> build1;
  dispatcher --> build2;
  dispatcher --> build3;

  subgraph matrix-build
    build1(["1a. MacOS build"]);
    build2(["1b. Linux build"]);
    build3(["1c. Windows build"]);
    build2 --> build4(["1d. Integration tests"]);
  end

  dry-delivery(["2. dry delivery"])
  build1 --> dry-delivery;
  build3 --> dry-delivery;
  build4 --> dry-delivery;
  release(["3. release"])
  dry-delivery --> release;
  publish-images(["5. publish-images"])
  release --> publish-images;
  publish-doc(["4. publish-doc"])
  release --> publish-doc;
  success(["6. success"])
  matrix-build .-> success
  dry-delivery .-> success
  release .-> success
  publish-doc --> success
  publish-images --> success;
```

## Bots & Tools

### Semantic Release

### Renovate

### Mergify

### SonarCloud

## Continuous Deployment
