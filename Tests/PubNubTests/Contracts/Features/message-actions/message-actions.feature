@featureSet=messageActions
Feature: Message Actions
  As a PubNub user
  I want to add, fetch and remove message actions
  So I can add features to my application like read receipts or reactions

  @contract=successfulAddMessageAction @beta
  Scenario: Adding a message action
    Given the demo keyset
    When I add a message action
    Then I receive successful response

  @contract=failedAddMessageAction @beta
  Scenario: Failing to add a message action
    Given the demo keyset
    When I add a message action
    Then I receive error response

  @contract=fetchMessageActions @beta
  Scenario: Fetching message actions with pagination
    Given the demo keyset
    When I fetch message actions
    Then I receive successful response
    And the response contains pagination info

  @contract=successfulDeleteMessageAction @beta
  Scenario: Deleting a message action
    Given the demo keyset
    When I delete a message action
    Then I receive successful response

  @contract=failedDeleteMessageAction @beta
  Scenario: Failing to delete a message action
    Given the demo keyset
    When I delete a message action
    Then I receive error response