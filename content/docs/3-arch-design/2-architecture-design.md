---
weight: 302
title: "Architecture Design"
description: ""
toc: true
---

Following the identification and definition of the quality attributes, a _**microservice architecture**_ was chosen.
This is characterized by the decomposition of the system into a set of independent and loosely coupled services, each of which is responsible for a specific business domain or functionality.
Indeed, the use of this architectural style enables the continuous delivery and deployment of large, complex applications, the ability to scale horizontally with ease, the possibility to use different technologies and programming languages for each service and an increase in the overall system maintainability.
Moreover it allows to isolate failures and to improve the fault tolerance of the system, hence gaining in reliability.

## Microservices Decomposition

Following the _decompose by subdomain strategy_ the following microservices have been identified:

- **User Service**: responsible for managing the user account data and the groups of the system;
- **Location Service**: responsible for managing the location and the user tracking;
- **Notification Service**: responsible for managing the notifications;
- **Chat Service**: responsible for managing the chat messages.

Both the Groups and User bounded contexts have been consolidated within the user service due to their strong interrelation and need for frequent, seamless interaction.
Separating them into distinct microservices would compromise data consistency and introduce unacceptable levels of latency, making this integration a more efficient and reliable solution.
Indeed, while it's common to map a bounded context to a single microservice, this isn't always the case [^1].

