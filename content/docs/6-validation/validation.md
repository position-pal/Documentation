---
weight: 500
title: "Self Assessment and Validation"
description: "Self assessment and validation of the system."
icon: "Bug_Report"
draft: false
toc: true
---

Different types of _automated_ tests, at different granularity, are in place to ensure the correctness of the system, as well as the quality of the software product as a whole.

The testing strategy follows [Martin Fowler’s Test Pyramid idea](https://martinfowler.com/articles/practical-test-pyramid.html), which advocates for a higher number of low-level unit tests that are that are fast and cost-effective, complemented by fewer high-level integration and end-to-end tests that, while slower and more complex, validate the overall system's functionalities.

Each type of test has been designed and executed accordingly, as detailed in the following sections.

## Architectural Testing

[ArchUnit](https://www.archunit.org) have been used to enforce architectural constraints, making sure to adhere to the _Hexagonal architecture_ (also known as _Onion architecture_ or _Ports and Adapters_), preventing unwanted dependencies, maintaining separation of concerns and ensuring architectural decisions are consistently followed over time.

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

This uses the `onionArchitecture` rule to enforce the following architectural constraints:

- the `domainModels` contains all the domain entities and do not depend on any other layer;
- the `applicationServices` contains all the application services that are needed to run the application and use cases. They can use and see only the domain models and no other layer;
- the `adapter`s modules contains logic to connect to external systems and/or infrastructure. They can see and use both the domain models and the application services, but no adapter can depend on another one.
- the only exception applies to the `entrypoint` package that contains the main application entrypoint and, thus, need to see and use the various adapters to wire all up together.

## Unit tests

Unit tests are at the lowest level of the pyramid. 
Their goal is to test a small piece, very often simply some classes, behaves like expected.

the advantage of kotest and scala test as DSL... 

an example of unit test

## Integration tests

## End-to-End tests

As presented in the [Domain Analysis](/docs/2-domain-analysis/1-functional-requirements/) section, the system has been end-to-end validated and tested using Cucumber...

<iframe src="https://position-pal.github.io/gateway/reports/cucumber-report.html" width="100%" height="700"></iframe>

## Quality Assurance

For all the projects and repositories, depending on the language they are developed in, different Quality Assurance (QA) tools have been used to validate the quality of the codebase.
These tools ensure adherence to coding standards, maintainability, and early detection of potential issues, if appropriately integrated into Continuous Integration (as per DevOps best practices).

The following tools have been used for Scala:

- [`Scalafmt`](https://scalameta.org/scalafmt/): a code formatter ensuring consistency in code style across the project;
- [`Scalafix`](http://www.scalafix.org): a tool for refactoring and linting Scala code, allowing automated fixes for common issues and ensuring best practices.

The following tools have been employed for Kotlin:

- [`ktlint`](https://ktlint.github.io): a linter and formatter that enforces Kotlin coding standards automatically;
- [`detekt`](https://scalacenter.github.io/scalafix/): a static code analysis tool for Kotlin that helps identify code smells, complexity issues, and potential security risks.

For Javascript, [`ESLint`](https://eslint.org), a static analysis tool that enforces coding style rules and detects problematic patterns in JavaScript code.

To further improve code quality and reliability, aggressive compilation options have been used across all projects. These options ensure that all warnings are treated as errors, preventing the introduction of potential issues into the codebase. This approach enforces strict compliance with best practices and minimizes the risk of overlooking important warnings that could lead to runtime errors or degraded maintainability.

By integrating these QA tools and enforcing strict compilation settings, the project maintains high code quality, reduces technical debt, and ensures consistency across different languages and repositories.

For more details on the QA tools and configuration used please refer to the [DevOps section](/docs/7-devops/devops/).
