---
weight: 500
title: "Self Assessment and Validation"
description: ""
icon: "article"
draft: false
toc: true
---

Different types of _automated_ tests are in place to ensure the correctness of the system, as well as the quality of the software product as a whole.

## Architectural Testing

[ArchUnit](https://www.archunit.org) have been used to enforce architectural constraints, making sure to adhere to the _Hexagonal architecture_ (otherwise said _Onion_ or _Ports and Adapters_) and preventing unwanted dependencies, maintaining separation of concerns and ensuring architectural decisions are consistently followed over time.

An example of arch unit test specification and rules used is shown below and can be found [here](https://github.com/position-pal/location-service/blob/main/entrypoint/src/test/scala/io/github/positionpal/location/entrypoint/ArchitecturalTest.scala).

```scala
"Project-wise architecture" should "adhere to ports and adapters, a.k.a onion architecture" in:
    val locationGroup = "io.github.positionpal.location"
    val code = ClassFileImporter().importPackages(locationGroup)
    onionArchitecture()
      .domainModels(s"$locationGroup.commons..", s"$locationGroup.domain..")
      .applicationServices(s"$locationGroup.application..", s"$locationGroup.presentation..")
      .adapter("real time tracker component", s"$locationGroup.tracking..")
      .adapter("storage", s"$locationGroup.storage..")
      .adapter("message broker", s"$locationGroup.messages..")
      .adapter("gRPC API", s"$locationGroup.grpc..")
      .adapter("web sockets and http web API", s"$locationGroup.ws..")
      .ignoreDependency(havingEntrypointAsOrigin, andAnyTarget)
      .because("`Entrypoint` submodule contains the main method wiring all the adapters together.")
      .ensureAllClassesAreContainedInArchitectureIgnoring(havingEntrypointAsOrigin)
      .withOptionalLayers(true)
      .check(code)

  private def havingEntrypointAsOrigin =
    DescribedPredicate.describe[JavaClass]("in `entrypoint` package", _.getPackage.getName.contains("entrypoint"))

  private def andAnyTarget = DescribedPredicate.alwaysTrue()
```

## Unit tests

## Integration tests

## End-to-End tests

<iframe src="https://position-pal.github.io/gateway/reports/cucumber-report.html" width="100%" height="700"></iframe>

## Quality Assurance

For every language, different Quality Assurance (QA) tools are used to ensure the quality of the codebase.

For Scala, the following tools are used:

- [`Scalafmt`](https://scalameta.org/scalafmt/)
- [`Scalastyle`](http://www.scalastyle.org)

For Kotlin, the following tools are used:

- [`ktlint`](https://ktlint.github.io)
- [`detekt`](https://detekt.github.io/detekt)

For Javascript, [`ESLint`](https://eslint.org) is used to enforce a coding style.
