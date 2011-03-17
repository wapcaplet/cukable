Feature: Cuke fixture

  Background:
    Given a standard Cucumber project directory structure

  Scenario: Do table
    Given a Cuke fixture
    When I do this table:
      | Feature: Table |
      | Scenario: Table |

    Then "slim_results/features/fitnesse/fitnesse_test.feature.json" should contain JSON:
      """
      [
        ["report:Feature: Table"],
        ["report:Scenario: Table"]
      ]
      """

  Scenario: Wiki
    Given a Cuke fixture
    And a FitNesse wiki
    And a FitNesse suite "TestSuite" with:
      """
      !contents
      """
    And a FitNesse test "TestSuite/HelloWorld" with:
      """
      | Table: Cuke |
      | Feature: Hello |
      | Scenario: Hello |
      """
    And a FitNesse test "TestSuite/GoodbyeWorld" with:
      """
      | Table: Cuke |
      | Feature: Goodbye |
      | Scenario: Goodbye |
      """
    When I write features for suite "TestSuite"

    Then "features/fitnesse/HelloWorld_0.feature" should contain:
      """
      Feature: Hello
      Scenario: Hello
      """
    And "features/fitnesse/GoodbyeWorld_0.feature" should contain:
      """
      Feature: Goodbye
      Scenario: Goodbye
      """

