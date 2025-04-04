---
weight: 301
title: "Bounded Contexts"
description: ""
toc: true
mermaid: true
---

Following the event storming session, the subsequent bounded contexts have been identified:

- **Users Management**: it is responsible for managing the users' lifecycle, from registration to deletion and the management of their profile information along with the authentication and authorization.
- **Groups Management**: it is responsible for managing the group lifecycle, from creation to deletion, and the management of the group members.
- **Location Tracking**: it is responsible for managing the location tracking of the users, including the sharing of the location with group members, the reception of location updates, the sending of SOS alerts and the management of their paths.
- **Notifications**: it is responsible for managing the notifications, including the push notifications to the users' devices.
- **Chat**: it is responsible for managing the chat between the users and the group members.

In the following sections, we will provide a detailed view of each bounded context, including its **_Ubiquitous Language_**, the **_Commands_** and the **_Events_** guiding the interactions between the different contexts.
These can be categorized as **_Driving_** or **_Driven Events_**: the former are the events triggered by the user's actions and that drives an application use case, while the latter are the events that are triggered by the system as a reaction to a use case or a system state change.
Moreover we distinguish between _Commands_ and _Events_ to highlight the difference between a request to perform an action (_Command_) and the notification of something meaningful that has happened (_Event_).

## Users Management

### Ubiquitous Language

{{< table "table-striped " >}}

| Concept  | Description | Synonyms |
| -------- | ----------- | -------- |
| **User** | An individual who has registered and can access the system with a unique identity. | Member, Account Holder |
| **Profile** | Collection of personal information associated with a user. | User Profile |
| **Authentication** | The process of verifying a user's identity, typically through credentials like email/password. | Login, Sign-in |
| **Authorization** | Determination of what actions a user is permitted to perform within the system. | Permissions, Access Control |
| **Credentials** | Information used to verify a user's identity, such as email/password combinations or tokens. | Login Details |
| **Session** | A period of time during which a user is actively authenticated in the system. | User Session |
| **Registration** | The process by which a new user creates an account in the system. | Sign-up, Account Creation |

{{< /table >}}

### Events

{{< table "table-striped" >}}

| 🏷️ Event Type | Event Name | Description |
| ---------- | ---------- | ----------- |
| **📥 Driven event** | **UserCreated** | Triggered when a new user successfully completes the registration process. |
| **📥 Driven event** | **ProfileUpdated** | Triggered when a user modifies their profile information. |
| **📥 Driven event** | **UserDeleted** | Triggered when the user account is permanently deleted from the system. |

{{< /table >}}

### Commands

{{< table "table-striped" >}}

| Command | Description |
| ------- | ----------- |
| **CreateUser** | Register a new user in the system. |
| **UpdateUser** | Modify the existing user's profile information. |
| **AuthenticateUser** | Verify the user's credentials to allow access to the system. |
| **DeleteUser** | Permanently remove a user from the system. |

{{< /table >}}

## Groups Management

### Ubiquitous Language

{{< table "table-striped " >}}

| Concept  | Description | Synonyms |
| -------- | ----------- | -------- |
| **Group** | A collection of users who are connected for shared tracking and communication purposes. | Circle, Team |
| **Group Member** | A user who belongs to a group. | Participant |

{{< /table >}}

### Events

{{< table "table-striped" >}}

| 🏷️ Event Type | Event Name | Description |
| ---------- | ---------- | ----------- |
| **📥 Driven event** | **GroupCreated** | Triggered when a user creates a new group. |
| **📥 Driven event** | **GroupMemberAdded** | Triggered when a user is added to an existing group. |
| **📥 Driven event** | **GroupMemberRemoved** | Triggered when a member is removed from a group. |

{{< /table >}}

### Commands

{{< table "table-striped " >}}

| Command | Description |
| ------- | ----------- |
| **CreateGroup** | Create a new group in the system. |
| **AddMemberToGroup** | Add a new member to an existing group. |
| **RemoveMemberToGroup** | Remove a member from an existing group. |

{{< /table >}}

## Location Tracking

### Ubiquitous Language

{{< table "table-striped " >}}

| Concept  | Description | Synonyms |
| -------- | ----------- | -------- |
| **Location** | A specific point on a geographical plane, represented by coordinates that indicates where something / someone is located. | Position |
| **Address**  | A human-readable description of a location, usually including the street name, the city, the country, and the postal code along with the related location. | |
| **ETA** | Estimated Time of Arrival, the time at which a user is expected to reach a certain destination. | |
| **Route**    | A set of positions that can be interpolated forming a path between two geographical positions. | Path |
| **Tracking** | Represent the user route information at a certain point in time. | |
| **State**    | State of a user at a certain time, the values that it could assume are: online, offline, SOS, Routing, Warning. | |
| **Session**  | An aggregation of the user's tracking information, the state and last location of a user in a certain period of time. | |

