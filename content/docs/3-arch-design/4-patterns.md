---
weight: 304
title: "Architectural Patterns"
description: ""
toc: true
mermaid: true
---

In this page are collected the Microservice Architectural Pattern we used in the design of the system, following the [Chris Richardson's taxonomy](https://position-pal.github.io/docs/3-arch-design/4-patterns/)

## Service collaboration

### [Database per Service](https://microservices.io/patterns/data/database-per-service.html)

Each microservice's persistent data is private to that service and accessible only via its API.
More specifically, an approach where each microservice has **its own schema** has been adopted, favoring _data isolation_, making ownership of the data clearer and ensuring the services are _loosely coupled_.

### [Domain event](https://microservices.io/patterns/data/domain-event.html)

Since the _notification_, _location_, and _chat_ microservices all require information about group members to function correctly, a query-based approach would be inefficient and would degrade system performance, especially given the need to handle high volumes of data and requests.
To address this, the architecture is designed to be event-driven.
The user service publishes domain events whenever a group-related action occurs, such as adding or removing a member.

This approach ensures that all the services that need to know this information can subscribe to the events and update their local projections accordingly.
As in the observer pattern, the publisher does not know who is interested in the event and, therefore, does not need to be aware of the subscribers that may change in the future (for example because of the addition of a new service) with no impact on the publisher.

On the downside, this approach makes the system eventually consistent, but this is a trade-off that has been accepted in order to ensure the system's scalability and performance.

### [Event sourcing](https://microservices.io/patterns/data/event-sourcing.html)

For the location and chat services, the _Event Sourcing_ pattern is adopted.
This patterns consists of persisting the state of a business entity such as a sequence of state-changing events.
Whenever the state of the business entity changes a new event is appended to the list of events, making it possible for the application to reconstruct the entity's state by replaying the events.

This approach suits well both the location and chat services, as they need to keep track of the history of the location updates and chat messages, respectively.
Moreover, this approach allows the system to be more resilient to failures, as the state can be reconstructed by replaying the events, and more scalable as it enables efficient distribution of workload across multiple services, reduces contention on the database by leveraging an append-only storage model, and facilitates the creation of optimized read models through event-driven processing.

### [CQRS](https://microservices.io/patterns/data/cqrs.html)

Since different services, other than the Users & Groups service
requires the groups information to properly function, the _Command Query Responsibility Segregation_ pattern is adopted.

Every microservice that has the need to know the group members information have their own read-only 'replica' that is designed specifically to serve the queries of that service.
The service keeps the database up to date by subscribing to Domain events published by the service that own the data, in our case the Users & Groups service.
This pattern allows each service to support its own denormalized view of the groups data that is optimized for its specific needs, ensuring that the services are loosely coupled and that the system is scalable and performant.
No complex and slow queries are needed to be executed on the user service to retrieve the group members information, as the data is already available in the read-only replica of the service that needs it.
This also improves the overall system responsiveness.


## Communication styles

In accordance to the _Domain event_ pattern the interactions between the microservices are **_asynchronous_**: they exchange messages over messaging channels through a Message/Event Broker.

Though, the communication between the client and the microservices through the API Gateway is **_synchronous_** though an RPC protocol, allowing the client to invoke remote procedures on the microservices and receive a response in a synchronous manner (e.g. for the authentication process), adhering to the _Request/Reply_ pattern.

## External API

### [API Gateway](https://microservices.io/patterns/apigateway.html)

The API Gateway is the single entry point for all clients, providing a unified interface to the system's microservices.
It's main purpose is to **aggregate** the functionalities of the architecture, **routing** the requests to the appropriate service, **aggregating** the responses, and providing a unified interface to the client applications.
Moreover, it is responsible for ensuring the **security** of the system, handling **authentication and authorization**.
Lastly, it surely provides **communication protocols translation** (e.g. from REST to gRPC or Websocket to a Message Broker).

## Security

### [Access Token](https://microservices.io/patterns/security/access-token.html)

The system uses the _Access Token_ pattern to ensure the security of the system.
The _Access Token_ pattern is used to provide a secure way to access the system's resources, ensuring that only authorized users can access the system's functionalities.
For each request, the client must provide a valid access token, which is then validated by the system to ensure that the user is authorized to access the requested resource.

## Deployment Patterns

### [Service-per-Container](https://microservices.io/patterns/deployment/service-per-container.html)

Each service is packages as a container image and deployed as a separate and independent container.
This pattern allows each service to be deployed and scaled independently, ensuring that the system is _resilient_ and _scalable_.

### [Service deployment platform](https://microservices.io/patterns/deployment/service-deployment-platform.html)

