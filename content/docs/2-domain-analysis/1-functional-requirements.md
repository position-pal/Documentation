---
weight: 201
title: "Functional Requirements"
description: ""
icon: "article"
toc: true
---

In this section are collected the functional requirements of the system.

## User Stories

### Users and groups

### Location tracking

<em>

1. As a logged user \
   I want to be able to start sharing my location with other groups' member \
   So that I'm able to be monitored

2. As a logged user who is sharing their position with a set of groups \
   I want to be able to stop sharing it with a group's members \
   So that I can go where I want without letting know those member

3. As a logged user \
   I want to be able to receive location updates from my groups' members who are sharing their location \
   So that I can view their live location on a map in real-time

4. As a logged user \
   I want to be able to get the last known location and state of my groups' member \
   So that I can see their last reported location and status when live sharing is unavailable

5. As a logged user \
   I want to be able to send an SOS alert comprising of my location to all members of all groups I'm participating despite the fact I'm or not sharing my location \
   So that if I am in a dangerous situation my friends are notified and knows where I am

6. As a logged user \
   I want to start sharing my location to all groups' members after the trigger of an SOS alert \
   So that my live location is automatically shared after an SOS alert to aid responders

7. As a logged user who is sharing their position \
   I want to be able to share a journey towards a location specifying the time by which I'll be there \
   So that my friends know where I'm going

8. As a logged user who is sharing a journey \
   I want to be able to trigger an SOS alert \
   So that if I am in a dangerous situation my friends are notified

9. As a logged user in SOS mode \
   I want to be able to stop the SOS \
   So that my friend are notified I'm not anymore in danger

10. As a logged user who is sharing a journey \
    I want to be able to stop it prematurely \
    So that my friend knows a change in my plan have occurred

11. As a logged user \
    I want to be able to see the entire path taken by my groups' members who are sharing a journey or triggered an SOS alert \
    So that I know where they have been during the dangerous situation 

12. As a logged user \
    I want to be able to receive a notification when one of my groups' member start a journey or trigger an SOS alert \
    So that I'm aware of it

13. As a logged user \
    I want to be able to receive a notification if one my groups' member who triggered an SOS alert goes offline or deactivate it \
    So that I can take appropriate action

14. As a logged user \
    I want to be able to receive a notification if one my groups' member who started a journey stops moving, doesn't arrive on time, goes offline, reaches their destination or deactivate it \
    So that I can take appropriate action

</em>

### Chat

## Acceptance tests

Following BDD principles, starting from the above user stories, a set of acceptance test specifications have been defined.
These specifications are written in Gherkin using [Cucumber](https://cucumber.io), providing a structured and readable format that facilitates communication between stakeholders.
They serve as end-to-end tests, ensuring that the system meets the defined requirements while aligning with end users' expectations and needs. 
By leveraging this approach, the tests remain clear, maintainable, and closely tied to business objectives.

### Location tracking

```gherkin
Feature: Users real-time tracking

  Background:
    Given I am a logged user
    * with a registered device
    And I am in a group with other users

  Scenario: User can track other users in their groups in real-time
    When I access my group tracking information
    Then I should see the real-time location of online group members
    And the last known location of offline group members

  Scenario: User is able to share their location with other group members
    When I start sharing my location
    Then my last known location should be updated
    And my state should be `Active`

  Scenario: User can stop sharing their location with other group members
    When I stop sharing my location with that group
    Then the group's members should not see my location anymore
    * my state should be updated to `Inactive`
    But my last known location should still be available
```

```gherkin
Feature: Users routes tracking

  Background:
    Given I am a logged user
    * with a registered device
    And I am in a group with other users

  Scenario: User can activate a route that is recorded and visible to group members
    When I activate the routing mode indicating a destination and the ETA
    Then my state is updated to `Routing`
    * my group's members receive a notification indicating I've started a routing
    And my group's members can see the route I've been taken since activating routing mode

  Scenario Outline: A route can be stopped
    Given I'm in routing mode
    When <event>
    Then the routing is stopped
    * the route discarded
    * my state is updated to `Active`
    And my group's members receive a notification indicating <event>

    Examples:
      | event |
      | I have arrived at the destination |
      | I have stopped the routing        |

  Scenario Outline: Route notifications
    Given I'm in routing mode
    When <event>
    Then my group's members receive a notification indicating <event>

    Examples:  
      | event |
      | I have gone offline                                |
      | I have not arrived by the estimated time           |
      | I have been stuck in the same position for a while |
```
