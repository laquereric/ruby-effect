Feature: Basic Effect Operations
  As a developer using ruby-effect
  I want to create and compose effects
  So that I can build robust functional programs

  Scenario: Creating a successful effect
    Given I create an effect that succeeds with value 42
    When I run the effect synchronously
    Then the result should be 42

  Scenario: Creating a failed effect
    Given I create an effect that fails with error "Something went wrong"
    When I attempt to run the effect synchronously
    Then it should raise an error

  Scenario: Mapping over an effect
    Given I create an effect that succeeds with value 5
    When I map the effect with a function that doubles the value
    And I run the effect synchronously
    Then the result should be 10

  Scenario: Chaining effects with flat_map
    Given I create an effect that succeeds with value 3
    When I flat_map the effect with a function that returns an effect of the value times 3
    And I run the effect synchronously
    Then the result should be 9

  Scenario: Error recovery with catch_all
    Given I create an effect that fails with error "error"
    When I catch all errors and recover with value "recovered"
    And I run the effect synchronously
    Then the result should be "recovered"