[^1]: [How to define subdomains](https://microservices.io/post/architecture/2023/08/14/assemblage-overview-part-2-defining-subdomains.html#a-microservice-is-a-collection-of-subdomains)

Moreover, to aggregate the functionalities of the different microservices, we have chosen to use the **API Gateway** pattern. This pattern is used to aggregate the functionalities of the architecture, providing a single entry point for the client applications.
The API Gateway is responsible for routing the requests to the appropriate service, aggregating the responses, and providing a unified interface to the client applications.

## Architecture Documentation

### High-Level Overview

**To address the challenges of scalability, decoupling, and real-time processing, the system architecture was designed following an event-driven microservice approach, in which the microservices are mainly designed to _interact_ by means of event streams.**

This paradigm enables **_asynchronous communication_** between the services, allowing them to be _loosely coupled_ and _independent_ from each other, hence making the system more _resilient_ and _maintainable_.

For this purpose, the architecture is designed around a **Message/Event Broker**, which acts as a central communication hub for the microservices, enabling them to _publish_ and _subscribe_ to events, and _exchange messages_ in a _reliable_ and _scalable_ way.

Nonetheless, regarding the communications between the client and the microservices through the API Gateway, an **RPC** protocol is used, in order to ensure synchronous communication.
This approach enables the client to _invoke_ remote procedures on the microservices and receive a response in a synchronous manner (e.g. for the authentication process).

Lastly, each microservice follow the best practice of having **its own database**, ensuring _data isolation_ and _independence_ from other services, allowing a _loosely coupled_ architecture whose communications happen **only** through the message broker via a standard protocol.
This has also the advantage of letting the developers change a service schema without affecting, and thus coordinating, with other services teams.

Following these high-level principles, in the following sections we provide a detailed view of the system architecture, though the three main structural views: _Components and Connectors_, _Modules_ and _Allocation_.

### C&C View

The following diagrams shows the _Component and Connector_ (C&C) view of the system, providing a high-level picture of the system's runtime entities in action and their boundaries.

In order to avoid overwhelming the reader with an all-encompassing but rather confusing scheme, we provide below a C&C view of the system by showing, for each microservice, its relative UML diagram.

#### User and Group Service

The user service interacts with the Gateway, exposing an RPC-based API port allowing users to manage their account and groups.
It has its own database for storing user and group data and interacts with the message broker to publish group events to the other services.

```plantuml
@startuml arch-cc-user-group
'========================== Styling =========================='
skinparam component {
    BackgroundColor<<external>> White
    BackgroundColor<<executable>> #e3f6e3
}
skinparam DatabaseBackgroundColor LightYellow
skinparam QueueBackgroundColor #e4fafb
'========================= Components ========================'
component ":gateway" {
    portin "API" as GATEWAY_API
    portout "User service \n Public API" as GATEWAY_USR_API
}

component ":User Service" {
    portin "User and Group \n Services" as USER_SERVICES
    portout "Data \n Access" as USR_DA
    portout "Publish \n group events" as USR_PUB
}

GATEWAY_USR_API -(0- USER_SERVICES : <<rpc>>
database ":User \n Database" as USR_DB <<infrastructure>> {
    portin " " as USR_DB_DA
}
USR_DA -(0- USR_DB_DA : <<database connector>>

queue ":Message \n broker" <<infrastructure>> {
    portin "Publish \n group events" as MB_PUB_GROUP
}
USR_PUB -(0- MB_PUB_GROUP : <<publish>>
@enduml
```

#### Location Service

The Location Service interacts with the Gateway, exposing two different API ports: one for real-time tracking via a real-time connector, allowing users to be tracked, and another for accessing tracking service information through an RPC connector.
Like, any other microservice, it has its own database for storing the tracking data, and it interacts with the message broker to publish notifications and subscribe to group events.

```plantuml
@startuml arch-cc-location
'========================== Styling =========================='
skinparam component {
    BackgroundColor<<external>> White
    BackgroundColor<<executable>> #e3f6e3
}
skinparam DatabaseBackgroundColor LightYellow
skinparam QueueBackgroundColor #e4fafb
'========================= Components ========================'
component ":gateway" {
    portin "API" as GATEWAY_API
    portin "Real-time API" as GATEWAY_REALTIME
    portout "Location service \n Real-time API" as GATEWAY_LOC_REALTIME
    portout "Location service \n Public API" as GATEWAY_LOC_API
}

component ":Location Service" {
    portin "Real-time \n tracking" as LOC_REALTIME
    portin "Tracking \n Services" as LOC_TRACK
    portout "Data \n Access" as LOC_DA
    portout "Publish \n notifications" as LOC_PUB
    portout "Receive \n groups events" as LOC_SUB
}
GATEWAY_LOC_REALTIME --(0- LOC_REALTIME : <<real-time connector>>
GATEWAY_LOC_API -(0- LOC_TRACK : <<rpc>>
database ":Location \n Database" as LOC_DB <<infrastructure>> {
    portin " " as LOC_DB_DA
}
LOC_DA -(0- LOC_DB_DA : <<database connector>>

queue ":Message \n broker" <<infrastructure>> {
    portin "Publish \n notifications" as MB_PUB_NOTIF
    portin "Subscribe \n groups events" as MB_SUB_GRPS
}
LOC_PUB -(0- MB_PUB_NOTIF : <<publish>>
LOC_SUB -(0- MB_SUB_GRPS : <<subscribe>>
@enduml
```

#### Chat Service

Similarly to the location service, the chat service exposes two different API ports: one for real-time chat communication via a real-time connector, and another for accessing chat service information through an RPC connector. It stores the chat data in its own database and interacts with the message broker for receiving group events.

```plantuml
@startuml arch-cc-chat
'========================== Styling =========================='
skinparam component {
    BackgroundColor<<external>> White
    BackgroundColor<<executable>> #e3f6e3
}
skinparam DatabaseBackgroundColor LightYellow
skinparam QueueBackgroundColor #e4fafb
'========================= Components ========================'
component ":gateway" {
    portin "API" as GATEWAY_API
    portin "Real-time API" as GATEWAY_REALTIME
    portout "Chat service \n Real-time API" as GATEWAY_CHAT_REALTIME
    portout "Chat service \n Public API" as GATEWAY_CHAT_API
}

component ":Chat Service" {
    portin "Chat \n communication" as CHAT_REALTIME
    portin "Chat \n API" as CHAT_API
    portout "Data \n Access" as CHAT_DA
    portout "Receive \n groups events" as CHAT_SUB
}

GATEWAY_CHAT_REALTIME --(0- CHAT_REALTIME : <<real-time connector>>
GATEWAY_CHAT_API -(0- CHAT_API : <<rpc>>

database ":Location \n Database" as LOC_DB <<infrastructure>> {
    portin " " as CHAT_DB_DA
}

CHAT_DA -(0- CHAT_DB_DA : <<database connector>>

queue ":Message \n broker" <<infrastructure>> {
    portin "Subscribe \n groups events" as MB_SUB_GRPS
}

CHAT_SUB -(0- MB_SUB_GRPS : <<subscribe>>

@enduml
```

#### Notification service

The notification service expose a input port through which an RPC connector is possible to subscribe to notifications by clients.
It has a data access port to interact with the database and two output ports to receive group updates and notification commands.

```plantuml
@startuml arch-cc-notification
'========================== Styling =========================='
skinparam component {
    BackgroundColor<<external>> #eeebeb
    BackgroundColor<<executable>> #e3f6e3
}
skinparam DatabaseBackgroundColor LightYellow
skinparam QueueBackgroundColor #e4fafb
'========================= Components ========================'
component ":gateway" {
    portin "API" as GATEWAY_API
    portout "Notification service Public API" as GATEWAY_NOT_API
}

component ":notification-service" {
    portin "Notification Subscription \n Service API" as NOT_API
    portout "Data Access" as NOT_DA
    portout "Receive groups \n updates" as NOT_SUB_GRPS
    portout "Receive \n notifications \n commands" as NOT_SUB_NOTIF
}
database ": Notification \n Service \n Database" as  NOT_DB {
    portin " " as NOT_DB_DA
}
GATEWAY_NOT_API -(0- NOT_API : <<rpc>>
NOT_DA -(0- NOT_DB_DA : <<database connector>>

queue ":Message \n broker" <<infrastructure>> {
    portin "Notifications \n topic" as MB_SUB_NOTIF
    portin "Group events \n topic" as MB_SUB_GRPS
}
NOT_SUB_GRPS -0)- MB_SUB_GRPS
NOT_SUB_NOTIF -0)- MB_SUB_NOTIF
@enduml
```

### Deployment View

```plantuml
@startuml deployment-view
actor "User" as U

node "Client Node" as CN {
    component "Client Application" <<container>> as CA
}

node "Backend Infrastructure" as INF {
   
    node "API Gateway" <<container>> as AGW
    node "Message Broker" <<container>> as MB

    component "Notification" as NS {
        node "Notification Service" <<container>> as NSI
        node "Notification Database" <<container>> as ND
        NSI -- ND
    }

    component "User" as US {
        node "User Service" <<container>> as USI
        node "User Database" <<container>> as UD
        USI -- UD
    }

    component "Location" as LS {
        node "Location Service" <<container>> as LSI
        node "Location Database" <<container>> as LD
        LSI -- LD
    }

    component "Chat" as CS {
        node "Chat Service" <<container>> as CSI
        node "Chat Database" <<container>> as CD
        CSI -- CD
    }

    LSI ... MB: <<message>>
    CSI ... MB: <<message>>
    NSI ... MB: <<message>>
    USI ... MB: <<message>>

    AGW .. USI
    AGW .. LSI
    AGW .. CSI
    AGW .. NSI
}

AGW .up. CA
U .. CA
@enduml
```

## Hexagonal Architecture

In compliance with DDD principles, the microservices are designed following the **Hexagonal Architecture** pattern (also known as _Ports and Adapters_ or _Onion Architecture_), which is a particular instantiation of the layered architecture, that is well-suited for microservices to preserve models' integrity.
Indeed, the primary advantage of this pattern is the separation of concerns, which allows the business logic to be decoupled from the infrastructure and the external systems (e.g., databases, message brokers, etc.) hence making the system more maintainable and testable, and the business logic more reusable.

![Hexagonal Architecture](https://herbertograca.com/wp-content/uploads/2018/11/070-explicit-architecture-svg.png)

Each layer of the Hexagonal Architecture has been enforced in the code by mapping them into modules (like Grade submodules) each of which with its own build dependencies and responsibilities, as shown in the following diagram:

```plantuml
@startuml hexagonal-architecture
skinparam artifact {
    BackgroundColor<<third-party>> white
}

folder domain
note left of domain
    Here lies all the domain logic
    and business rules that
    encompass:
     • Value objects
     • Entities
     • Aggregates
     • Events
end note

folder application
note right of application
    Here lies the application
    use cases:
     • Services
     • Repository
end note

folder storage
note top of storage
    Here resides all the 
    code that ensures 
    data persistence 
    (storage adapters)
end note
artifact "DB client library" <<third-party>> as DB_LIB
storage -left-|> DB_LIB

folder presentation
artifact "serialization library" <<third-party>> as SERIALIZATION_LIB
presentation -right-|> SERIALIZATION_LIB

folder mom
folder api

application -up-|> domain
storage -up-|> application
presentation -up-|> application
mom -up-|> presentation
api -up-|> presentation

folder entrypoint
note left of entrypoint
    The service entrypoint where all
    the adapters are wired together
    and the main application 
    is started
end note
entrypoint -up-|> api
entrypoint -up-|> mom
entrypoint -up-|> storage

note "Two examples of adapters" as AD
api .. AD
mom .. AD

@enduml
```
