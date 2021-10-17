@featureSet=push
Feature: Push Notifications
  As a PubNub user
  I want to manage push notifications
  So I can communicate with my customers even when they are not using the application

  @contract=listingPushChannels @beta
  Scenario: Listing push channels for GCM gateway
    Given the demo keyset
    When I list GCM push channels
    Then I receive successful response

  @beta
  Scenario: Listing push channels for APNS2 without topic
    Given the demo keyset
    When I list APNS2 push channels
    Then I receive error response

  @contract=listingPushChannels @beta
  Scenario: Listing push channels for APNS2
    Given the demo keyset
    When I list APNS2 push channels with topic
    Then I receive successful response

  @contract=addingPushChannels @beta
  Scenario: Adding push channels for GCM
    Given the demo keyset
    When I add GCM push channels
    Then I receive successful response

  @contract=addingPushChannels @beta
  Scenario: Adding push channels for FCM
    Given the demo keyset
    When I add FCM push channels
    Then I receive successful response

  @beta
  Scenario: Adding push channels for APNS2 without topic
    Given the demo keyset
    When I add APNS2 push channels
    Then I receive error response

  @contract=addingPushChannels @beta
  Scenario: Adding push channels for APNS2
    Given the demo keyset
    When I add APNS2 push channels with topic
    Then I receive successful response

  @contract=removingPushChannels @beta
  Scenario: Removing push channels for GCM
    Given the demo keyset
    When I remove GCM push channels
    Then I receive successful response

  @beta
  Scenario: Removing push channels for APNS2 without topic
    Given the demo keyset
    When I remove APNS2 push channels
    Then I receive error response

  @contract=removingPushChannels @beta
  Scenario: Removing push channels for APNS2
    Given the demo keyset
    When I remove APNS2 push channels with topic
    Then I receive successful response

  @contract=removingDevice @beta
  Scenario: Removing device for GCM
    Given the demo keyset
    When I remove GCM device
    Then I receive successful response

  @beta
  Scenario: Removing device for APNS2 without topic
    Given the demo keyset
    When I remove APNS2 device
    Then I receive error response

  @contract=removingDevice @beta
  Scenario: Removing device for APNS2
    Given the demo keyset
    When I remove APNS2 device with topic
    Then I receive successful response
