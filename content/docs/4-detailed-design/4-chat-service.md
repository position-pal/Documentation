---
weight: 405
title: "Chat Service design"
description: ""
draft: false
toc: false
---

Chat service is responsible for managing the **communication between users in _real-time_**. This document describes the detailed design of the chat service, including its architecture, components, and interactions.

## Abstract Design

Here are presented the main components of the chat service, we start describing the foundamental entities of the domain, then we move to the infrastructure layer, where we define the commands and events that will be used to interact with the domain entities.

### Structure

```plantuml
@startuml chat-service-structure-domain
hide empty members
package shared.kernel.domain {
    interface User <<entity>>
    interface UserId <<value object>>
    interface GroupId <<value object>>
    User *-left-> "1" UserId
}

package domain {

    package client {

        interface ClientID <<value object>> {
            + value: String
        }

        interface OutputReference <<value object>>
        enum ClientStatus {
            ONLINE
            OFFLINE
        }

        interface Client <<entity>> {
            + id: ClientID
            + status: ClientStatus
            + outputReference: OutputReference
        }

        Client *-right-> "1" ClientID
        Client *-down-> "1" OutputReference
        Client *-left-> "1" ClientStatus
    }

    package group {

        interface Group <<entity>> {
            + id: GroupId
            + clients: List<Client>
        }

        interface GroupID <<value object>>
        Group *-right-> "1" GroupID
        
    }

    interface ClientMessage <<entity>> {
        + from: ClientId
        + to: GroupId
        + content: String
        + timestamp: DateTime
    }

    ClientMessage *-up-> "1" domain.client.ClientID
    ClientMessage *-down-> "1" domain.group.GroupID
    
    domain.client.ClientID .up. UserId
    GroupID .up. shared.kernel.domain.GroupId
    
}
@enduml
```

- **Client**: An entity that represents a user connected to the chat service. It has an identifier, a status, and a reference to the output channel.
  - **ClientID**: A value object that represents the unique identifier of a client that connects to the chat service. This is a 1-1 mapping to the user identifier used in the shared kernel.
  
  - **OutputReference**: A value object that represents the reference to the output channel of a client. This reference is used to send messages to the client.
- **Group**: An entity that represents a group of clients that can communicate with each other. It has an identifier and a list of clients.
  - **GroupID**: A value object that represents the identifier of a group. This is a 1-1 mapping to the group identifier used in the shared kernel.
- **ClientMessage**: An entity that represents a message sent by a client to a group. It contains the sender, the group, the content, and the timestamp of the message.

In the following diagram are presented the main services interfaces that will be used to interact with the domain entities and to respond to the external events.

```plantuml
@startuml chat-service-structure-infrastructure
hide empty members
package infrastructure {

    package event {
        interface GroupEvent <<domain event>> 
        interface ClientJoinedToGroup <<domain event>> extends GroupEvent
        interface ClientLeavedFromGroup <<domain event>> extends GroupEvent
        interface ClientConnected <<domain event>> extends GroupEvent
        interface ClientDisconnected <<domain event>> extends GroupEvent 
        interface Message <<domain event>> extends GroupEvent
    }

    package command {
        interface GroupCommand 
        interface DeleteGroup extends GroupCommand
        interface ClientJoinsGroup extends GroupCommand
        interface ClientLeavesGroup extends GroupCommand
        interface ClientConnects extends GroupCommand
        interface ClientDisconnects  extends GroupCommand
        interface SendMessage extends GroupCommand
    }

    
    abstract class GroupHandler {
        + group: Group
        + client: List<Client>
        --
        + handle(command: GroupCommand): GroupEvent
    }

    GroupHandler .up.> GroupCommand
    GroupHandler .up.> GroupEvent


    interface GroupHandlerService {
        + delete(groupID: String)
        + join(groupID: String, clientID: String)
        + leave(groupID: String, clientID: String)
        + connect(groupID: String, clientID: String)
        + disconnect(groupID: String, clientID: String)
        + send(groupID: String, clientID: String, message: String)
    }

    GroupHandlerService .up.> "creates" GroupHandler

    class GroupHandlerServiceImpl implements GroupHandlerService 
}

package realtime {
        
        interface Route <<value object>> {
            + version
            + path
        }

        interface RealTimeService <<service>> <<port>> {
            + connect(clientID: String, groupID: String)
        }

        

        RealTimeService *-left-> "1..n" Route
        RealTimeService *-up-> "1" GroupHandlerServiceImpl
}

package amqp {
    interface MessageHandler {
        + handle(type:MessageType, message: ByteStream)
    }

    interface ConnectionProvider{
        + connect()
        + disconnect()
    }

    interface MessageConsumer <<service>> <<in port>> {
        + consume(handler: MessageHandler)
    }

    MessageConsumer *-left-> ConnectionProvider
    MessageConsumer *-down-> MessageHandler
    MessageConsumer *-up-> "1" GroupHandlerServiceImpl
}   
@enduml
```

### Interaction between Entities

Finally, we present the interaction between the main components of the chat service. The following diagram shows the sequence of main events that occours inside the chat service.

```plantuml
@startuml chat-service-structure-behavior
autonumber 1.0.0
autoactivate on

queue "Message Broker" as MB
participant "Client" as C
participant "WebSocket Server" as WS
boundary "External Event Port" as EP
control "Group Handler" as GH
control "Group Actor" as GA
control "Client Actor" as CA

activate GH
activate EP

== Group Creation ==
MB -> EP: new group event
EP -> GH: create a new group
deactivate EP
GH -> GA **: spawn group entity
activate GA
deactivate GH

== New user join Group ==
autonumber inc B
MB -> EP: user join group event
EP -> GA: send user info to specific group
deactivate GA
GA -> CA **: spawn user entity
activate CA

== Client connection to the server ==
autonumber inc A
C -> WS: connect
WS -> GA: ask for user actor reference
alt user not found
    GA --> WS: return error
    WS --> C: return error
else user found
    GA -> GA: broadcast user connection event
    GA --> WS: return user actor reference
    WS --> C: return the URL used by client to connect to the server
end

== Send Message to group ==
autonumber inc A
C -> WS: send message to group
WS -> GA: send message
deactivate GA
GA -> GA: broadcast message to all users in the group
deactivate GA

== User leave group ==
autonumber inc A
C -> WS: disconnect
WS -> GA: send disconnection event
GA -> GA: remove user from the group
GA -> CA: destroy user entity
deactivate CA
destroy CA
deactivate GA
GA -> GA: broadcast user disconnection event
deactivate GA
@enduml
```