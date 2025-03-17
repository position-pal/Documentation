---
weight: 600
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

private def havingEntrypointAsOrigin = DescribedPredicate
  .describe[JavaClass]("in `entrypoint` package", _.getPackage.getName.contains("entrypoint"))

private def andAnyTarget = DescribedPredicate.alwaysTrue()
```

This uses the `onionArchitecture` rule to enforce the following architectural constraints:

- the `domainModels` contains all the domain entities and do not depend on any other layer;
- the `applicationServices` contains all the application services that are needed to run the application and use cases. They can use and see only the domain models and no other layer;
- the `adapter`s modules contains logic to connect to external systems and/or infrastructure. They can see and use both the domain models and the application services, but no adapter can depend on another one.
- the only exception applies to the `entrypoint` package that contains the main application entrypoint and, thus, need to see and use the various adapters to wire all up together.

## Unit tests

Unit tests, which sit at the lowest level of the testing pyramid, focus on verifying that small pieces of code—often individual classes—behave as expected.

Leveraging testing DSLs frameworks like [Kotest](https://kotest.io) and [ScalaTest](http://www.scalatest.org) tests can be crafted in a clear and succinct way, enhancing their comprehensibility and maintenance.

## Integration tests

Integration tests are used to verify that different parts of the system work together correctly. They are more complex than unit tests, as they involve multiple components and services.

These tests are placed in the service layer, where the business logic is implemented, and are run against the real system, including the database and external services.

In some situations it was necessary to mock some services, this allowed us to create fine-grained tests that are isolated from the rest of the system, ensuring that the tests are repeatable and deterministic.

For the creation of these tests, a task was set up via `gradle` to launch a docker container that dies immediately after the tests are finished.

For example, launch postgres in the module reserved for storage tests:

```kotlin
normally {
    dockerCompose {
        startedServices = listOf("postgres")
        isRequiredBy(tasks.test)
    }
} except { inCI and (onMac or onWindows) } where {
    tasks.test { enabled = false }
} cause "GitHub Actions runner does not support Docker Compose"
```

Note how there is a section dedicated to CI that allows testing only on linux systems, consistent with the constraints set by the GitHub actions.


## End-to-End tests

End-to-End tests are the heaviest and slowest tests, as they validate the system as a whole, simulating real user interactions and scenarios.

These tests are placed in the access point of the system, i.e., the API gateway, and to be run against the whole system requires the local deployment of all the services along with a mocked version of the client app to make it possible to test real system notifications and interactions in a controlled and repeatable way.

For this purpose a local deployment infrastructure has been set up using Docker Compose with a custom template resolution strategy to allow the gateway test lifecycle to:

1. package in a Docker image the gateway service with the latest changes;
2. package the mocked client application in a Docker image;
3. bring up all the system microservices along with the gateway and the mocked client application. With a custom script and a custom option `--override` we override the default last push image for the gateway service with the local image built in step 1;
4. run the end-to-end tests against the system;
5. tear down the whole system.

```js
BeforeAll(async () => setupLocalDeployment());

AfterAll(async () => teardownLocalDeployment());

const setupLocalDeployment = () => {
  console.log("Bring up the local testing environment");
  run("docker build --no-cache -t local-gateway ."); // 1
  run(`cd ${mockedAppPath} && docker build --no-cache -t mocked-app .`); // 2
  run(`${deploymentScript} up --override gateway:local-gateway`); // 3
  run(`docker run -d -v ${mockedAppPath}/firebase-config.json:/app/firebase-config.json -p 8080:8080 mocked-app`); // 3
};

const teardownLocalDeployment = () => { // 5
  console.log("Tearing down the local testing environment");
  run(`${deploymentScript} down`);
  run('docker rm $(docker stop $(docker ps -a -q --filter ancestor=mocked-app --format="{{.ID}}"))');
};