{{< /table >}}

### Events

{{< table "table-striped" >}}

| 🏷️ Event Type | Event Name | Description |
| ---------- | ---------- | ----------- |
| **🚀 Driving event** | **SampledLocation** | The event sent from the client application to update the user's location. |
| **🚀 Driving event** | **RoutingStarted** | The event sent from the client application to start the user's route tracking towards a destination. |
| **🚀 Driving event** | **RoutingStopped** | The event sent from the client application to stop the user's route tracking. |
| **🚀 Driving event** | **SOSAlertTriggered** | The event sent from the client application to trigger an SOS alert, carrying the user's location. |
| **📥 Driven event** | **SOSAlertStopped** | The event sent from the client application to stop the SOS alert. |
| **📥 Driven event** | **UserUpdate** | The event sent from the Location Service to notify the client application about the user's state or location update. |

{{< /table >}}

## Notifications

### Ubiquitous Language

{{< table "table-striped" >}}

| Concept  | Description | Synonyms |
| -------- | ----------- | -------- |
| **Push notification** | A real-time message sent to a user's device to inform about a relevant event. | |
| **Notification message** | The actual content of the push notification that is displayed to the user. | |
| **Registration token** | A unique token associated with a user's device for sending push notifications. | Token, Device Token |

{{< /table >}}

### Commands

{{< table "table-striped" >}}

| Command | Description |
| ------- | ----------- |
| **Group Wise Push Notification** | A push notification to be sent to all the members of a group. |
| **Co Members Push Notification** | A push notification to be sent to all users sharing at least one group with a specific user. |

{{< /table >}}

## Chat

### Ubiquitous Language

{{< table "table-striped " >}}

| Concept  | Description | Synonyms |
| -------- | ----------- | -------- |
| **Client** | An individual that connect to a chat group | User, Group Member |
| **Group** | A set of Clients that chat between each other| Chat Room|
| **Message** | A text message that is sent from a client in a group. | |

{{< /table >}}

### Events

{{< table "table-striped" >}}

| 🏷️ Event Type | Event Name | Description |
| ---------- | ---------- | ----------- |
| **🚀 Driving event** | **ClientJoinedToGroup** | The event triggered when a client join a group in order to start chat. |
| **🚀 Driving event** | **ClientLeavedFromGroup** | The event triggered when a client leaves a group. |
| **🚀 Driving event** | **ClientConnected** | The event sent from the client application when user logs in and is able to receive messages. |
| **🚀 Driving event** | **ClientDisconnected** | The event sent from the client application when user logs out and is no longer reachable. |
| **📥 Driven event** | **Message** | The event sent from the client application when a new message is received in a group. |

{{< /table >}}

### Commands

{{< table "table-striped" >}}

| Command | Description |
| ------- | ----------- |
| **DeleteGroup** | Delete a chat group. |
| **ClientJoinsGroup** | Add a new client in a group. |
| **ClientLeavesGroup** | Remove a client from a group. |
| **ClientConnects** | Make a client become available for receiving new messages. |
| **ClientDisconnects** | Make a client unavailable for receiving new messages. |
| **SendMessage** | Send a message in a group. |

{{< /table >}}

## Bounded Context Integration

The boundary of each bounded context delineates the scope of the context: models in different bounded context can be evolved and implemented independently, but they need to be integrated to provide a coherent service to the users.

DDD provides a set of patterns for defining relationship and integrations between bounded contexts to be reified in the so-called **Context Map**, a visual representation of the system bounded contexts and the relationships between them.

The following diagram shows the context map of the PositionPal system:

![Context Map](/images/context-map.svg)

The **shared kernel** collects the shared entities and domain logic that are in common between the bounded contexts.
As per best practices, the overlapping module will be limited as much as possible to avoid coupling between the contexts and exposing only the part of the model that, otherwise, would be duplicated in all the contexts.

The **conformist** pattern applies to users and groups management context: the downstream context (Group Management) conform to the upstream context (Users Management) model to simplify the integration and avoid the complexity of translation between bounded contexts. Although this approach may constrain the downstream team's design flexibility, it significantly simplifies integration.
Since the upstream context (Users Management) has more influence in this relationship, conforming to its model facilitates clearer communication and reduces integration overhead.
