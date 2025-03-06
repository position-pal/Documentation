---
weight: 302
title: "Microservices"
description: ""
toc: true
---

## Microservices Decomposition

Following the decompose by subdomain strategy and considering the following guidelines we have identified the microservices that will compose the system:

- User Service: responsible for managing the user account data and the groups of the system; 
- Location Service: responsible for managing the location and the user tracking;
- Notification Service: responsible for managing the notifications;
- Chat Service: responsible for managing the chat messages.

It should be noted that in the User Service we have joined together the Users and Groups bounded context. This is because one can see the close interaction between these two domain entities in addition to respecting properties such as the "Common Closure Principle" (package components that change for the same reason are located into the same service.), ensuring data consistency and mitigate Network latency:

Moreover, to aggregate the functionalities of the different microservices, we have chosen to use the **API Gateway** pattern. This pattern is used to aggregate the functionalities of the architecture, providing a single entry point for the client applications.
The API Gateway is responsible for routing the requests to the appropriate service, aggregating the responses, and providing a unified interface to the client applications.
