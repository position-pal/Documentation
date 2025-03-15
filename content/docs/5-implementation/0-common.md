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

The gateway is implemented in Javascript leveraging the Express framework.

```mermaid
flowchart TD
    client[Client Applications] -->|HTTP/REST| gateway[API Gateway]
    
    subgraph gateway_components[API Gateway Components]
        auth[Authentication & Authorization]
        router[Request Router]
        translator[Protocol Translator]
    end
    
    gateway --> auth
    auth --> router
    router --> translator
    translator --> ratelimit
    ratelimit --> logging
    
    logging -->|REST| serviceA[Microservice A REST API]
    logging -->|gRPC| serviceB[Microservice B RPC API]
    logging -->|REST| serviceC[Microservice C REST API]
    logging -->|gRPC| serviceD[Microservice D gRPC API]
    
    classDef gateway fill:#f96,stroke:#333,stroke-width:2px
    classDef service fill:#69b,stroke:#333,stroke-width:1px
    classDef client fill:#9d9,stroke:#333,stroke-width:1px
    classDef component fill:#fcf,stroke:#333,stroke-width:1px
    
    class gateway gateway
    class serviceA,serviceB,serviceC,serviceD service
    class client client
    class auth,router,translator,ratelimit,logging component
    
    %% Key characteristics
    note1[Stateless - No Database]
    note2[Protocol Translation REST <-> gRPC]
    note3[Authentication & Authorization]
```

**
tecnologie
middleware
express
cucumber
**
TODO - LUCA

## Shared Kernel
**
tecnologie
codice
**
TODO - VALE
