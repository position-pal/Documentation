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
        in charge of tracking management logic
    end note
}
@enduml
```

### Behavior

The active controllers of the system is based on top of Akka actors.

```plantuml 
@startuml location-service-behavior

[*] -> NormalMode

NormalMode -> NormalMode : TrackingEvent / replace last position

NormalMode -up-> RoutingMode : StartRoutingEvent
RoutingMode: entry / notify all groups members
RoutingMode -up-> NormalMode : StopRoutingEvent / create snapshot of last position
RoutingMode -up-> RoutingCheckingMode : TrackingEvent
RoutingCheckingMode: entry / append position to route
RoutingCheckingMode: do / perform checks
state c <<choice>>
RoutingCheckingMode --> c
c --> RoutingMode : [""Continue""]
c --> RoutingMode : [""Alert""] / notify all groups members

NormalMode --> AlertMode : SOSAlertEvent
AlertMode: entry / notify all groups members
AlertMode: entry / replace last position
AlertMode --> AlertMode : TrackingEvent / append position to route
AlertMode --> NormalMode : StopSOSEvent
@enduml
```

### Interaction

```plantuml
@startuml location-service-interaction

actor   "Client"                            as client
queue   "RabbitMQ \n Notification Exchange" as rabbitmq_notifications
queue   "Kafka \n Broker"                   as kafka_broker

@enduml
```

### Architectural Design
