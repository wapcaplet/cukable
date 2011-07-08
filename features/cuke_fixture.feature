Feature: Cuke fixture

  Background:
    Given a standard Cucumber project directory structure

  Scenario: Do table
    Given a default Cuke fixture
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
    Given a default Cuke fixture
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


  Scenario: Write features for multiple projects
    Given a FitNesse wiki
    And a Suite "TestSuite" containing:
      """
      !define TEST_SYSTEM {slim}
      !define TEST_RUNNER {rubyslim}
      !define COMMAND_PATTERN {rubyslim}
      !contents
      """

    And a Suite "TestSuite/ProjectA" containing:
      """
      !contents
      """
    And a Test "TestSuite/ProjectA/HelloWorld" containing:
      """
      | Table: Cuke |
      | Feature: Hello |
      | Scenario: Hello |
      """
    And a Cuke fixture with arguments:
      | project_dir | project_a |

    When I write features for suite "TestSuite/ProjectA"
    Then "project_a/features/fitnesse/HelloWorld_0.feature" should contain:
      """
      Feature: Hello
      Scenario: Hello
      """

    Given a Suite "TestSuite/ProjectB" containing:
      """
      !contents
      """
    And a Test "TestSuite/ProjectB/GoodbyeWorld" containing:
      """
      | Table: Cuke |
      | Feature: Goodbye |
      | Scenario: Goodbye |
      """
    And a Cuke fixture with arguments:
      | project_dir | project_b |

    When I write features for suite "TestSuite/ProjectB"
    Then "project_b/features/fitnesse/GoodbyeWorld_0.feature" should contain:
      """
      Feature: Goodbye
      Scenario: Goodbye
      """


  Scenario: Accelerate suite
    Given a FitNesse wiki
    And a default Cuke fixture
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
  @focus
  Scenario: Accelerate suite with skipped tags
    # FIXME: Fails when run with other scenarios. Lack of init/cleanup in self_test dir?
    Given a FitNesse wiki
    And a Cuke fixture with arguments:
      | cucumber_args | --tags ~@skip |

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

