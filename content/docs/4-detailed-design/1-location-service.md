---
weight: 401
title: "Location Service"
description: ""
icon: "article"
draft: false
toc: false
---

The location service is responsible for the real-time location tracking and management of the users tracking information.

## Abstract Design

### Main domain concepts (from knowledge crunching)

| Concept  | Description                                                                                                              | Synonyms |
| -------- | ------------------------------------------------------------------------------------------------------------------------ | -------- |
| Location | A specific point on a geographical plane, represented by coordinates that indicates where something / someone is located | Position |
| Route    | A set of positions that can be interpolated forming a path between two geographical positions                            | Path     |
| Tracking | Represent the user route information at a certain point in time                                                          |          |
| State    | State of a user at a certain time, the values that it could assume are: online, offline and SOS                          |          |

### Structure

The main domain concepts and events are presented hereafter and reified in the following classes structure, following the DDD principles.

```plantuml 
@startuml location-service-structure-domain
package shared.kernel.domain {
    interface User
    interface UserId <<value object>>
    interface GroupId <<value object>>
    User *-l-> "1" UserId
}

package domain {
    interface Scope {
        + user: User
        + group: GroupId
    }

    interface GPSLocation <<value object>> {
        + latitude: Double
        + longitude: Double
    }

    '------------------------- Events -------------------------'
    interface DomainEvent {
        + timestamp: Instant
        + user: User
        + group: GroupId
        + scope: Scope
    }
    User "1" <--* DomainEvent
    GroupId "1" <---* DomainEvent
    DomainEvent *-right-> "1" Scope

    interface DrivenEvent extends DomainEvent
    class UserUpdate <<domain event>> implements DrivenEvent {
        + position: Option[GRSLocation]
        + status: UserState
    }

    interface DrivingEvent extends DomainEvent
    interface ClientDrivingEvent extends DrivingEvent

    class SampledLocation <<domain event>> implements ClientDrivingEvent {
        + position: GPSLocation
    }
    class SOSAlertTriggered <<domain event>> implements ClientDrivingEvent {
        + position: GPSLocation
    }
    class SOSAlertStopped <<domain event>> implements ClientDrivingEvent
    class RoutingStarted <<domain event>> implements ClientDrivingEvent {
        + position: GPSLocation
        + mode: RoutingMode
        + destination: GPSLocation
        + expectedArrival: Instant
    }
    class RoutingStopped <<domain event>> implements ClientDrivingEvent

    interface InternalDrivingEvent extends DrivingEvent
    class WentOffline <<domain event>> implements InternalDrivingEvent
    class StuckAlertTriggered <<domain event>> implements InternalDrivingEvent
    class StuckAlertStopped <<domain event>> implements InternalDrivingEvent
    class TimeoutAlertTriggered <<domain event>> implements InternalDrivingEvent

    GPSLocation --* RoutingStarted
    GPSLocation --* SOSAlertTriggered
    GPSLocation --* SampledLocation

    '------------------------- Aggregates -------------------------'
    enum RoutingMode {
        DRIVING
        WALKING
        CYCLING
    }

    enum Alert {
        STUCK
        LATE
        OFFLINE
    }

    enum UserState {
        ACTIVE
        INACTIVE
        SOS
        ROUTING
        WARNING
    }

    interface Route {
        + path: List[GPSLocation]
    }

    interface Tracking {
        + route: Route
        + addSample(sample: SampledLocation): Tracking
        + +(sample: SampledLocation): Tracking
    }

    Tracking *-right- Route

    interface MonitorableTracking extends Tracking {
        + mode: RoutingMode
        + destination: GPSLocation
        + expectedArrival: Instant
        - alerts: Set[Alert]
        + addAlert(alert: Alert): MonitorableTracking
        + removeAlert(alert: Alert): MonitorableTracking
        + has(alert: Alert): Boolean
    }

    MonitorableTracking o-- Alert
    MonitorableTracking o-- RoutingMode
    MonitorableTracking *-- GPSLocation

    interface Session {
        + scope: Scope
        + userState: UserState
        + lastSampledLocation: SampledLocation
        + tracking: Option[Tracking]
        + updateWith(e: DrivingEvent): Session
    }

    Session *-left-> "1" Scope
    Session *-right-> "1" UserState
    Session *--> "1" SampledLocation
    Session o--> "1" Tracking

}
@enduml
```

- **`Scope`**: Represents the context in which an event occurs, it is composed of a user and a group, capturing the idea that a user's state can differ from group to group, enabling group-specific visibility and tracking.

<!--

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

-->

### Behavior

<!--
The active controller of the system is based on top of Akka actors which allows for a scalable and fault-tolerant system without arranging a complex infrastructure for it.
-->

```plantuml
@startuml userstate-behavior

[*] -> NormalMode

state NormalMode {
    [*] --> Active
    Active --> Active : ""SampledLocation""

    Active -left-> Inactive : ""WentOffline""
    Inactive -right-> Active : ""SampledLocation""

    Active -down-> Routing : ""RoutingStarted""
    Routing -up-> Active : ""RoutingStopped""
    Inactive --> Routing : ""RoutingStarted""
    Routing -> Routing : ""SampledLocation""

    Routing --> Warning : ""WentOffline"", \n ""StuckAlertTriggered"", \n ""TimeoutAlertTriggered"" / ""late<-true""
    Warning -up-> Routing : ""StuckAlertStopped"", \n ""SampledLocation"" [""!late""]
    Warning -up-> Active : ""RoutingStopped""
    Warning -> Warning : ""SampledLocation"" [""late""], \n ""TimeoutAlertTriggered"", \n ""StuckAlertTriggered""
}

state SOSMode {
    [*] -> SOS
}

NormalMode --> SOSMode : ""SOSAlertTriggered""
SOSMode --> NormalMode : ""SOSAlertStopped""

@enduml
```

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

<!--
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
-->
