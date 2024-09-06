---
weight: 301
title: "Location Service"
description: ""
icon: "article"
date: "2024-08-02T16:21:33+02:00"
lastmod: "2024-08-02T16:21:33+02:00"
draft: false
toc: true
---

The location service is responsible for location tracking and management.

## Abstract Design

### Main domain concepts (from knowledge crunching)

| Concept | Description | Synonyms |
|---|---|---|
| Location | A specific point on a geographical plane, represented by coordinates that indicates where something / someone is located | Position |
| Route | A set of positions that can be interpolated forming a path between two geographical positions | Path |
| Session | Represent the state and the position of a user at a certain time | Tracking |
| State | State of a user at a certain time, the values that it could assume are: online, offline and SOS | |

### Structure

The main domain concepts are reified in the following classes structure, following the DDD principles.

```plantuml
@startuml location-service-structure
package application {
    package domain {
        interface GPSLocation <<value object>> {
            + latitude: Double
            + longitude: Double
        }

        class User <<entity>> {
            + id: UserId
            + inGroups: Set<GroupId>
        }
        class UserId <<value object>>
        class GroupId <<value object>>

        User *-u- "N" UserId
        User *-u- "N" GroupId

        interface Event {
            + timestamp: Date
            + user: User
        }

        User "1" --* Event

        interface StartRoutingEvent <<domain event>> extends Event {
            + arrivalPosition: GPSLocation
            + estimatedArrivalTime: Date
        }

        StartRoutingEvent *-- "1" GPSLocation

        interface TrackingEvent <<domain event>> extends Event {
            + position: GPSLocation

        }

        TrackingEvent *-- "1" GPSLocation

        interface StopRoutingEvent <<domain event>> extends Event

        interface SOSAlertEvent <<domain event>> extends Event {
            + position: GPSLocation

        }

        SOSAlertEvent *-- "1" GPSLocation
        
        interface Route <<aggregate root>> {
            + event: StartRoutingEvent
            + positions: List<TrackingEvent>
            + addTrace(TrackingEvent: TrackingEvent): Route
        }

        Route *-u- "1" StartRoutingEvent
        Route *-u- "N" TrackingEvent
    }

    interface TrackingEventsReader <<outbound port>> {
        + lastOf(user: User): TrackingEvent
    }
    interface TrackingEventsWriter <<outbound port>> {
        + save(TrackingEvent: TrackingEvent)
    }
    interface TrackingEventsStore <<outbound port>> implements TrackingEventsReader, TrackingEventsWriter
    TrackingEventsReader o.up. TrackingEvent
    TrackingEventsWriter o.up. TrackingEvent

    ' interface RoutesStore <<outbound port>> {
    '     + update(Route: Route)
    '     + by(user: User): Route
    '     + delete(Route: Route)
    ' }

    ' RoutesStore o.up. Route

    interface MapsService <<outbound port>> {
        + estimateArrivalTime(start: GPSLocation, end: GPSLocation): Date
        + distance(start: GPSLocation, end: GPSLocation): GPSLocation
    }

    MapsService o.up. GPSLocation

    interface UserTrackingInfoService <<inbound port>> {
        + lastTraceOf(user: User): TrackingEvent
        + routeOf(user: User): Route
        + lastStateOf(user: User): State
    }
    note right of UserTrackingInfoService::routeOf
        At most 1 
        route per
        user per 
        time is 
        active
    end note
    enum State {
        + ACTIVE,
        + INACTIVE,
        + SOS,
        + ROUTING
    }
    UserTrackingInfoService o.. State

    class UserTrackingInfoServiceImpl implements UserTrackingInfoService
    UserTrackingInfoServiceImpl *-- TrackingEventsReader

    interface RealTimeTrackingService <<inbound port>> {
        + handle(event: Event)
    }
    RealTimeTrackingService o.l. Event
    class ActorBasedTrackingService implements RealTimeTrackingService
    note top of RealTimeTrackingService
        in charge of users real time
        tracking management
    end note
}
@enduml
```

### Behavior

The active controller of the system is based on top of Akka actors which allows for a scalable and fault-tolerant system without arranging a complex infrastructure for it.

```plantuml 
@startuml location-service-behavior

[*] -> ActiveMode

ActiveMode -> ActiveMode : ""TrackingEvent(position)"" / save ""position""
ActiveMode: entry / create snapshot
ActiveMode: entry / state <- ACTIVE
ActiveMode -up-> RoutingMode : ""StartRoutingEvent"" \n / notify group members
ActiveMode --> SOSMode : SOSAlertEvent \n / notify group members

RoutingMode: entry / state <- ROUTING
RoutingMode ---> ActiveMode : ""StopRoutingEvent"" \n / notify all group members
RoutingMode -up-> RoutingCheckingMode : TrackingEvent
'RoutingMode --> RoutingMode : [no updates for a while] \n / alert all group members \n / state <- INACTIVE

RoutingCheckingMode: entry / append position to route
RoutingCheckingMode: do / perform checks
state c <<choice>>
RoutingCheckingMode --> c
c --> RoutingMode : [""Continue""]
c --> RoutingMode : [""Alert(msg)""] \n / alert group members ""msg""
c --> ActiveMode : [""Success(msg)""] \n / notify group members ""msg""

SOSMode: entry / state <- SOS
SOSMode --> SOSMode : ""TrackingEvent"" / append position to route
SOSMode --> ActiveMode : ""StopSOSEvent"" \n / notify group members
@enduml
```

In the above schema is not modelled the `Inactive Mode`: it is fired whenever no updates have been collected for a while (this is handled through timers by the actor).
In such cases the state is changed to `INACTIVE` and if the state before was not the active one (default where everything is ok) an alert (i.e. a notification) is triggered.

<!--

### Interaction

```plantuml
@startuml location-service-interaction

actor   "Client"                            as client
queue   "RabbitMQ \n Notification Exchange" as rabbitmq_notifications
queue   "Kafka \n Broker"                   as kafka_broker

@enduml
```

-->

### Architectural Design

The project is structured by implementing hexagonal architecture, mapping layers to Gradle submodules.

```plantuml
@startuml repo-structure

skinparam component {
    BackgroundColor<<external>> White
    BackgroundColor<<executable>> #ccffcc
    BackgroundColor<<test>> cyan
}
skinparam DatabaseBackgroundColor LightYellow
skinparam NodeBackgroundColor White

component ":location-service" {
    [:commons] as C
    [:domain] as D
    [:application] as A

    [:presentation] as P
    [io.circe:circe-core_3] as circe <<external>>
    [io.grpc-*] as grpc <<external>>

    [:infrastructure] as I
    [org.http4s:http4s-*] as http4s <<external>>
    [com.typesafe.akka:akka-cluster-*] as akka <<external>>

    D -up-|> C
    A -up-|> D
    P -up-|> A
    circe <|-left- P
    grpc <|-right- P
    I -up-|> P
    http4s <|- I
    I -|> akka
}

@enduml
```
