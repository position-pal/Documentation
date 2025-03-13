---
weight: 402
title: "Location Service design"
description: ""
draft: false
toc: false
---

<!--This chapter explains the strategies used to meet the requirements identified in the analysis.-->

In this section it is presented the abstract design of the **Location Service**.
As per best practices, the design is based on the **Domain-Driven Design** principles, and is presented in terms of the main three views: **structure**, **interaction**, and **behavior**.

## Abstract Design

### Structure

The main domain concepts and events are presented hereafter and reified in the following classes structure, following the DDD building blocks.

```plantuml 
@startuml location-service-structure-domain
package shared.kernel.domain {
    interface User <<entity>>
    interface UserId <<value object>>
    interface GroupId <<value object>>
    User *-left-> "1" UserId
}

package domain {
    interface Scope <<value object>> {
        + user: UserId
        + group: GroupId
    }

    UserId "1" <--* Scope
    GroupId "1" <--* Scope

    interface GPSLocation <<value object>> {
        + latitude: Double
        + longitude: Double
    }

    interface Address {
        + name: String
        + position: GPSLocation
    }

    Address *-left-> "1" GPSLocation

    '------------------------- Events -------------------------'
    interface DomainEvent {
        + timestamp: Instant
        + user: UserId
        + group: GroupId
        + scope: Scope
    }
    '''UserId "1" <--* DomainEvent
    '''GroupId "1" <---* DomainEvent
    DomainEvent *-right-> "1" Scope

    interface DrivenEvent extends DomainEvent
    class UserUpdate <<domain event>> implements DrivenEvent {
        + position: Option[GRSLocation]
        + status: UserState
    }

    interface DrivingEvent extends DomainEvent
    interface ClientDrivingEvent extends DrivingEvent

    class SampledLocation <<domain event>> {
        + position: GPSLocation
    }
    ClientDrivingEvent <|.. SampledLocation
    class SOSAlertTriggered <<domain event>> {
        + position: GPSLocation
    }
    ClientDrivingEvent <|.. SOSAlertTriggered
    class SOSAlertStopped <<domain event>>
    ClientDrivingEvent <|... SOSAlertStopped
    class RoutingStarted <<domain event>> {
        + position: GPSLocation
        + mode: RoutingMode
        + destination: GPSLocation
        + expectedArrival: Instant
    }
    ClientDrivingEvent <|.. RoutingStarted
    class RoutingStopped <<domain event>> 
    ClientDrivingEvent <|... RoutingStopped

    interface InternalDrivingEvent extends DrivingEvent
    class WentOffline <<domain event>>
    InternalDrivingEvent <|... WentOffline
    class StuckAlertTriggered <<domain event>> 
    InternalDrivingEvent <|.. StuckAlertTriggered
    class StuckAlertStopped <<domain event>> 
    InternalDrivingEvent <|... StuckAlertStopped
    class TimeoutAlertTriggered <<domain event>> 
    InternalDrivingEvent <|.. TimeoutAlertTriggered

    GPSLocation "1" <--* RoutingStarted
    GPSLocation "1" <--* SOSAlertTriggered
    GPSLocation "1" <--* SampledLocation

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
        INVALID(reason: String)
    }

    interface Tracking <<entity>> {
        + type Route = List[GPSLocation]
        + route: Route
        + addSample(sample: SampledLocation): Tracking
        + +(sample: SampledLocation): Tracking
    }

    interface MonitorableTracking <<entity>> extends Tracking {
        + mode: RoutingMode
        + destination: GPSLocation
        + expectedArrival: Instant
        - alerts: Set[Alert]
        + addAlert(alert: Alert): MonitorableTracking
        + removeAlert(alert: Alert): MonitorableTracking
        + has(alert: Alert): Boolean
    }

    MonitorableTracking o-l-> Alert
    MonitorableTracking *-r-> RoutingMode
    MonitorableTracking *--> "1..n" GPSLocation

    class Snapshot <<value object>> {
        + scope: Scope
        + userState: UserState
        + lastSampledLocation: Option[SampledLocation]
    }

    Session .. Snapshot

    interface Session <<aggregate root>> {
        + scope: Scope
        + userState: UserState
        + lastSampledLocation: Option[SampledLocation]
        + tracking: Option[Tracking]
        + updateWith(e: DrivingEvent): Either[UserState.INVALID, Session]
    }

    Session *-left-> "1" Scope
    Session *-right-> "1" UserState
    Session *--> "1" SampledLocation
    Session o--> "1" Tracking

}
@enduml
```

- **`Scope`**: A _value object_ representing the context in which an event occurs. It is composed of a user and a group, capturing the idea that a user's state can differ from group to group, enabling group-specific visibility and tracking.
- **`Tracking`**: An _entity_ representing the user's route information at a certain point in time, it is composed of a list of positions that can be interpolated to form a path between two geographical positions.
  - **`MonitorableTracking`**: a specialized `Tracking` _entity_ that includes the mode of transportation, the destination, the expected arrival time, enabling the system to monitor the user's route and trigger alerts when necessary.
