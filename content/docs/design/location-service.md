---
weight: 301
title: "Location Service"
description: ""
icon: "article"
date: "2024-08-02T16:21:33+02:00"
lastmod: "2024-08-02T16:21:33+02:00"
draft: false
toc: false
---

The location service is responsible for location tracking and management.

## Abstract Design

### Main domain concepts (from knowledge crunching)

`TODO: To keep in sync with the code`

| Concept | Description | Synonyms |
|---|---|---|
| Position | GPS coordinates | |
| Route | A set of positions that can be interpolated forming a path between two geographical positions | Path |
| Session | Represent a state and a position of a user at a certain time | Tracking |
| State | State of a user at a certain time, the values that it could assume are: online, offline and SOS | |

### Structure

```plantuml
@startuml location-service-structure
package infrastructure {
    package application {
        package domain {
            interface GPSPosition <<value object>> {
                + latitude: Double
                + longitude: Double
            }

'            interface Address <<value object>> {
'                + street: String
'                + city: String
'                + zip: String
'                + position: GPSPosition
'            }
'
'            Address *-r- "1" GPSPosition

            interface User <<entity>> {
                + id: UserId
                + inGroups: Set<GroupId>
            }
            interface UserId <<value object>>
            interface GroupId <<value object>>

            User *-u- "N" UserId
            User *-u- "N" GroupId

            interface Event {
                + timestamp: Date
                + user: User
            }

            User "1" --* Event

            interface StartRoutingEvent <<domain event>> extends Event {
                + arrivalPosition: GPSPosition
                + estimatedArrivalTime: Date
            }

            StartRoutingEvent *-- "1" GPSPosition

            interface TrackingEvent <<domain event>> extends Event {
                + position: GPSPosition
            }

            TrackingEvent *-- "1" GPSPosition

            interface StopRoutingEvent <<domain event>> extends Event

            interface SOSAlertEvent <<domain event>> extends Event {
                + position: GPSPosition
            }

            SOSAlertEvent *-- "1" GPSPosition
            
            interface Route <<aggregate root>> {
                + event: StartRoutingEvent
                + positions: List<TrackingEvent>
                + addTrace(TrackingEvent: TrackingEvent): Route
            }

            Route *-u- "1" StartRoutingEvent
            Route *-u- "N" TrackingEvent
        }

        interface TrackingEventsStore <<outbound port>> {
            + update(TrackingEvent: TrackingEvent)
            + by(user: User): TrackingEvent
        }

        TrackingEventsStore o.up. TrackingEvent

        interface RoutesStore <<outbound port>> {
            + update(Route: Route)
            + by(user: User): Route
            + delete(Route: Route)
        }

        RoutesStore o.up. Route

        interface NotificationsService <<outbound port>> {
            + notify(notificationEvent: NotificationEvent)
        }
        note right of NotificationsService::notify
            ""NotificationEvent"" is in 
            shared kernel module (?)
        end note

        User .up.o NotificationsService

        interface MapsService <<outbound port>> {
            + estimateArrivalTime(start: GPSPosition, end: GPSPosition): Date
            + distance(start: GPSPosition, end: GPSPosition): GPSPosition
        }

        MapsService o.up. GPSPosition

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

        UserTrackingInfoService o.r. TrackingEvent
        UserTrackingInfoService o.r. State

        interface RoutesTrackingService <<outbound port>> {
            + onNewRoute()
            + onRoutingEvent()
        }
        RoutesTrackingService o.. Event

        interface RoutesInfoService <<inbound port>> {
            + routeOf(user: User): Route
        }
        RoutesInfoService o.u. Route

        interface RealTimeTrackingService <<inbound port>> {
            + onNewEvent(event: Event)
        }
        RealTimeTrackingService o.l. Event
    }

    class NotificationsServiceAdapter implements application.NotificationsService
    note top of NotificationsServiceAdapter
        This class is an adapter 
        that forwards notifications to 
        the notification microservice
        through message broker
    end note

    class MapsServiceAdapter <<outbound adapter>> implements application.MapsService
    note right of MapsServiceAdapter
        Uses external geocoding and maps APIs
    endnote

    class RealTimeTrackingKafkaAdapter <<inbound adapter>>
    RealTimeTrackingKafkaAdapter .up.> application.RealTimeTrackingService : <<uses>>

    class UserTrackingInfoGrpcAdapter <<inbound adapter>> 
    UserTrackingInfoGrpcAdapter .up.> application.UserTrackingInfoService : <<uses>>

    class RoutesTrackingServiceKafkaAdapter implements application.RoutesTrackingService

    class RoutesInfoGrpcAdapter
    RoutesInfoGrpcAdapter .up.> application.RoutesInfoService : <<uses>>
}
@enduml
```

### Behavior

The active controllers of the system is based on top of Akka actors.

```plantuml 
@startuml location-service-behavior

[*] --> Idle

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
