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

### Runtime

Vale--

Security

Performance

User friendliness

#### Observability
**Stimulus**: On or more services in the system is not responding as expected.
**Stimulus Source**: Monitoring service detect and report the anomaly.
**Environment**: The system operating in normal state in a production enviroment.
**Artifact**: The monitoring service.
**Response**: The monitoring service logs the anomaly and sends an alert to the system administrator.
**Response Measure**: 
    - ✅ **Pass Condition**: The system administrator receives the alert in less than 1 minute.
    - ✅ **Pass Condition**: The alert contains the service name, the error message, and the timestamp of the anomaly.
    - ✅ **Pass Condition**: The alert is sent to the system administrator via email, a messaging service, or a dedicated monitoring platform.
    - ✅ **Pass Condition**: The alert is logged in the monitoring system for future reference.

#### Reliability

**Stimulus**: An error occours in one of the system services.
**Stimulus Source**: An exception (of any nature) throwed inside a service program.
**Environment**: The system operating in normal state in a production enviroment.
**Artifact**: The affected service(s).
**Response**: The infrastructure of the system automatically detects the failure and tries to restore the affected service(s), ensuring that no data is lost or corrupted.
**Response Measure**: The service(s) returns to operate normally if they can be restored, otherwise they will be replaced by a new operational instance.
    - ✅ **Pass Condition**: The system is able to restore the service(s) within 30 seconds.

#### Availability

**Stimulus**: Due an internal error occours, a service becomes unavailable.
**Stimulus Source**: Hardware or network error.
**Environment**: The system operating in normal state in a production enviroment.
**Artifact**: The service that becomes unavailable.
**Response**: The infrastructure of the system automatically detects the failure and tries to redirect the trafic in another replica if this is available, otherwise an error is reported to the monitoring system.
**Response Measure**: 
    - ✅ **Pass Condition**: The system is able to redirect the trafic to another replica within 1 minute.

#### Scalability

**Stimulus**: An huge amount of requests are performed to one or more services in the system.
**Stimulus Source**: Users that tries to access the system.
**Environment**: The system operating on an high load in a production enviroment.
**Artifact**: Services of the system with huge amount of requests registered.
**Response**: The infrastructure that hosts the system will automatically create new replicas of the services that are under high load, and will redirect the trafic to the new replicas.
**Response Measure**: 
    -  ✅ **Pass Condition**: System is able to serve all the requests with a response time of less than 3.5 second on the 98% of the requests.

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