---
weight: 302
title: "Architecture Design"
description: ""
toc: true
---

The chosen architectural style for the system is the **Microservices Architecture**.

`TODO: why, advantages`

## Microservices Decomposition

Following the _decompose by subdomain strategy_ the following microservices have been identified:

- **User Service**: responsible for managing the user account data and the groups of the system;
- **Location Service**: responsible for managing the location and the user tracking;
- **Notification Service**: responsible for managing the notifications;
- **Chat Service**: responsible for managing the chat messages.

It should be noted that in the _User Service_ we have joined together the Users and Groups bounded context.
This is because one can see the close interaction between these two domain entities in addition to respecting properties such as the "Common Closure Principle" (package components that change for the same reason are located into the same service), ensuring data consistency and mitigate Network latency:

Moreover, to aggregate the functionalities of the different microservices, we have chosen to use the **API Gateway** pattern. This pattern is used to aggregate the functionalities of the architecture, providing a single entry point for the client applications.
The API Gateway is responsible for routing the requests to the appropriate service, aggregating the responses, and providing a unified interface to the client applications.

## C&C View

The following diagram shows the _Component and Connector_ (C&C) view of the system, providing a high-level picture of the system's runtime entities in action and their boundaries.

In order to avoid overwhelming the reader with an all-encompassing but rather confusing scheme, we provide below a C&C view of the system by providing, for each microservice, its relative UML diagram.

### Location Service

```plantuml
@startuml arch-cc-location
'========================== Styling =========================='
left to right direction
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
GATEWAY_LOC_REALTIME -(0- LOC_REALTIME : <<wss>>
GATEWAY_LOC_API -(0- LOC_TRACK : <<rpc>>
database ":Location \n Database" as LOC_DB <<infrastructure>> {
    portin " " as LOC_DB_DA
}
LOC_DA -(0- LOC_DB_DA : <<database connector>>

queue ":Message \n broker" <<infrastructure>> {
    portin "Publish \n notifications" as MB_PUB_NOTIF
    portin "Subscribe \n groups events" as MB_SUB_GRPS
}
LOC_PUB -(0- MB_PUB_NOTIF : <<subscribe>>
LOC_SUB -(0- MB_SUB_GRPS : <<publish>>
@enduml
```
<!-- 
```plantuml
@startuml arch-cc-chat

@enduml
``` -->

```plantuml
@startuml arch-cc-notification
'========================== Styling =========================='
left to right direction
skinparam component {
    BackgroundColor<<external>> White
    BackgroundColor<<executable>> #e3f6e3
}
skinparam DatabaseBackgroundColor LightYellow
skinparam QueueBackgroundColor #e4fafb
'========================= Components ========================'
component ":notification-service" {
    portout "Data Access" as NOT_DA
    portout "Receive groups \n updates" as NOT_SUB_GRPS
    portout "Receive \n notifications \n commands" as NOT_SUB_NOTIF
}
database ": Notification \n Service \n Database" as  NOT_DB {
    portin " " as NOT_DB_DA
}
NOT_DA -(0- NOT_DB_DA : <<database connector>>

queue ":Message \n broker" <<infrastructure>> {
    portin "Notifications \n topic" as MB_SUB_NOTIF
    portin "Group events \n topic" as MB_SUB_GRPS
}
NOT_SUB_GRPS -0)- MB_SUB_GRPS
NOT_SUB_NOTIF -0)- MB_SUB_NOTIF
@enduml
```

## Deployment View

## Hexagonal Architecture

The design of all the microservices follows 

