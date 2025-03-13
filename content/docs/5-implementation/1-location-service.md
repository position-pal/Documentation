---
weight: 502
title: "Location Service implementation details"
description: ""
draft: false
mermaid: true
toc: true
---

This chapter provides an overview of the implementation details of the **Location Service**.

## User Tracking and Real-time Management

The most important and critical feature of the Location Service is the **tracking** of the user's location and real-time management of their  state considering the high volume of data that needs to be processed in real-time.
Moreover, the service is in charge of the user monitoring during the _SOS_ and _Routing_ modes, which require to take real-time actions to ensure the user's safety.

For what concern the technology stack, the real-time location and user state updates are managed through the **WebSocket** protocol, which allows bidirectional communication between the client and the service.
While this is a common choice for real-time applications and it is well supported by the majority of the programming languages and frameworks, it is worth mentioning that the WebSocket protocol brings with it some challenges in terms of scalability of the service, which is a fundamental requirement for the system.
Indeed, each socket connection is bound to a specific instance of the service, which means it is needed to make sure that all the requests from specific users are forwarded to the same instance of the service.

One another important aspect to consider is that this service is intrinsically **stateful**: it needs to keep track of the user's location and state and take actions based on the history of the past updates and the current state.

To address these challenges we adopted a two-level approach.
First, the system has been designed and implemented with a **fully event-driven** approach, starting from the core of the service - the domain - on top of a "event reactions" mechanism.
Second, on the technological level, we selected a distributed actor framework based on **Akka Cluster** thanks to its capabilities to manage and allocate, in a location-transparent way, the actors across the cluster nodes, allowing to scale the service horizontally and to ensure the fault-tolerance of the system.

For these reasons the Location Service is implemented in **Scala**.

### Event reactions