- **`Session`**: An _aggregate root entity_ storing the overall state of a user in a group at a certain point in time. It acts as a state machine, updating the state and the tracking information based on the received events, ensuring the consistency of the user's state is maintained.
  - A **`Snapshot`** is a _value object_ capturing a snapshot of the user's state.
- **`DomainEvent`**: An _interface_ representing the base structure of a domain event, capturing the timestamp, the user, and the group in which the event occurs. It is the base type for all the events that occur in the system.
  - **`DrivingEvent`**: An _interface_ representing the base structure of a driving event, i.e. a valuable event guiding an application use case.
    - **`ClientDrivingEvent`**: A specialized `DrivingEvent` _interface_ representing the events that are triggered by the user's actions, such as sampling the location, triggering an SOS alert, starting or stopping a routing.
    - **`InternalDrivingEvent`**: A specialized `DrivingEvent` _interface_ representing the events that are triggered by the system, such as the user going offline, triggering a stuck alert, or a timeout alert.
  - **`DrivenEvent`**: An _interface_ representing the base structure of a driven event, i.e. an event triggered by the system as a result of some system state change / action.

The application services and repositories are presented in the following diagram, which presents only the main interfaces, leaving out the implementation and the adapters classes.

```plantuml
@startuml location-service-infrastructure
package application {

    package groups {
        interface UserGroupsReader {
            + groupsOf(user: UserId): Set[GroupId]
            + membersOf(group: GroupId): Set[UserId]
        }
        interface UserGroupsWriter {
            + addMember(groupId: GroupId, user: User)
            + removeMember(groupId: GroupId, userId: UserId)
        }
        interface UserGroupsStore <<repository>> <<out port>> extends UserGroupsReader, UserGroupsWriter 

        interface UserGroupsService <<service>> {
            + addedMember(event: AddedMemberToGroup)
            + removeMember(event: RemovedMemberFromGroup)
            + groupsOf(userId: UserId): Set[GroupId]
            + membersOf(groupId: GroupId): Set[UserId]
            + of(scope: Scope): Option[User]
        }
        class UserGroupsServiceImpl implements UserGroupsService {
            - userGroupsStore: UserGroupsStore
        }
        UserGroupsServiceImpl *--> UserGroupsStore
    }

    package notifications {
        interface NotificationService <<service>> <<out port>> {
            + sendToOwnGroup(\n    scope: Scope,\n    message: NotificationMessage\n)
            --
            + sendToGroup(\n    recipient: GroupId,\n    sender: UserId,\n    message: NotificationMessage\n)
            --
            + sendToAllMembersSharingGroupWith(\n    user: UserId,\n    sender: UserId,\n   message: NotificationMessage\n)
        }
        abstract class NotificationServiceProxy implements NotificationService {
            + send(command: PushNotificationCommand): Unit
        }
    }

    package sessions {
        interface UserSessionReader {
            + sessionOf(scope: Scope): Option[Session]
        }
        interface UserSessionWriter {
            + update(session: Session.Snapshot): Unit
        }
        interface UserSessionStore <<repository>> <<out port>> extends UserSessionReader, UserSessionWriter

        interface UsersSessionService <<service>> <<in port>> {
            + ofScope(scope: Scope): Option[Session]
            + ofGroup(groupId: GroupId): Stream[Session]
        }

        class UsersSessionServiceImpl implements UsersSessionService {
            - userSessionStore: UserSessionStore
        }
        UsersSessionServiceImpl *-left-> UserSessionStore
        UsersSessionServiceImpl *---> UserGroupsService
    }

    package tracking {
        interface MapsService <<service>> <<out port>> {
            + duration(mode: RoutingMode)(\n    origin: GPSLocation,\n    destination: GPSLocation\n): FiniteDuration
            --
            + distance(mode: RoutingMode)(\n    origin: GPSLocation,\n    destination: GPSLocation\n): Distance
        }

        interface OutcomeObserver <<service>> <<out port>> {
            + type Outcome
        }

        interface RealTimeTrackingService <<service>> <<in port>> {
            + handle(event: ClientDrivingEvent)
            + addObserverFor(scope: Scope)(observer: OutcomeObserver)
            + removeObserverFor(scope: Scope)(observer: OutcomeObserver)
        }
        RealTimeTrackingService *--> OutcomeObserver

        abstract class RealTimeTracker implements RealTimeTrackingService {
            # maps: MapsService
            # notifier: NotificationService
        }
        RealTimeTracker *--> MapsService
        RealTimeTracker *---> NotificationService
    }

}
@enduml
```

