Feature: Slim JSON Formatter

  Background:
    Given a standard Cucumber project directory structure


  Scenario: Passing step
    Given a file named "features/passing.feature" with:
      """
      Feature: Passing
        Scenario: Passing
          Given a step passes
      """
    When I run cucumber on "features/passing.feature"
    Then "slim_results/features/passing.feature.json" should contain JSON:
      """
        [
          ["report:Feature: Passing"],
          ["report:Scenario: Passing"],
          ["pass:Given a step passes"]
        ]
      """


  Scenario: Failing step
    Given a file named "features/failing.feature" with:
      """
      Feature: Failing
        Scenario: Failing
          Given a step fails
      """
    When I run cucumber on "features/failing.feature"
    Then "slim_results/features/failing.feature.json" should contain JSON:
      """
        [
          ["report:Feature: Failing"],
          ["report:Scenario: Failing"],
          ["fail:Given a step fails"]
        ]
      """


  Scenario: Undefined step
    Given a file named "features/undefined.feature" with:
      """
      Feature: Undefined
        Scenario: Undefined
          Given a step is undefined
      """
    When I run cucumber on "features/undefined.feature"
    Then "slim_results/features/undefined.feature.json" should contain JSON:
      """
        [
          ["report:Feature: Undefined"],
          ["report:Scenario: Undefined"],
          ["error:Given a step is undefined"]
        ]
      """


  Scenario: Skipped step
    Given a file named "features/skipped.feature" with:
      """
      Feature: Skipped
        Scenario: Skipped
          When a step fails
          Then a step is skipped
      """
    When I run cucumber on "features/skipped.feature"
    Then "slim_results/features/skipped.feature.json" should contain JSON:
      """
        [
          ["report:Feature: Skipped"],
          ["report:Scenario: Skipped"],
          ["fail:When a step fails"],
          ["ignore:Then a step is skipped"]
        ]
      """


  Scenario: Passing table
    Given a file named "features/passing_table.feature" with:
      """
      Feature: Passing table
        Scenario: Passing table
          When I have a table:
            | OK | OK | OK |
            | OK | OK | OK |
      """
    When I run cucumber on "features/passing_table.feature"
    Then "slim_results/features/passing_table.feature.json" should contain JSON:
      """
        [
          ["report:Feature: Passing table"],
          ["report:Scenario: Passing table"],
          ["pass:When I have a table:"],
          ["report: ", "pass:OK", "pass:OK", "pass:OK"],
          ["report: ", "pass:OK", "pass:OK", "pass:OK"]
        ]
      """


  Scenario: Failing table
    Given a file named "features/failing_table.feature" with:
      """
      Feature: Failing table
        Scenario: Failing table
          When I have a table:
            | OK | OK   | OK |
            | OK | FAIL | OK |
      """
    When I run cucumber on "features/failing_table.feature"
    Then "slim_results/features/failing_table.feature.json" should contain JSON:
      # FIXME: The table rows should probably not be marked 'pass' here!
      """
        [
          ["report:Feature: Failing table"],
          ["report:Scenario: Failing table"],
          ["fail:When I have a table:"],
          ["report: ", "pass:OK", "pass:OK", "pass:OK"],
          ["report: ", "pass:OK", "pass:FAIL", "pass:OK"]
        ]
      """


  Scenario: Scenario Outline
    Given a file named "features/scenario_outline.feature" with:
      """
      Feature: Failing table
        Scenario Outline: Outline
          Given a step <result>

          Examples:
            | result |
            | passes |
            | fails |
      """
    When I run cucumber on "features/scenario_outline.feature"
    Then "slim_results/features/scenario_outline.feature.json" should contain JSON:
      """
        [
          ["report:Feature: Failing table"],
          ["report:Scenario Outline: Outline"],
          ["ignore:Given a step &lt;result&gt;"],
          ["report:Examples: "],
          ["report: ", "pass:result"],
          ["report: ", "pass:passes"],
          ["fail:", "fail:fails"]
        ]
      """