The core of the Location Service is built around the [**event reactions** concept](https://github.com/position-pal/location-service/blob/main/domain/src/main/scala/io/github/positionpal/location/domain/EventReactionADT.scala), which represents the actions that the service takes in response to the service driving events.

Thanks to Scala, the event reactions are implemented as ADTs on top of a convenient DSL that allows to define and compose them as a pipeline in a functional way with a "short-circuit" semantic: if one step in the pipeline return a `Left` outcome (the opposite of a `Right` outcome) the pipeline stops and the result is returned to the caller.
This allows, in the future, to easily extend the pipeline with new steps without changing the existing ones, thus ensuring the extensibility and maintainability of the system.

The implemented pipeline is used to react to the `DrivingEvents` and take appropriate actions to track appropriately the user's location and state and is compose of the following steps:

```mermaid
flowchart LR
    id1(Pre check notifier)
    id2(Arrival check)
    id3(Stationary check)
    id4(Arrival timeout check)
    id1 --> id2
    id2 --> id3
    id3 --> id4
```

1. **Pre check notifier**: this steps intercepts valuable events for which a notification has to be sent to the user.
2. **Arrival check**: this step checks if the user is in routing mode and has arrived at a specific location.
3. **Stationary check**: this step checks if the user is in routing mode and has become stuck in a specific location.
4. **Arrival timeout check**: this step checks if the user is in routing mode and has not arrived at the expected destination within the expected time.

For example, the following snippet shows the reaction _Arrival check_ reaction implementation:

```scala
/** A [[TrackingEventReaction]] checking if the position curried by the event
  * is near the arrival position. 
  */
object ArrivalCheck:

  def apply[F[_]: Async](
    using maps: MapsService[F], notifier: NotificationService[F], groups: UserGroupsService[F],
  ): EventReaction[F] =
    on[F]: (session, event) =>
      event match
        case e: SampledLocation if session.tracking.exists(_.isMonitorable) =>
          for
            config <- ReactionsConfiguration.get
            tracking <- session.tracking.asMonitorable.get.pure[F]
            distance <- maps.distance(tracking.mode)(e.position, tracking.destination.position)
            isNear = distance.toMeters.value <= config.proximityToleranceMeters.meters.value
            _ <- if isNear then sendNotification(session.scope, successMessage) else Async[F].unit
          yield if isNear then Left(RoutingStopped(e.timestamp, e.scope)) else Right(Continue)
        case _ => Right(Continue).pure[F]

  private val successMessage = notification(" arrived!", " has reached their destination on time.")
```

They can be composed in a pipeline as follows:

```scala
  val reactionPipeline = (
    PreCheckNotifier[IO] >>> ArrivalCheck[IO] >>> StationaryCheck[IO] >>> ArrivalTimeoutCheck[IO]
  )(session, event)
```

### Akka Cluster to the rescue

Since the service should track a large number of users and their tracking information concurrently for each group, the actor model, and in particular, Akka is the perfect fit for this scenario since it can handle smoothly a huge number of actors per node thanks to their very light memory footprint.

In particular, the Location Service is implemented using the [Akka Cluster Sharding](https://doc.akka.io/docs/akka/current/typed/cluster-sharding.html) module, which allows to **distribute stateful actors** across the cluster nodes in a **location-transparent** way.
This means that the service can scale horizontally by adding more nodes to the cluster and the actors will be **automatically distributed** and, possibly, **rebalanced** across the nodes without any kind of intervention **from the underlying infrastructure**.
This is possible thanks to the fact the interaction between the actors is guided by their only _logical_ identifier despite their physical location.
Moreover, _Cluster Sharding_ entities have a configurable _passivation_ mechanism that allows to automatically stop the actors that are not used for a certain amount of time, thus freeing the resources and ensuring the system's efficiency.

Additionally, the Akka framework support the integration of websockets through the [Akka HTTP](https://doc.akka.io/docs/akka-http/current/index.html) module, which allows to easily expose the WebSocket endpoints to the clients and to manage the connections and their handlers through actors distributed across the cluster, zeroing the need for additional infrastructure components to deal with scaling and fault-tolerance.

For our purposes two main actor entities have been designed:

- `RealTimeUserTracker` actor which is responsible for managing and tracking a user in real-time in a specific group (recall different group may have different views of the user state and location);
- `GroupManager` actor which keeps track of all active websocket connections for a specific group (or, rather, all the actor references of the websocket handlers), acting as a _router_ for the messages between the `RealTimeUserTracker` actors and the clients.

![Akka actors](/images/ls-actors.svg)

The main flow is described in the following diagram:

1. the client application connects to the websocket endpoint exposed by the service and a new actor is created to handle the connection;
2. upon connection the websocket handler actor register itself to the appropriate `GroupManager` actor to receive the updates for the specific group it is interested in;
3. when the client application send a new `DrivingEvent` to the websocket handler actor through the websocket connection, it forwards the event to the the appropriate `RealTimeUserTracker` actor for the specific user and group the event is related to;
4. the `RealTimeUserTracker` actor reacts to the event and updates the user state and location accordingly (using the pipeline described above) sending the updated state and location to the `GroupManager` actor;
5. the `GroupManager` actor forwards the updates to all the registered websocket handler actors.

It is worth noting both the actors are sharded across the cluster nodes and, hence, it is not known in advance where they are located, but since the interaction is guided by their logical identifier, the system is able to route the messages to the correct actor even though they are located on different nodes from the one the client is connected to.

![Akka Cluster Sharding](/images/ls-sharding.svg)

When using sharding, actors entities can be moved across the cluster nodes and, since they are stateful, a persistence mechanism must be in place to ensure the state is fully recovered when the actor is moved to a different node.
Akka follows the ***Event Sourcing*** pattern: only the _events_ that are persisted by the actor are stored in the journal of events (the actor when receiving an event can choose whether persisting or ignoring it).
Upon recovery, the actor automatically replays the events, rebuilding its state from scratch.
This can be either the full history or starting from a checkpoint in a snapshot, that can significantly reduce the recovery time.
This approach allows very high transaction rates and efficient replication.

```scala
/** The actor in charge of tracking the real-time location of users, reacting to
  * their movements and status changes. This actor is managed by Akka Cluster Sharding.
  */
object RealTimeUserTracker:

  /** Uniquely identifies the types of this entity instances (actors) 
    * that will be managed by cluster sharding. */
  val key: EntityTypeKey[Command] = EntityTypeKey(getClass.getSimpleName)

  /** Labels used to tag the events emitted by this kind entity actors to distribute them over
    * several projections. Each entity instance selects it (based on an appropriate strategy) 
    * and uses it to tag the events it emits.
    */
  val tags: Seq[String] = Vector.tabulate(5)(i => s"${getClass.getSimpleName}-$i")

  def apply(scope: Scope, tag: String)(
    using NotificationService[IO], MapsService[IO], UserGroupsService[IO],
  ): Behavior[Command] =
    Behaviors.setup: ctx =>
      given ActorContext[Command] = ctx
      Behaviors.withTimers: timer =>
        val persistenceId = PersistenceId(key.name, scope.encode)
        // Create the Event Sourced Behavior with initial state an empty session
        EventSourcedBehavior(persistenceId, Session.of(scope), commandHandler(timer), eventHandler)
          .withTagger(_ => Set(tag))
          .snapshotWhen((_, event, _) => event == RoutingStopped, deleteEventsOnSnapshot = true)
          .withRetention: // to free up space in the journal
            snapshotEvery(numberOfEvents = 100, keepNSnapshots = 1).withDeleteEventsOnSnapshot
          .onPersistFailure: // to handle persistence failures
            restartWithBackoff(minBackoff = 2.second, maxBackoff = 15.seconds, randomFactor = 0.2))
  
  // The event handler is responsible for updating the state of the entity
  private def eventHandler: (Session, Event) => Session = ...

  // The command handler is responsible for handling the incoming commands
  // triggering the appropriate responses and possibly persisting new events
  private def commandHandler(
    timerScheduler: TimerScheduler[Command]
  ): (Session, Command) => Effect[Event, Session] = ...
```

As you can see the `RealTimeUserTracker` is implemented as an `EventSourceBehavior` whose initial state is an empty `Session`.
Indeed, the Akka Sharding entities are very often carrier actors for the _domain aggregates_.

Finally, to complete the picture, [**Akka Projection**](https://doc.akka.io/libraries/akka-projection/current/overview.html) is used to project the events emitted by the `RealTimeUserTracker` actors to the read-side representation of the user state and tracking information, which is then used by the other services to provide the user with the most up-to-date information.
This approach follows the **CQRS** pattern and allows to separate the read and write concerns, ensuring the system's scalability and performance.

![Akka Projection](/images/ls-projection.svg)

As data storage component, **Cassandra** has been chosen for its scalability and performance characteristics, which are well suited for the high volume of data that needs to be stored and queried.

## Location Service API

To allow users to get the most up-to-date information about the state and tracking information of the users, the Location Service expose a set of gRPC APIs that allow to query them from the Read-Side representation obtained through the Akka Projection described above.

Here the service definition:

```protobuf
service UserSessionsService {
  rpc GetCurrentSession(GroupId) returns (stream SessionResponse) { }
  rpc GetCurrentLocation(Scope) returns (LocationResponse) { }
  rpc GetCurrentState(Scope) returns (UserStateResponse) { }
  rpc GetCurrentTracking(Scope) returns (TrackingResponse) { }
}
```

As you can see, we take full advantage of the gRPC streaming capabilities to allow the clients to get the most up-to-date information through a lazy stream of responses.
This is important because the response can become quickly huge and returning it in a single response can be very inefficient and slow.

One important aspect to remark and that justify the need for this service to receive groups updates through the message broker is that the service needs to know the members of the groups to provide the correct information to the clients.
Moreover, when a user leaves a group, the service needs to be notified to stop tracking the user.

## Async API Documentation

The Location Service API is documented using the **AsyncAPI specification**, which provides a standardized format for defining and describing asynchronous APIs. By leveraging _AsyncAPI_, the Location Service API ensures clear communication patterns, message structures, and data formats

<iframe src="https://position-pal.github.io/location-service/asyncapi/" width="100%" height="700"></iframe>

[Ref: [Location Service AsyncAPI](https://position-pal.github.io/location-service/asyncapi/)].
