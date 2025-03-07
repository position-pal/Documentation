---
weight: 203
title: "Quality Attributes"
description: ""
toc: true
---

_Quality Attributes_ (_QA_), also known as _Non-Functional Requirements_ (_NFR_), are measurable properties of a system that describe its qualities and indicate how well it satisfies the needs of its stakeholders beyond the functional requirements.

These attributes play a crucial role in shaping the system architecture, as they influence design decisions, trade-offs, and the selection of appropriate technologies and patterns.

In the context of this project have been identified the following quality attributes that are considered essential for the success of system, divided into "Runtime" and "Development Time" categories:

- **Runtime**
  - the system should be highly **available** and **reliable** to ensure users can access it when needed
  - the system should be **scalable** to handle a growing number of users and data
  - the system should be **performant** to provide a responsive user experience and minimize latency in critical operations
  - the system should be **secure** to protect users' data and privacy
  - the system should be **observable** to allow monitoring and troubleshooting of its components in real-time
  - the client application should be **user-friendly** to provide an intuitive and accessible interface for users to interact with the system
- **Development Time**
  - the system should be **testable** to ensure the correctness of its behavior and facilitate maintenance over time;
  - the system should be **modular** to allow independent development and streamlined deployment of its components;
  - the system should be **extensible** to support future enhancements and integrations with other services without major refactoring or disruptions;
  - the system should be **maintainable** to allow easy updates, bug fixes, and improvements over time without excessive effort or risk of regressions.

Based on the above non-functional requirements, the team has identified the following scenarios to be considered during the design and implementation of the system.

## Quality Attributes Scenarios

### Development Time

#### Testability

- **Source**: Developer
- **Stimulus**: A new code change is submitted to the version control system
- **Environment**: In a controlled CI/CD pipeline with automated testing tools and environments set up
- **Artifact**: System modules and components
- **Response**: The system triggers all the automated test suite, comprising unit, integration, and end-to-end tests, to verify the correctness of the changes
- **Response Measure**:
  - ✅ **Pass Condition**: All tests pass successfully withing 15 minutes
  - ✅ **Pass Condition**: The test report must clearly indicate the tests report and any failed tests, including module name, error details and stack trace

#### Modularity

- **Source**: Development team
- **Stimulus**: A request is made to update, fix, or replace an existing module or component due to a bug fix, performance improvement, or internal refactoring.
- **Environment**: The system is operational and new code changes are being developed and tested in a controlled environment with all modules integrated
- **Artifact**: The specific component or module targeted for update or replacement
- **Response**: The requested module can be replaced or updated independently, using only its exposed APIs, without modifying or recompiling other modules.
- **Response Measure**:
  - ✅ **Pass Condition**: Integration of the updated or new module must not require changes to other modules.
  - ✅ **Pass Condition**: Integration testing must be completed within 20% of the original development effort for the module.
  - ✅ **Pass Condition**: All tests for unchanged modules must pass after integration.

#### Extensibility

- **Source**: Product manager
- **Stimulus**: A request is made to add a new feature or integrate an external service that does not exist in the current system.
- **Environment**: During development, with the system operational for existing services, leveraging defined extension points or APIs.
- **Artifact**: New module or service to be integrated, extension points, and system interfaces.
- **Response**: The new feature must be implemented as a separate module using a clear and well-defined API, minimizing changes to existing code. The integration should not impact the performance or functionality of existing modules.
- **Response Measure**:
  - ✅ **Pass Condition**: No more than 10% of the existing code can be modified to support the new module.
  - ✅ **Pass Condition**: The new module must pass all tests independently before integration.
  - ✅ **Pass Condition**: Integration must not degrade existing system performance by more than 5%.

#### Maintainability

- **Source**: Development team
- **Stimulus**: A bug is reported in a deployed module.
- **Environment**: In a controlled development environment with access to the source code, bug tracking system, and deployment tools.
- **Artifact**: System logs, bug report, and source code repository
- ***Response***: The development team isolates the issue, applies a fix, and deploys it without affecting other modules.
- **Response Measure**:
  - ✅ **Pass Condition**: No new regression failures are detected in automated tests post-deployment.

Vale--

Security

Performance

User friendliness


Gio--

Observability

Availability

Reliability

Scalability
