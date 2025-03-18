---
weight: 501
title: "User and Group Service implementation details"
description: ""
draft: false
toc: true
---

This chapter provides an overview of the implementation details of the **User and Group Service**.

## High level overview

The User and Group Service is responsible for managing the users and groups of the system. It is a core service that is used by other services to manage the users and groups of the system.

The User and Group Service is composed of the following parts:

- **User Management Component**: This is responsible for managing the users of the system. It provides APIs for creating, updating, deleting, and retrieving user information.

- **Group Management Component**: This is responsible for managing the groups of the system. It provides APIs for creating, updating, deleting, and retrieving group information.

- **Membership Management Component**: This is responsible for managing the relationship between users and groups. It provides APIs for adding users to groups, removing users from groups, and retrieving the users of a group.

## User Service

### User Authentication and Identity Management

The core responsibility of the User Service is handling **user authentication and identity management**, which forms the foundation of the entire PositionPal platform. This service must maintain robust and secure user profiles, manage user authentication flows, and provide user data to other services in a consistent and reliable manner.

The critical challenge is balancing security with performance while maintaining a clear separation of concerns in a microservice architecture. User data must be protected, yet accessible to authorized services across the platform.

### Clean Architecture Implementation

For the User Service implementation, we adopted a **Clean Architecture** approach with clearly separated layers. This architectural choice provides significant benefits for a service responsible for sensitive user data:

```plaintext
user-service/
├── domain/         # Core business entities and rules
├── application/    # Use cases and service interfaces
├── storage/        # Database and persistence implementations
├── presentation/   # Protocol definitions
├── grpc/           # gRPC service implementations
├── rabbitmq/       # Message broker integration
└── entrypoint/     # Application bootstrap
```

Each layer has a specific responsibility and communicates only with upper layers, with dependencies pointing inward toward the domain layer. This approach allows us to isolate the core business logic from implementation details.

The domain layer contains pure business entities and rules, uncontaminated by external frameworks or technologies. For example, the `User` entity contains only the essential properties and validation rules:

```kotlin

data class User(
    val userData: UserData,
    val password: String,
)

data class UserData(
    val id: String,
    val name: String,
    val surname: String,
    val email: String,
)
```

The application layer defines service interfaces and use cases without implementation details. For instance, the `UserService` interface specifies what the service can do without dictating how:

```kotlin
interface UserService {
    suspend fun createUser(user: User): User
    suspend fun getUser(id: UserID): User?
    suspend fun updateUser(id: UserID, firstName: String, lastName: String): User?
    suspend fun deleteUser(id: UserID): Boolean
    suspend fun getUserByEmail(email: Email): User?
}
```

This clean separation facilitates testing and allows different implementations without affecting the core domain logic.

## Group Service

An interesting aspect of the User Service implementation is the management of user groups. We applied **Domain-Driven Design** principles to model this complex relationship:

```kotlin
data class Group(
    val id: String,
    val name: String,
    val members: List<UserData>,
    val createdBy: UserData,
)
```
The `Membership` entity encapsulates all the business rules regarding group membership.

```kotlin
data class Membership(
    val userId: String,
    val groupId: String,
)
```

### Group Operations and Membership Management
Here's the interface that defines what our Group Service can do:

```kotlin
interface GroupService {
    fun createGroup(group: Group): Group
    fun getGroup(groupId: String): Group?
    fun updateGroup(groupId: String, group: Group): Group?
    fun deleteGroup(groupId: String): Boolean
    fun addMember(groupId: String, userData: UserData): Group?
    fun removeMember(groupId: String, userData: UserData): Group?
    fun findAllGroupsOfUser(email: String): List<Group>
    fun findAllGroupsByUserId(id: String): List<Group>
}
```

## Authentication Implementation with JWT

The User Service implements JWT-based authentication, which is crucial for a microservice architecture where multiple services need to verify user identity without direct database access.

The service uses a combination of password hashing (with BCrypt) for secure storage and JWT tokens for stateless authentication:

```kotlin
interface AuthService {
    fun authenticate(email: String, password: String): String?
    fun authorize(token: String): Boolean
    fun getEmailFromToken(token: String): String?
}
```
```kotlin
class AuthServiceImpl(
    private val authRepository: AuthRepository,
    private val secret: Secret,
    private val issuer: Issuer,
    private val audience: Audience,
    private val expirationTime: Int = EXPIRATION_TIME,
) : AuthService {
  override fun authenticate(email: String, password: String): String? {
    ...
    return JWT.create()
            .withIssuer(issuer.value)
            .withAudience(audience.value)
            .withClaim("email", email)
            .withExpiresAt(Date(System.currentTimeMillis() + expirationTime))
            .sign(algorithm)
  }
}
```


