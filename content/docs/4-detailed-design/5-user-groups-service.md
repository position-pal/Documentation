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


  interface Membership <<value object>>{
    + userId: UserId
    + groupId: GroupId
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

  Membership *-down-> "1" UserId
  Membership *-down-> "1" GroupId
}
@enduml
```

- **`User`**: The User entity represents an individual in the system. Each User is uniquely identified by a value object, _UserId_, ensuring consistency and traceability. The entity includes attributes such as name, email, and password, which can be updated while maintaining the same identity.

- **`Group`** The Group entity represents a collection of users. It is identified by a _GroupId_ value object and has attributes like a group name and a list of members (Users).

- **`Membership`** The Membership value object captures the relationship between a user and a group. It includes the _UserId_ and _GroupId_ value objects, establishing a many-to-many association between users and groups. This structure allows for efficient querying of group memberships and user-group relationships.


```plantuml
@startuml user-group-service-application
package application {
  package repository {
    interface UserRepository <<repository>> {
      + save(user: User): void
      + findById(id: UserId): User
      + update(user: User): User
      + deleteById(id: UserId): Boolean
      + findAll(): List<User>
      + findByEmail(email: String): User
    }
    interface GroupRepository <<repository>> {
      + save(group: Group): void
      + findById(id: GroupId): Group
      + update(group: Group): Group
      + deleteById(id: GroupId): Boolean
      + findAll(): List<Group>
      + addMember(groupId: GroupId, user: User): Group
      + removeMember(groupId: GroupId, user: User): Group
      + findGroupsByUserEmail(email: String): List<Group>
      + findGroupsByUserId(id: UserId): List<Group>
    }
    interface AuthRepository <<repository>> {
      + checkCredentials(email: String, password: String): Boolean
    }
  }
  
  package service {
    interface UserService <<service>> {
      + createUser(user: User): User
      + getUser(id: UserId): User
      + updateUser(user: User): User
      + deleteUser(id: UserId): Boolean
      + getUserByEmail(email: String): User
    }
    interface GroupService <<service>> {
      + createGroup(name: String): Group
      + getGroup(id: GroupId): Group
      + updateGroup(groupId: GroupId, group: Group): Group
      + deleteGroup(id: GroupId): Boolean
      + addMember(groupId: GroupId, user: User): Group
      + removeMember(groupId: GroupId, user: User): Group
      + findAllGroupsOfUser(email: String): List<Group>
      + findAllGroupsByUserId(id: UserId): List<Group>
    }
    interface AuthService <<service>> {
      + authenticate(username: String, password: String): String
      + authorize(token: String): Boolean
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

  application.service.UserService .up.> application.repository.UserRepository : uses
  application.service.GroupService .up.> application.repository.GroupRepository : uses
  application.service.AuthService .up.> application.repository.AuthRepository : uses
  application.service.GroupService .up.> shared.kernel.domain.events.GroupDeleted : publishes
  application.service.GroupService .up.> shared.kernel.domain.events.GroupCreated : publishes
  application.service.GroupService ..> shared.kernel.domain.events.AddedMemberToGroup : publishes
  application.service.GroupService ..> shared.kernel.domain.events.RemovedMemberToGroup : publishes

@enduml
```

- **`Repositories:`**

  - **`UserRepository:`** Abstracts the persistence operations for User entities by exposing methods such as save(user: User), findById(id: UserId): User, and delete(user: User).

  - **`GroupRepository:`** Similarly abstracts persistence for Group entities with equivalent operations.

  - **`AuthRepository:`** Provides methods for checking user credentials during authentication.

- **`Services:`**

  - **`UserService:`** Contains business logic for creating, updating, and deleting users. It leverages the UserRepository for data operations and publishes a UserCreated event when a new user is created.

  - **`GroupService:`** Manages group-related operations such as creating groups, adding users to groups, and removing users from groups. It uses the GroupRepository for data access and publishes GroupCreated, UserAddedToGroup, and UserRemovedFromGroup events as necessary.

  - **`AuthService:`** Handles user authentication and authorization. It verifies user credentials against the AuthRepository and generates JWT tokens for authenticated users.

### Interaction
The interaction between the main components of the system is described in the following sequence diagram.

- `User Registration:` A new user registers by sending their email, and password to the Auth Service. The service persists the new user in the User-Group Store, publishes a UserCreated event on the Event Bus, and returns the created user details.

- `User Login:` The user logs in by providing credentials. The Auth Service validates these against the User-Group Store and returns a UserSession (including a token).

- `User Modification:` The user modifies their own details (e.g., changing name, surname or password) by sending an update request to the Auth Service. The service updates the record, publishes a UserUpdated event, and returns the updated user information.

- `Group Creation:` The user creates a group through the Group Handler. The handler persists the new group (recording the creator’s UserID), publishes a GroupCreated event, and returns the group details.

- `Group Update:` The user updates the group name via the Group Handler. The updated details are persisted, a GroupUpdated event is published, and the updated group details are returned.

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
U -> AS: registerUser(email, password)
activate AS
AS -> UGS: persistUser(email, password)
activate UGS
UGS --> AS: UserDetails
deactivate UGS
AS -> EB: publish(UserCreated event)
AS --> U: registrationSuccess(UserDetails)
deactivate AS

== User Login ==
autonumber inc B
U -> AS: login(email, password)
activate AS
AS -> UGS: validateCredentials(email, password)
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