const run = (command) => { /* Run on a shell the given command ... */ };
```

As presented in the [Domain Analysis](/docs/2-domain-analysis/1-functional-requirements/) section, the system has been end-to-end validated and tested using Gherking and Cucumber-JS libraries, along with [Puppeteer](https://pptr.dev) for browser automation and interactions.

An example of a feature implementation is presented hereafter:

```js
When("I have arrived at the destination", async () => {
  await this.hanWs.send(
    JSON.stringify(sample(global.han.userData.id, global.astro.id, cesenaCampusLocation))
  );
});

Then("the routing is stopped", { timeout: 20_000 }, async () => {
  await eventually(async () => {
    expect(
      receivedUpdates.some((update) => 
        update.UserUpdate.user === global.han.userData.id && update.UserUpdate.status === "Active"
      ),
    ).to.be.true;
  }, 15_000);
});

Then("my state is updated to `Active`", { timeout: 15_000 }, async () => {
  await eventually(async () => {
    await expectSuccessfulGetRequest(
      `/api/session/state/${global.astro.id}/${global.han.userData.id}`,
      global.han.token,
      {
        status: { code: "OK" },
        state: "ACTIVE",
      },
    );
  }, 10_000);
});
```

The full suite of end-to-end features and tests can be found [here](https://github.com/position-pal/gateway/tree/main/tests/features) and the report of the last run can be found below:

<iframe src="https://position-pal.github.io/gateway/reports/cucumber-report.html" width="100%" height="700"></iframe>

## Stress Test

Stress tests have been performed to evaluate the system's performance under extreme conditions, such as high loads and peak traffic.
These are executed on the production environment, simulating a large number of concurrent users and requests to assess the system's stability, scalability, and responsiveness.

In order to perform these test we used [k6](https://k6.io/), a load testing tool that allows to write test scripts in JavaScript and run them from the command line. In particular we leveraged on xk6, an extended version of k6 that allows to add extension to the tool, in our case we used the Faker extension to generate random data for the tests.

Test are structured in scenarios that simulate different user behaviors and interactions with the system:

```js
export const smokeOptions = {
    vus: 2,               
    duration: '1m',       
    thresholds: {
      http_req_duration: ['p(95)<500'],  
      http_req_failed: ['rate<0.01'],
    },
    tags: { test_type: 'smoke' },
};

export const loadOptions = {
    stages: [
      { duration: '2m', target: 50 },    
      { duration: '5m', target: 50 },    
      { duration: '2m', target: 0 },    
    ],
    thresholds: {
      http_req_duration: ['p(95)<1000', 'p(99)<1500'],
      http_req_failed: ['rate<0.05'],
    },
    tags: { test_type: 'load' },
};

export const stressOptions = {
    stages: [
      { duration: '2m', target: 100 },   
      { duration: '5m', target: 100 },   
      { duration: '5m', target: 200 },   
      { duration: '10m', target: 200 },  
      { duration: '5m', target: 300 },   
      { duration: '10m', target: 300 },  
      { duration: '2m', target: 0 },     
    ],
    thresholds: {
      http_req_duration: ['p(95)<2000', 'p(99)<3000'], 
      http_req_failed: ['rate<0.1'],
    },
    tags: { test_type: 'stress' },
};
```
These scenarios represent three different levels of stress on the system: `smoke`, `load`, and `stress`. The `smoke` scenario simulates a small number of users and requests, it aims to verify the system's basic functionalities and responsiveness, the `load` scenario simulates a medium number of users and requests, simulating the system's performance under normal conditions while The `stress` scenario simulates a large number of users and requests verifying the system's performance under extreme conditions.

Tests are composed of one or more stages where, each of these, represents a different level of stress on the system. Each stage has a duration and a target number of virtual users (VUs) that will be simulated during that stage. The `thresholds` object contains the performance thresholds that the system must meet during the test, such as the maximum duration of a request or the maximum failure rate.


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