This implementation follows the **Strategy Pattern** where different authentication methods could be plugged in, though currently JWT is the primary method. The service is designed to easily support additional authentication strategies if needed.

```kotlin
private val algorithm = Algorithm.HMAC256(secret.value)
```


## Inter-Service Communication with gRPC

A significant challenge in implementing the User Service was defining how other services would interact with user data. We chose **gRPC** for synchronous service-to-service communication for several reasons:

1. **Type safety**: Protocol buffers provide strict contract definitions;
2. **Performance**: gRPC offers better performance than REST/JSON;
3. **Automatic code generation**: Simplifies development by reducing repetitive code and maintaining consistency across services.

The service interfaces are defined using Protocol Buffers:

```protobuf
service UserService {
  rpc CreateUser (CreateUserRequest) returns (CreateUserResponse);
  rpc GetUser (GetUserRequest) returns (GetUserResponse);
  rpc UpdateUser (UpdateUserRequest) returns (UpdateUserResponse);
  rpc DeleteUser (DeleteUserRequest) returns (DeleteUserResponse);
  rpc GetUserByEmail (GetUserByEmailRequest) returns (GetUserByEmailResponse);
}

service AuthService {
  rpc Login (LoginRequest) returns (LoginResponse);
  rpc ValidateToken (ValidateTokenRequest) returns (ValidateTokenResponse);
}
```

The gRPC service adapters then translate between these protocol messages and domain objects, following the **Adapter Pattern**:

```kotlin
class GrpcUserServiceAdapter(private val userService: UserService) : UserServiceCoroutineImplBase() {
    override suspend fun createUser(request: CreateUserRequest): CreateUserResponse {
        try {
            val createdUser = userService.createUser(mapFromGrpcUser(request.user))
            
            return CreateUserResponse.newBuilder()
                .setUser(mapToGrpcUser(createdUser).userData)
                .setStatus(createStatus(StatusCode.OK, 
                                        "User created successfully"))
                .build()
        } catch (e: Exception) {
            return CreateUserResponse.newBuilder()
                .setStatus(createStatus(StatusCode.INTERNAL_ERROR, e.message))
                .build()
        }
    }
    
    // Additional methods...
}
```

This adapter implementation allows us to keep the service interface stable while the internal implementation can evolve independently. The mapping functions handle the translation between domain models and protocol buffer messages, ensuring a clean separation of concerns.

## Event-Driven Communication with RabbitMQ

For asynchronous communication scenarios, such as notifying other services when users are created or updated, we implemented an event-driven approach using **RabbitMQ** with the **Observer Pattern**.

The User Service publishes domain events when user-related actions occur, such as member join group or group creation. Other services can subscribe to these events and update their local projections accordingly.

The message adapter uses the **Strategy Pattern** for serialization, allowing different serialization methods (currently Avro) to be used.

### Group Event Publication System

One of the most interesting aspects of our implementation is how we've embraced event-driven architecture—but specifically focused on group operations.

In our system, we publish events exclusively for group-related operations through RabbitMQ. Here's what that looks like:

```kotlin
enum class EventType {
    GROUP_CREATED,
    GROUP_UPDATED,
    GROUP_DELETED,
    MEMBER_ADDED,
    MEMBER_REMOVED
}
```

Each event type corresponds to a significant domain event within our Group Service. When a group is created, members are added or removed, or a group is deleted, we publish an event to notify other services that might need to react to these changes.


## Data Persistence with Repository Pattern

The User Service uses the **Repository Pattern** to abstract database operations, making it possible to change the underlying database without affecting the business logic:

```kotlin
interface UserRepository {
    fun save(user: User): User
    fun findById(userId: String): User?
    fun update(user: User): User?
    fun deleteById(userId: String): Boolean
    fun findAll(): List<User>
    fun findByEmail(email: String): User?
}
```

We use **Ktorm**, a lightweight ORM, to interact with PostgreSQL:

```kotlin
object Users : BaseTable<User>("users") {
    val id = varchar("id").primaryKey()
    val name = varchar("name")
    val surname = varchar("surname")
    val email = varchar("email")
    val password = varchar("password")

    override fun doCreateEntity(row: QueryRowSet, withReferences: Boolean) = User(
        userData = UserData(
            id = row[id].orEmpty(),
            name = row[name].orEmpty(),
            surname = row[surname].orEmpty(),
            email = row[email].orEmpty(),
        ),
        password = row[password].orEmpty(),
    )
}
```
