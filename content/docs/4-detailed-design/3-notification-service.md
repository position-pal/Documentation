---
weight: 405
title: "Notification Service design"
description: ""
draft: false
toc: false
---

In this section is presented the abstract design of the notification service.

As already presented, its main responsibility is to **send notifications** to the users, based on the events that occur in the system.

## Structure

The structure of the service is quite simple:

```plantuml
@startuml notification-service-structure
package shared.kernel.domain {
    package entities {
        interface User <<entity>>
        interface UserId <<value object>>
        interface GroupId <<value object>>
        User *-left-> "1" UserId
        interface NotificationMessage <<entity>> {
            + title: String
            + body: String
        }
    }
}

package application {

    package domain {

        interface Token <<value object>> {}

        interface UserToken <<entity>> {
            + userId: UserId
            + token: Token
        }
        UserToken *-left-> "1" Token
        UserToken *-up--> "1" UserId
    }

    interface GroupsRepository <<repository>> <<out port>> {
        + addMember(groupId: GroupId, userId: UserId): Result<Unit>
        + removeMember(groupId: GroupId, userId: UserId): Result<Unit>
        + getMembersOf(groupId: GroupId): Result<Set<UserId>>
        + getGroupsOf(userId: UserId): Result<Set<GroupId>
    }

    interface NotificationPublisher <<service>> <<out port>> {
        + send(notificationMessage: NotificationMessage): PublishingTargetStrategy
        + send(message: NotificationMessage: userIds: Set<UserId>)
    }
    NotificationPublisher *-up--> "1" NotificationMessage
    NotificationPublisher *-up--> "*" UserId

    interface PublishingTargetStrategy {
        + toAllMembersOf(groupId: GroupId)
        + toAllMembersSharingGroupWith(userId: UserId)
    }

    NotificationPublisher *--> "1" PublishingTargetStrategy

    abstract class BasicNotificationPublisher implements NotificationPublisher {
        + {abstract} send(message: NotificationMessage, userIds: Set<UserId>)
    }
    BasicNotificationPublisher *--> "1" GroupsRepository

    interface UsersTokensRepository <<repository>> <<out port>> {
        + save(userToken: UserToken): Result<Unit>
        + get(userId: UserId): Result<UserToken>
        + delete(userToken: UserToken): Result<Unit>
    }

    interface UsersTokensService <<service>> <<in port>> {
        + register(userId: UserId, token: Token): Result<UserToken>
        + invalidate(userId: UserId, token: Token): Result<Unit>
    }
    UsersTokensService *-up-> "1" UserId
    UsersTokensService *-up-> "1" GroupId

    UsersTokensRepository *-up-> "1" UserToken
    UsersTokensService *-up-> "1" UserToken

    class UsersTokensServiceImpl implements UsersTokensService
    UsersTokensServiceImpl *--> "1" UsersTokensRepository
}
@enduml
```

- `Token` is a value object that represents the token used to identify the device of a user.
- `UserToken` is an entity that represents the association between a user and a token.
- `UsersTokensService` is the service that allows registering and invalidating tokens for users.
- `UsersTokensRepository` is the repository that stores the associations between users and tokens.
- `NotificationPublisher` is the service that sends notifications to users.
  - `PublishingTargetStrategy` is the strategy used to determine the target of the notification. Two stategies exists: one to send to all members of a group (corresponding to the `GroupWisePushNotification` command) and another to send to all members sharing a group with a user (corresponding to the `CoMembersPushNotification` command).
- `GroupsRepository` is the repository that allows storing and retrieving the members of the groups. This is called by the message broker adapter on every events whose topic is related to groups state changes.

## Interaction

The main flow scenario is depicted in the following sequence diagram:

```plantuml
@startumll notification-service-interaction
autonumber

== User device token registration ==

actor "Group Member" as User
control PushNotificationService as PNS
participant UsersTokensService as UTS
database UsersTokensRepository as UTR
database GroupsRepository as GR
participant NotificationPublisher as NP
queue "Message Broker" as Broker

activate User
activate Broker

User -> PNS: Request token for my device
activate PNS
PNS -> User: <token>
deactivate PNS
User -> UTS: Register <uid, token>
activate UTS
UTS -> UTR: Save <uid, token>
activate UTR
UTS <<-- UTR: Ok
User <<-- UTS: Ok
deactivate UTR

== A notification command is received ==

Broker -->> NP: Send <notification> to all \n members of group <gid>
activate NP
NP --> GR: Get members of <gid>
activate GR
GR -->> NP: List of members

loop#gold forach member
    NP -> UTR: Get <member> token
    activate UTR
    UTR -->> NP: Token
    deactivate UTR
    NP -> PNS: Send <notification> to device <token>
    activate PNS
    PNS -->> NP: Ok
    PNS -->> User: Notification
    deactivate PNS
end

@enduml
```
