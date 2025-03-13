---
weight: 403
title: "User and Group Service design"
description: ""
draft: false
toc: false
---

In this section it is presented the abstract design of the **User and Group Service**.
As per best practices, the design is based on the **Domain-Driven Design** principles, and is presented in terms of the main three views: **structure**, **interaction**, and **behavior**.

## Abstract Design

### Structure

The main domain concepts and events are presented hereafter and reified in the following classes structure, following the DDD building blocks.

```plantuml 
@startuml user-group-service-structure
package domain {
  package user {
    interface User <<entity>> {
      + id: UserId
      + name: String
      + email: String
      + password: String
    }
    interface UserId <<value object>> {
      + value: UUID
    }
    User *-right-> "1" UserId
  }

  package group {
    interface Group <<entity>> {
      + id: GroupId
      + name: String
      + members: List<User>
    }
    interface GroupId <<value object>> {
      + value: UUID
    }
    Group *-right-> "1" GroupId
    Group --> "0..*" User
  }
}
@enduml
```

- **`User`**: The User entity represents an individual in the system. Each User is uniquely identified by a value object, _UserId_, ensuring consistency and traceability. The entity includes attributes such as name, email, and password, which can be updated while maintaining the same identity.

- **`Group`** The Group entity represents a collection of users. It is identified by a _GroupId_ value object and has attributes like a group name and a list of members (Users). The association (Group → 0..* User) signifies that a group can have zero or more users, enabling flexible management of group memberships.

- **`User-Group Context:`** Although not explicitly modeled as a value object in the diagram, the context in which events occur is defined by the association between a user and a group. This context is crucial for tracking state variations that might be specific to a group—allowing, for example, group-specific permissions or visibility settings.

- **`Domain Events:`** Domain events capture significant changes within the business context and play a key role in maintaining consistency and notifying other system components. All events implement the DomainEvent interface, ensuring a common structure (for instance, including a timestamp and references to the affected user and group). Key events include:

  - **`UserCreated:`**
Triggered when a new user is created. It contains the UserId, name, and email, enabling other components (such as notification services) to react accordingly.

  - **`GroupCreated:`**
Signals the creation of a new group, carrying the _GroupId_ and group name to initiate processes like automatic configuration or internal notifications.

  - **`UserAddedToGroup:`**
Captures the event of adding a user to a specific group by linking the _UserId_ and _GroupId_.

  - **`UserRemovedFromGroup:`**
Records the removal of a user from a group, including both _UserId_ and _GroupId_.

```plantuml
@startuml user-group-service-application
package application {
  package repository {
    interface UserRepository <<repository>> {
      + save(user: User): void
      + findById(id: UserId): User
      + delete(user: User): void

      + TODO ADD METHODS FOR UPDATING USER
    }
    interface GroupRepository <<repository>> {
      + save(group: Group): void
      + findById(id: GroupId): Group
      + delete(group: Group): void

      + TODO ADD METHODS FOR ADDING/REMOVING USERS
    }
  }
  
  package service {
    interface UserService <<service>> {
      + createUser(name: String, surname, email: String, password: String): User
      + updateUser(user: User): void
      + deleteUser(id: UserId): void

      + TODO ADD METHODS FOR UPDATING USER
    }
    interface GroupService <<service>> {
      + createGroup(name: String): Group
      + addUserToGroup(user: User, group: Group): void
      + removeUserFromGroup(user: User, group: Group): void

      + TODO ADD METHODS FOR ADDING/REMOVING USERS
    }
  }
}

package shared.kernel.domain.events {
    interface AddedMemberToGroup <<domain event>> {
        + groupId: GroupId
        + addedMember: User
    }
    interface GroupCreated <<domain event>> {
        + groupId: GroupId
        + createdBy: User
    }
    interface GroupDeleted <<domain event>> {
        + groupId: GroupId
    }
    interface RemovedMemberToGroup <<domain event>> {
        + groupId: GroupId
        + removedMember: User
    }
}

  application.service.UserService ..> application.repository.UserRepository : uses
  application.service.GroupService ..> application.repository.GroupRepository : uses
  application.service.GroupService ..> shared.kernel.domain.events.GroupDeleted : publishes
  application.service.GroupService ..> shared.kernel.domain.events.GroupCreated : publishes
  application.service.GroupService ..> shared.kernel.domain.events.AddedMemberToGroup : publishes
  application.service.GroupService ..> shared.kernel.domain.events.RemovedMemberToGroup : publishes

@enduml
```

- **`Repositories:`**

  - **`UserRepository:`** Abstracts the persistence operations for User entities by exposing methods such as save(user: User), findById(id: UserId): User, and delete(user: User).

  - **`GroupRepository:`** Similarly abstracts persistence for Group entities with equivalent operations.

