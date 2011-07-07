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
    And a Suite "TestSuite" containing:
      """
      !contents
      """
    And a Test "TestSuite/HelloWorld" containing:
      """
      | Table: Cuke |
      | Feature: Hello |
      | Scenario: Hello |
      """
    And a Test "TestSuite/GoodbyeWorld" containing:
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


  @wip
  Scenario: Write features for multiple projects
    Given a Cuke fixture
    And a FitNesse wiki
    And a Suite "TestSuite" containing:
      """
      !define TEST_SYSTEM {slim}
      !define TEST_RUNNER {rubyslim}
      !define COMMAND_PATTERN {rubyslim}
      !contents
      """

    And a Suite "TestSuite/ProjectA" containing:
      """
      !define PROJECT_DIR {project_a}
      !contents
      """
    And a Test "TestSuite/ProjectA/HelloWorld" containing:
      """
      | Table: Cuke |
      | Feature: Hello |
      | Scenario: Hello |
      """

    And a Suite "TestSuite/ProjectB" containing:
      """
      !define PROJECT_DIR {project_b}
      !contents
      """
    And a Test "TestSuite/ProjectB/GoodbyeWorld" containing:
      """
      | Table: Cuke |
      | Feature: Goodbye |
      | Scenario: Goodbye |
      """

    When I write features for suite "TestSuite/ProjectA"


  Scenario: Accelerate suite
    Given a FitNesse wiki
    And a Cuke fixture
    And a Suite "FeatureS" containing:
      """
      !define TEST_SYSTEM {slim}
      !define TEST_RUNNER {rubyslim}
      !define COMMAND_PATTERN {rubyslim}
      !define CUCUMBER_ARGS {}
      """

    And a Test "FeatureS/AaaAccelerator" containing:
      """
      """

    And a Test "FeatureS/PassingFeature" containing:
      """
      !| Table: Cuke |
      | Feature: Passing |
      | Scenario: Passing |
      | Given a step passes |
      """

    And a Test "FeatureS/FailingFeature" containing:
      """
      !| Table: Cuke |
      | Feature: Failing |
      | Scenario: Failing |
      | Given a step fails |
      """

    When I run the accelerator for suite "FeatureS"

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


  @wip
  Scenario: Accelerate suite with skipped tags
    # FIXME: Fails when run with other scenarios. Lack of init/cleanup in self_test dir?
    Given a FitNesse wiki
    And a Cuke fixture

    And a Test "FeatureS/SkippedScenariosFeature" containing:
      """
      !| Table: Cuke |
      | Feature: Passing |
      | @skip |
      | Scenario: Skipped scenario |
      | Given a step passes |
      | Scenario: Passing |
      | Given a step passes |
      | @skip |
      | Scenario: Another skipped scenario |
      | Given a step passes |
      """

    And a Test "FeatureS/SkippedFeature" containing:
      """
      !| Table: Cuke |
      | @skip |
      | Feature: Skipped feature |
      | Scenario: Failing |
      | Given a step fails |
      """

    When I set CUCUMBER_ARGS to "--tags ~@skip"
    And I run the accelerator for suite "FeatureS"

    Then "slim_results/features/fitnesse/SkippedScenariosFeature_0.feature.json" should contain JSON:
      """
      [
        ["report:Feature: Passing"],
        ["report:Scenario: Passing"],
        ["error:Given a step passes"]
      ]
      """

    And "slim_results/features/fitnesse/SkippedFeature_0.feature.json" should not exist

