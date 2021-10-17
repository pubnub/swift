@featureSet=time
Feature: Time
  As a PubNub user
  I want to get current PubNub time
  So I can verify connectivity to the PubNub network

  @contract=successfulTime @beta
  Scenario: Getting PubNub time
    When I request current time
    Then I receive successful response