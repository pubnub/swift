@featureSet=subscribe
Feature: Subscribe Loop
  Subscribe long polling with message published

  @contract=simpleSubscribe @beta
  Scenario: subscribe and recieve a published message
    Given the demo keyset
    When I subscribe
    When I publish a message
    Then I receive the message in my subscribe response