- `MapsService`: the service responsible for calculating the distance and the duration between two geographical positions, based on the mode of transportation.
- `NotificationService`: the service responsible for sending notifications, acting as a _proxy_ towards the notification service. The concrete adapter is in charge of sending the notification to the appropriate channel of the message broker.
- `RealTimeTracking`: the service responsible for handling the driving events, acting as an input port for the external adapters. It allows to register observers to be get back real-time updates.
- Clients can in any moment get a snapshot of the user's state and location by querying the `UsersSessionService` service, which is responsible for managing the user's session state.
  - The actual tracking information are stored through the `UserSessionStore` repository, which is responsible for the persistence of the user's session state. A `UserSessionStore` is both a `Writer` and a `Reader` for the `Session` entity. Separate write-side and read-side interfaces are defined to ensure the separation of concerns and the single responsibility principle, leaving the implementation open to adhere to CQRS pattern.
- `UserGroupsService` is responsible for managing the saving and retrieval of the groups members through the `UserGroupsStore` repository. Updates happen thanks the events propagated by the User service.

### Interaction

The interaction between the main components of the system is described in the following sequence diagram.

The Group Member connects to the `RealTimeTracking` service through a `Real Time Communication Connector` starting observing the updates of the group members it belongs to.
However, before starting reacting to these updates, it fetches the current state of all group members through the `UsersSessionService` service, ensuring a consistent view of their state.
Once the current state of all members is obtained, it starts reacting to the updates of other groups members while sending its own updates to the service.
The `RealTimeTracking` service, upon receiving the updates, reacts to the events and updates the user's session state, sending back the result to all the group members currently observing group's changes.

Please, note the diagram illustrates only the main success flow, leaving out the error handling and the edge cases.

```plantuml
@startuml location-service-interaction
autonumber

actor "Group Member" as User
control "Real Time \n Communication Connector" as RTC
participant UsersSessionService as USS
participant RealTimeTrackingService as RTT
database UserSessionStore as USSS

== Use case: Real-time tracking ==

activate User

User -> RTC: connect(<groupId, userId>)
activate RTC
RTC -> RTT: addObserverFor(<groupId, userId>)(me)
activate RTT
RTT -> RTT: save(observer)
RTT --> RTC: ok
deactivate RTT
RTC --> User: ok

User -> USS: ofGroup(groupId)
activate USS
loop#Lightblue for each group member
    USS -> USSS: sessionOf(<scope>)
    activate USSS
    USSS --> USS: Some[Session]
    deactivate USSS
end
USS --> User: Stream[Session]
deactivate USS

loop#gold while connected, periodically
    User ->> RTC: send(ClientDrivingEvent)
    RTC -> RTT: handle(ClientDrivingEvent)
    activate RTT
    RTT -->> RTC: ack
    RTC -->> User: ack
    RTT -> RTT: react(event): UserUpdate
    RTT -> USSS: update(UserUpdate)
    activate USSS
    USSS --> RTT: ok
    deactivate USSS
    loop#Lightblue for each observer
        RTT --> RTC: notify(UserUpdate)
        RTC --> User: UserUpdate
    end
end

deactivate RTC
deactivate User

@enduml
```

### Behavior

As an event driven architecture, the state of each group's member can be described by the following state diagram, drawing the possible state transitions that can be fired by one of the above `DrivingEvent`.

```plantuml
@startuml userstate-behavior

[*] -> NormalMode

state NormalMode {
    [*] --> Active
    Active --> Active : ""SampledLocation""

    Active -left-> Inactive : ""WentOffline""
    Inactive -right-> Active : ""SampledLocation""

    Routing : entry [first time] / trigger notification
    Routing : entry / perform checks 
    Active -down-> Routing : ""RoutingStarted""
    Routing -up-> Active : ""RoutingStopped"" \n / trigger notification
    Inactive --> Routing : ""RoutingStarted""
    Routing -> Routing : ""SampledLocation""

    Warning : entry [not already notified the firing event] / trigger notification
    Routing --> Warning : ""WentOffline"", \n ""StuckAlertTriggered"", \n ""TimeoutAlertTriggered"" / ""late<-true""
    Warning -up-> Routing : ""StuckAlertStopped"" [""!late""], \n ""SampledLocation"" [""!late""]
    Warning -up-> Active : ""RoutingStopped"" \n / trigger notification 
    Warning -> Warning : ""SampledLocation"" [""late""], \n ""TimeoutAlertTriggered"", \n ""StuckAlertTriggered"", \n ""StuckAlertStopped"" [""late""]
}

state SOSMode {
    [*] -> SOS
    SOS : entry [first time] / trigger notification
    SOS --> SOS : SampledLocation
}

NormalMode --> SOSMode : ""SOSAlertTriggered""
SOSMode --> NormalMode : ""SOSAlertStopped""

@enduml
```
