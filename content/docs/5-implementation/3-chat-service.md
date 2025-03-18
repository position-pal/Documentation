---
weight: 503
title: "Chat Service implementation details"
description: ""
draft: false
toc: true
---
## Chat Messaging and Real-time Management

The primary functions of the chat service are to manage the _chat groups_ and the relative _messages_ that are exchanged between users of these groups.
In most of the cases the amount of messages exchanged is high, and the service needs to manage them in real-time with low latency of response.

We built a **WebSocket-based** communication system using an actor model. Specifically, we leveraged the **Event Sourcing** module from the _Akka framework_ to handle Group instances. This approach treats Events as first-class citizens while maintaining consistent chat state.

WebSockets proved ideal for this use case since each client establishes and maintains an open connection with the server throughout the chat session. This design also addresses scalability concerns, as each connection binds to a specific service instance, ensuring all requests from a user route to the same service instance.
To further enhance scalability, we implemented the whole system using Akka Cluster, which allows automatic and trasnparent allocation of actors across cluster nodes, ensuring horizontal scaling and fault tolerance.

### Clean Architecture Implementation

For the Chat Service implementation, we adopted a **Clean Architecture** approach with clearly separated layers. This architectural choice provides significant benefits for a service responsible for sensitive user data:

```plaintext
chat-service/
├── amqp/           # Message broker integration
├── common/         # Common part of the whole service 
├── domain/         # Core business entities and rules
├── application/    # Use cases and service interfaces
├── storage/        # Database and persistence implementations
├── presentation/   # Protocol definitions
├── grpc/           # gRPC service implementations
├── sockets/        # Realtime communication
├── infrastructure  # Contains the main components 
└── entrypoint/     # Application bootstrap
```

Each layer has a specific responsibility, with dependencies pointing inward toward the domain layer. This approach allows us to isolate the core business logic from implementation details.


## Chat Management

