---
weight: 204
title: "Event Storming"
description: ""
toc: true
---

To quickly and effectively extract the application's core functionality, we used **Event Storming** — a collaborative and visual modeling technique highly valued in agile and Domain-Driven Development.

Its strength lies in bringing together a diverse, multidisciplinary group of experts, including architects, product owners, UI/UX designers, and testers.
By working collaboratively, they identify key features and the processes that drive them, ensuring that knowledge is shared across teams rather than remaining siloed.
Additionally, this approach promotes a consistent, shared language (_ubiquitous language_) and helps uncover and resolve ambiguities or misunderstandings early in the project.

It starts with a problem or objective and, through the use of colored sticky notes and markers, proceeds to map the processes and interactions between the various entities involved so as to obtain an overview of the system and its interactions.
In more detail, the session begins with the identification of the **domain events**, that is, events related to the domain being explored that represent something interesting that has happened (past tense is used for this) and that may be useful for the system.
These are arranged in temporal sequence so as to create a timeline representing the flow of events occurring in the system.
This is followed by the identification of **commands**, i.e., actions that can be performed on the system by an actor, and **policies** by which the system reacts, going on to enrich the timeline by following the flow of events and actions.
Finally, **read models**, or whatever information the system needs to show the user, are highlighted.

**Glossary**:

| Sticky note color | Concept | Description |
| ----------------- | ------- | ----------- |
| 🟨 | **Actor** | Person/user/personas. The actor who triggered the event / command. |
| 🟧 | **Domain Event** | An event that is interesting for the business. |
| 🟦 | **Command** | An action that can be performed on the system. |
| 🟪 | **Policy** | Capture reactive logic to events. |
| 🟩 | **Read Model** | Information that the system needs to show the user. View details. |
| 🏻 | **System** | An internal or external component of the application. |
| 🟥 | **Hotspot** | An internal system constraint / some important note. |

<div style="width: 100%%; overflow-x: auto; white-space: nowrap;">
    <img 
        src="https://raw.githubusercontent.com/position-pal/Documentation/804a8f49452886b9cec67bff37d6ebd9a3fe2cf7/assets/images/event-storming.svg" 
        alt="Event Storming session" 
        style="display: inline-block; max-width: 5000px; max-height: 800px; width: auto; height: auto;"
    />
</div>

<br>

As a result of the event storming session, the main core entities and aggregates of the system were identified and from those the **bounded contexts** were derived:

![Bounded Contexts](/images/bounded-contexts.svg)
