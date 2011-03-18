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

  Scenario: Write features
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


  @focus
  Scenario: Accelerate suite
    Given a FitNesse wiki
    And a Cuke fixture
    And a file named "features/passing.feature" with:
      """
      Feature: Passing
        Scenario: Passing
          Given a step passes
      """
    And a file named "features/failing.feature" with:
      """
      Feature: Failing
        Scenario: Failing
          Given a step fails
      """
    When I convert features to FitNesse
    And I run the accelerator for suite "FeatureS"

    Then "slim_results/features/fitnesse/PassingFeature_0.feature.json" should contain JSON:
      """
      [
        ["report:Feature: Passing"],
        ["report:Scenario: Passing"],
        ["error:Given a step passes"]
      ]
      """

    And "slim_results/features/fitnesse/FailingFeature_0.feature.json" should contain JSON:
      """
      [
        ["report:Feature: Failing"],
        ["report:Scenario: Failing"],
        ["error:Given a step fails"]
      ]
      """

