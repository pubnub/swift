@featureSet=history
Feature: History
  As a PubNub user
  I want to get message history
  So I can display past messages

  @contract=fetchMessageHistory @beta
  Scenario: Fetching message history
    Given the demo keyset
    When I fetch message history for single channel
    Then I receive successful response
    And the response contains pagination info

  @contract=fetchMessageHistoryMulti @beta
  Scenario: Fetching message history for multiple channels
    Given the demo keyset
    When I fetch message history for multiple channels
    Then I receive successful response

  @contract=fetchMessageHistoryActions @beta
  Scenario: Fetching message history with message actions
    Given the demo keyset
    When I fetch message history with message actions
    Then I receive successful response
