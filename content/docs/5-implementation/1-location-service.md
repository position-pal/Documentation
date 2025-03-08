---
weight: 501
title: "Location Service implementation details"
description: ""
draft: false
toc: true
---

This chapter provides an overview of the implementation details of the **Location Service**.

## User Tracking and Real-time Management

The most important and critical feature of the Location Service is the **tracking** of the user's location and real-time management of their  state considering the high volume of data that needs to be processed in real-time.
Moreover, the service is in charge of the user monitoring during the SOS and Routing modes, which require to take real-time actions to ensure the user's safety.

For what concern the technology stack, the real-time location and user state updates are managed through the **WebSocket** protocol, which allows bidirectional communication between the client and the service.
While this is a common choice for real-time applications and it is well supported by the majority of the programming languages and frameworks, it is worth mentioning that the WebSocket protocol brings with it some challenges in terms of scalability of the service, which is a fundamental requirement for the system.

One another important aspect to consider is that this service is intrinsically **stateful**: it needs to keep track of the user's location and state and take actions based on the history of the past updates and the current state.
This is a challenge in a distributed system, where the state is usually kept in memory and is not shared between the different instances of the service.

To address these challenges we moved on two levels: the first was to design and implement the service with a **fully event-driven** approach right from the core of the service itself, the domain, where the concept of "event reaction" was reified; the second on the technological level, where a distributed actor framework based on **Akka Cluster** was chosen, thanks to its capabilities to manage and allocate in a location-transparent way the actors across the cluster nodes, allowing to scale the service horizontally and to ensure the fault-tolerance of the system.

For these reasons the Location Service is implemented in **Scala**.

### Event reactions

The core of the Location Service is built around the concept of **event reactions**, which are the actions that the service takes in response to the events that are received from the clients or from the other services.

Thanks to the Scala superpowers, the event reactions are implemented as ADTs on a convenient DSL that allows to define and compose them as a pipeline in a functional way:

```scala

```

### Akka Cluster to the rescue

![Akka actors](/images/ls-actors.svg)

![Akka Cluster Sharding](/images/ls-sharding.svg)