Inside the chat system are present two type of actor entities: The `GroupEventSourceHandler` and the `ClientActor`. The first one is developed upon the Event Sourcing pattern, the [entity](https://github.com/position-pal/chat-service/blob/main/infrastructure/src/main/scala/io/github/positionpal/group/GroupEventSourceHandler.scala) it receives commands that represents the actions that can be performed on the group, and emits events that represents changes that have been applied to the group. 

In the following snippet is shown the implementation that handles a new client joining the group:
```scala
object GroupEventSourceHandler:

  def apply(groupId: String): Behavior[Command] =
    EventSourcedBehavior[Command, Event, State](
      persistenceId = PersistenceId(entityKey.name, groupId),
      emptyState = Group.empty(groupId),
      commandHandler = commandHandler,
      eventHandler = eventHandler,
    )

  /** Handle an incoming command from the outside, triggering an event in the domain as response
    * @param state The actual state of the entity
    * @param command The received command
    * @return Return a [[ReplyEffect]] with the response of the operation
    */
  private def commandHandler(state: State, command: Command): Effect[Event, State] = command match
    case ClientJoinsGroup(clientID, replyTo) =>
      if state.isPresent(clientID) then
        Effect.reply(replyTo):
          StatusReply.Error(CLIENT_ALREADY_JOINED withClientId clientID)
      else
        Effect.persist(ClientJoinedToGroup(clientID)).thenReply(replyTo): state =>
          StatusReply.Success(ClientSuccessfullyJoined(state.clientIDList))
  
  /** Handle a triggered event letting the entity pass to a new state
    * @param state The actual state of the entity
    * @param event The triggered event
    * @return The new state of the entity
    */
  private def eventHandler(state: State, event: Event): State = event match
    case ClientJoinsGroup(clientID, replyTo) =>
      if state.isPresent(clientID) then
        Effect.reply(replyTo):
          StatusReply.Error(CLIENT_ALREADY_JOINED withClientId clientID)
      else
        Effect.persist(ClientJoinedToGroup(clientID)).thenReply(replyTo): state =>
          StatusReply.Success(ClientSuccessfullyJoined(state.clientIDList))
```

The `ClientActor` is instead responsible for managing the communication between the client and the group. It receives messages from the client and forwards them to the group, and vice versa. This entity is created through the webserver when a new connection is established, and is then linked to the `GroupEventSourceHandler` that manages the group the client is part of. As [_Akka HTTP_](https://doc.akka.io/libraries/akka-http/current/index.html) is used as the webserver, the `ClientActor` entity is created using an [_Akka Stream_](https://doc.akka.io/docs/akka/current/stream/index.html) that allows to handle the WebSocket connection.

![Ws Flow](/images/wsflow.png)

The image above shows the flow of messages between the client and the group. When a new connection is estabilished then a new Sink and Source are created:
- The sink is used to receive messages from the client and forward them to the group using the `GroupService`;
- The source is an Actor that is used to send messages transmitted on the group to the client.

The reference of the source is the ClientActor itself, and it is saved in the respective `GroupEventSourceHandler` that manages the group the client is part of.

```scala
// Sink creation
val toGroup: Sink[Message, Unit] = Flow[Message].collect:
  case TextMessage.Strict(msg) => msg
.map: text =>
  ChatMessageADT.now(text, clientID, groupID)
.watchTermination(): (_, watcher) =>
  watcher.onComplete: _ =>
    service.disconnect(groupID)(clientID)
.to:
  Sink.foreach(message => service.message(groupID)(message))

// Source creation
val toClient: Source[Message, ActorRef[CommunicationProtocol]] = ActorSource.actorRef(
  completionMatcher = { case Complete => },
  failureMatcher = { case ex: Throwable => ex },
  bufferSize = 1000,
  overflowStrategy = OverflowStrategy.fail,
).mapMaterializedValue: ref =>
  service.connect(groupID)(clientID, ref)
  ref
.map:
  case text: CommunicationProtocol => TextMessage(Json.encode(text).toUtf8String)

Flow.fromSinkAndSource(toGroup, toClient)
```

## AMQP Integration

The whole system have an integrated AMQP broker that allows the communication between the various services, the chat service is able to handle incoming messages from the broker in order to update the state of the groups. [Alpakka](https://doc.akka.io/docs/alpakka/current/index.html), a reactive integration library for Akka Streams, is used to consume the messages that comes from the AMQP broker.

```scala
GraphDSL.create():
  implicit graph =>
    import GraphDSL.Implicits.*

    // Definition of the queues that are used to consume the messages
    val sources = queues.map: queue =>

      val queueDeclaration = QueueDeclaration(queue.name)
      val exchangeDeclarations = queue.exchanges.map: exchange =>
      val declaration = ExchangeDeclaration(exchange.name, exchange.exchangeType).withDurable(exchange.durable)
      val binding = BindingDeclaration(queue = queue.name, exchange = exchange.name)
          .withRoutingKey(queue.routingKey.getOrElse(""))
      (declaration, binding)

    val settings = NamedQueueSourceSettings(provider, queue.name)
      .withDeclarations(
        queueDeclaration +: exchangeDeclarations.flatMap(decls => List(decls._1, decls._2)),
      ).withAckRequired(false)
      
    Source.fromGraph(AmqpSource.atMostOnceSource(settings, bufferSize = 10)).map(msg => (queue.name, msg))

    val merger = graph.add(Merge[(String, ReadResult)](queues.length))

    val messageProcessorUnit = Flow[(String, ReadResult)].mapAsync(1):
      case (_, msg) =>
      Future:
        val header = msg.properties.getHeaders.get("message_type").toString
        val result = Either.catchOnly[IllegalArgumentException](EventType.valueOf(header))
        .leftMap(_ => s"Error while retrieving $header")
        result match
        case Right(msgType: EventType) => messageHandler.handle(msgType, msg.bytes)
        case e => logger.error(s"I received a message that I can't handle because: $e")

    val sink = Sink.ignore

    sources.foreach(_ ~> merger)
    merger ~> messageProcessorUnit ~> sink

    ClosedShape
```

Here is shown the creation of the AMQP source that is used to consume the messages from the broker. The user is able to define and pass the queue where the messages are consumed, for each of these a new Source is created. The messages are then processed by the `messageProcessorUnit` that is a Flow that extracts the message type from the header then calls an handler function that is responsible for processing the message. Finally the dsl allows us to connect the sources to the merger that is connected to the `messageProcessorUnit` and then to the sink that is used to consume the messages.
