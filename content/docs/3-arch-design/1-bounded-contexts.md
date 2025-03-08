---
weight: 301
title: "Bounded Contexts"
description: ""
toc: true
---

Following the event storming session, the subsequent bounded contexts have been identified:

- **Users Management**: it is responsible for managing the users' lifecycle, from registration to deletion and the management of their profile information along with the authentication and authorization.
- **Groups Management**: it is responsible for managing the groups' lifecycle, from creation to deletion, and the management of the group's members.
- **Location Tracking**: it is responsible for managing the location tracking of the users, including the sharing of the location with groups' members, the reception of location updates, thw sending of SOS alerts and the management of their paths.
- **Notifications**: it is responsible for managing the notifications, including the push notifications to the users' devices.
- **Chat**: it is responsible for managing the chat between the users and the groups' members.

In the following sections, we will provide a detailed view of each bounded context, including its _Ubiquitous Language_ and the _Events_ guiding the interactions between the different contexts.
These can be categorized as _Driving Events_ and _Driven Events_: the former are the events triggered by the user's actions and that drives an application use case, while the latter are the events that are triggered by the system as a reaction to a use case or a system state change.

## Users Management

### Ubiquitous Language

### Events

## Groups Management

### Ubiquitous Language

### Events

## Location Tracking

### Ubiquitous Language

| Concept  | Description | Synonyms |
| -------- | ----------- | -------- |
| **Location** | A specific point on a geographical plane, represented by coordinates that indicates where something / someone is located. | Position |
| **Address**  | A human-readable description of a location, usually including the street name, the city, the country, and the postal code along with the related location. | |
| **Route**    | A set of positions that can be interpolated forming a path between two geographical positions. | Path |
| **Tracking** | Represent the user route information at a certain point in time. | |
| **State**    | State of a user at a certain time, the values that it could assume are: online, offline, SOS, Routing, Warning. | |
| **Session**  | An aggregation of the user's tracking information, the state and last location of a user in a certain period of time. | |

### Events

| Event Type | Event Name | Description |
| ---------- | ---------- | ----------- |
| *Driving event* | **SampledLocation** | The event sent from the client application to update the user's location. |
| *Driving event* | **RoutingStarted** | The event sent from the client application to start the user's route tracking towards a destination. |
| *Driving event* | **RoutingStopped** | The event sent from the client application to stop the user's route tracking. |
| *Driving event* | **SOSAlertTriggered** | The event sent from the client application to trigger an SOS alert, carrying the user's location. |
| *Driving event* | **SOSAlertStopped** | The event sent from the client application to stop the SOS alert. |
| *Driven event* | **UserUpdate** | The event sent from the Location Service to notify the client application about the user's state or location update. |

## Notifications

### Ubiquitous Language

| Concept  | Description | Synonyms |
| -------- | ----------- | -------- |
| **Push notification** | A real-time message sent to a user's device to inform about a relevant event. | |
| **Notification message** | The actual content of the push notification that is displayed to the user. | |
| **Registration token** | A unique token associated with a user's device for sending push notifications. |

### Events

| Event Type | Event Name | Description |
| ---------- | ---------- | ----------- |
| 

## Chat

### Ubiquitous Language

### Events



![Context Map](/images/context-map.svg)
