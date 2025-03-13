---
weight: 501
title: "User and Group Service implementation details"
description: ""
draft: false
toc: true
---

This chapter provides an overview of the implementation details of the **User and Group Service**.

## High level overview and modules structure

The User and Group Service is responsible for managing the users and groups of the system. It is a core service that is used by other services to manage the users and groups of the system. 

The User and Group Service is composed of the following modules:

- **User Management Module**: This module is responsible for managing the users of the system. It provides APIs for creating, updating, deleting, and retrieving user information.

- **Group Management Module**: This module is responsible for managing the groups of the system. It provides APIs for creating, updating, deleting, and retrieving group information.

- **Membership Management Module**: This module is responsible for managing the relationship between users and groups. It provides APIs for adding users to groups, removing users from groups, and retrieving the users of a group.