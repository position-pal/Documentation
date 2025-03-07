---
weight: 204
title: "Event Storming"
description: ""
toc: true
---

In order to extract the main functionality of the application as quickly and effectively as possible, **Event Storming**, a collaborative and visual modeling technique particularly used and valued in the agile and Domain-Driven development context, was used.

Its power comes from a heterogeneous, multidisciplinary group of experts, from architects to product owners, via UI/UX designers to testers, who, together, collaborate to extract key features and the processes that drive them, sharing this knowledge so that it is shared beyond the compartments of each team.
Moreover, this approach allows for uniformity in the language used (the _ubiquitous language_) and for raising and then resolving any ambiguities or misunderstandings that may arise early in the project.

It starts with a problem or objective and, through the use of colored stickynotes and markers, proceeds to map the processes and interactions between the various entities involved so as to obtain an overview of the system and its interactions.
In more detail, the session begins with the identification of the **domain events**, that is, events related to the domain being explored that represent something interesting that has happened (past tense is used for this) and that may be useful for the system.
These are arranged in temporal sequence so as to create a timeline representing the flow of events occurring in the system.
This is followed by the identification of **commands**, i.e., actions that can be performed on the system by an actor, and **policies** by which the system reacts, going on to enrich the timeline by following the flow of events and actions.
Finally, **read models**, or whatever information the system needs to show the user, are highlighted.