- **`Services:`**

  - **`UserService:`** Contains business logic for creating, updating, and deleting users. It leverages the UserRepository for data operations and publishes a UserCreated event when a new user is created.

  - **`GroupService:`** Manages group-related operations such as creating groups, adding users to groups, and removing users from groups. It uses the GroupRepository for data access and publishes GroupCreated, UserAddedToGroup, and UserRemovedFromGroup events as necessary.

  // TODO CHECK EVENTS

### Interaction
The interaction between the main components of the system is described in the following sequence diagram.

- `User Registration:` A new user registers by sending their username, email, and password to the Auth Service. The service persists the new user in the User-Group Store, publishes a UserCreated event on the Event Bus, and returns the created user details.

- `User Login:` The user logs in by providing credentials. The Auth Service validates these against the User-Group Store and returns a UserSession (including a token).

- `User Modification:` The user modifies their own details (e.g., changing name, surname or password) by sending an update request to the Auth Service. The service updates the record, publishes a UserUpdated event, and returns the updated user information.

- `Group Creation:` The user creates a group through the Group Handler. The handler persists the new group (recording the creator’s UserID), publishes a GroupCreated event, and returns the group details.

- `Group Update:` The user updates the group’s name via the Group Handler. The updated details are persisted, a GroupUpdated event is published, and the updated group details are returned.

- `User Join Group:` The user joins a group by sending a join request to the Group Handler. The Group Handler adds the user to the group in the store, publishes a UserAddedToGroup event, and returns the updated group details.

- `Remove Member from Group:` The user (or possibly a group owner) removes a target member from the group by sending a removal request. The Group Handler updates the membership in the store, publishes a UserRemovedFromGroup event, and returns the updated group details.

- `User Logout:` The user logs out by sending a logout request to the Auth Service. The service invalidates the session in the store and returns a logout acknowledgment.

Please, note the diagram illustrates only the main success flow, leaving out the error handling and the edge cases.

```plantuml
@startuml user-group-service-full-behavior
autonumber 1.0.0

actor "User" as U
participant "Auth Service" as AS
participant "Group Handler" as GH
database "User-Group Store" as UGS
queue "Event Bus" as EB

activate EB

== User Registration ==
U -> AS: registerUser(username, email, password)
activate AS
AS -> UGS: persistUser(username, email, password)
activate UGS
UGS --> AS: UserDetails (UserID, username, email)
deactivate UGS
AS -> EB: publish(UserCreated event)
AS --> U: registrationSuccess(UserDetails)
deactivate AS

== User Login ==
autonumber inc B
U -> AS: login(username, password)
activate AS
AS -> UGS: validateCredentials(username, password)
activate UGS
UGS --> AS: UserSession (UserID, Token)
deactivate UGS
AS --> U: loginSuccess(UserSession)
deactivate AS

== User Modification ==
autonumber inc B
U -> AS: updateUser(UserID, newName, newSurname, newPassword)
activate AS
AS -> UGS: updateUser(UserID, newName, newSurname, newPassword)
activate UGS
UGS --> AS: UpdatedUserDetails
deactivate UGS
AS -> EB: publish(UserUpdated event)
AS --> U: userUpdated(UpdatedUserDetails)
deactivate AS

== Group Creation ==
autonumber inc A
U -> GH: createGroup(groupName)
activate GH
GH -> UGS: persistGroup(groupName, creator=UserID)
activate UGS
UGS --> GH: GroupDetails (GroupID, groupName)
deactivate UGS
GH -> EB: publish(GroupCreated event)
GH --> U: groupCreated(GroupDetails)
deactivate GH

== Group Update ==
autonumber inc B
U -> GH: updateGroup(GroupID, newGroupName)
activate GH
GH -> UGS: updateGroup(GroupID, newGroupName)
activate UGS
UGS --> GH: UpdatedGroupDetails
deactivate UGS
GH -> EB: publish(GroupUpdated event)
GH --> U: groupUpdated(UpdatedGroupDetails)
deactivate GH

== User Join Group ==
autonumber inc A
U -> GH: joinGroup(GroupID)
activate GH
GH -> UGS: addUserToGroup(UserID, GroupID)
activate UGS
UGS --> GH: UpdatedGroupDetails
deactivate UGS
GH -> EB: publish(UserAddedToGroup event)
GH --> U: joinedGroup(UpdatedGroupDetails)
deactivate GH

== Remove Member from Group ==
autonumber inc B
U -> GH: removeUserFromGroup(targetUserID, GroupID)
activate GH
GH -> UGS: removeUserFromGroup(targetUserID, GroupID)
activate UGS
UGS --> GH: UpdatedGroupDetails
deactivate UGS
GH -> EB: publish(UserRemovedFromGroup event)
GH --> U: memberRemoved(UpdatedGroupDetails)
deactivate GH

== User Logout ==
autonumber inc A
U -> AS: logout(UserSession)
activate AS
AS -> UGS: invalidateSession(UserSession)
activate UGS
UGS --> AS: logoutAck
deactivate UGS
AS --> U: logoutSuccess
deactivate AS

@enduml
```