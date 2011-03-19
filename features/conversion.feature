Feature: Conversion

  Background:
    Given a standard Cucumber project directory structure
    And a FitNesse wiki

  Scenario: Convert features to FitNesse
    Given a file named "features/passing.feature" with:
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

    Then I should have a Suite "FeatureS" containing:
      """
      These variables must be defined for rubyslim to work:
      !define TEST_SYSTEM {slim}
      !define TEST_RUNNER {rubyslim}
      !define COMMAND_PATTERN {rubyslim}

      Extra command-line arguments to pass to Cucumber:
      !define CUCUMBER_ARGS {}

      !contents -R9 -p -f -h
      """

    And I should have a Test "FeatureS/AaaAccelerator" containing:
      """
      """

    And I should have a Test "FeatureS/PassingFeature" containing:
      """
      !| Table: Cuke |
      | Feature: Passing |
      | Scenario: Passing |
      | Given a step passes |
      """

    And I should have a Test "FeatureS/FailingFeature" containing:
      """
      !| Table: Cuke |
      | Feature: Failing |
      | Scenario: Failing |
      | Given a step fails |
      """

