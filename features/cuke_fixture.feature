Feature: Cuke fixture

  Background:
    Given a standard Cucumber project directory structure

  Scenario: Do table
    Given a Cuke fixture
    When I do this table:
      | Feature: Table |
      | Scenario: Table |

