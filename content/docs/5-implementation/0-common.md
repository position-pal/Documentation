---
weight: 500
title: "Implementation details for common services"
description: ""
draft: false
mermaid: true
toc: true
---

## Message Broker and RPC technologies

Why RabbitMQ?
Why gRPC?

**
tecnologie
tipologia
**
TODO - GIOVA

## Gateway

The gateway is the entry point of the system and is the only service that is exposed to the outside world.
Their main responsibilities and features are:

- **routing each request to the correct service after having authenticated and authorized the user**: it is important that only authenticated users can access the services and that they can only access the functionalities they are allowed to use. For example, a user can only access the functionalities of the group they belong to.
- **protocol translation**: for _synchronous_ remote procedure calls it is a best practice to use a ReST based API over the chosen gRPC protocol. This is because ReST APIs can be easily consumed by any client since they leverage standard HTTP methods and formats (like JSON), while gRPC APIs are more efficient but require specialized client libraries to handle Protobuf messages and HTTP/2 connections.
- since it is the entry-point of the system it can be a single point of failure and a bottleneck. To avoid this it is implemented like a **stateless service**, so it can be easily scaled horizontally to handle more requests and to be fault-tolerant.

```mermaid
flowchart RL
    client[Client Applications] -->|HTTP/REST| gateway[API Gateway]
    
    subgraph gateway_components[API Gateway Components]
        auth[Authentication]
        authoriz[Authorization]
        router[Request Router]
        translator[Protocol Translator]
        response_translator[Response Translator]
    end
    
    gateway --> auth
    auth --> authoriz
    authoriz --> router
    router --> translator
    
    translator -->|gRPC| serviceA[Location Service \n REST API]
    translator -->|wss| serviceB[Location Service \n Websocket API]
    translator -->|gRPC| serviceC[User Service \n gRPC API]
    translator -->|gRPC| serviceD[Chat Service \n gRPC API]
    translator -->|wss| serviceE[Chat Service \n Websocket API]
    translator -->|gRPC| serviceF[Notification Service \n gRPC API]

    
    serviceA .-> response_translator
    serviceB .-> response_translator
    serviceC .-> response_translator
    serviceD .-> response_translator
    serviceE .-> response_translator
    serviceF .-> response_translator
    
    response_translator -->|HTTP/REST| gateway
    gateway -->|HTTP/REST| client
    
    classDef gateway fill:#f96,stroke:#333,stroke-width:2px
    classDef client fill:#9d9,stroke:#333,stroke-width:1px
    classDef component fill:#fcf,stroke:#333,stroke-width:1px
    
    class gateway gateway
    class client client
    class auth,router,translator,authoriz,response_translator component
```

The API Gateway is implemented using **Express**, a lightweight and flexible _Node.js_ framework that simplifies the creation of web applications and APIs.

In this scenario, middleware plays a crucial role in the request-response lifecycle.
Middleware functions in Express are used to process incoming requests before they reach the core business logic and to handle responses before they are sent back to the client.
This modular approach helps organize the application logic into smaller, reusable components that can be stacked and composed as needed.

...

## Shared Kernel
**
tecnologie
codice
**
TODO - VALE
