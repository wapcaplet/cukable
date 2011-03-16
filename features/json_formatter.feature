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
    Then "slim/features/passing.feature.json" should contain JSON:
      """
        [
          ["report:Feature: Passing <span class=\"source_file\"></span>"],
          ["report:Scenario: Passing <span class=\"source_file\">features/passing.feature:2</span>"],
          ["pass:Given a step passes <span class=\"source_file\">features/step_definitions/simple_steps.rb:1</span>"]
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
    Then "slim/features/failing.feature.json" should contain JSON:
      """
        [
          ["report:Feature: Failing <span class=\"source_file\"></span>"],
          ["report:Scenario: Failing <span class=\"source_file\">features/failing.feature:2</span>"],
          ["fail:Given a step fails <span class=\"source_file\">features/step_definitions/simple_steps.rb:4</span><br/>expected: false\n     got: true (using ==)<br/>./features/step_definitions/simple_steps.rb:5:in `/^a step fails$/'<br/>features/failing.feature:3:in `Given a step fails'"]
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
    Then "slim/features/undefined.feature.json" should contain JSON:
      """
        [
          ["report:Feature: Undefined <span class=\"source_file\"></span>"],
          ["report:Scenario: Undefined <span class=\"source_file\">features/undefined.feature:2</span>"],
          ["error:Given a step is undefined <span class=\"source_file\">features/undefined.feature:3</span><br/>(Undefined Step)"]
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
    Then "slim/features/skipped.feature.json" should contain JSON:
      """
        [
          ["report:Feature: Skipped <span class=\"source_file\"></span>"],
          ["report:Scenario: Skipped <span class=\"source_file\">features/skipped.feature:2</span>"],
          ["fail:When a step fails <span class=\"source_file\">features/step_definitions/simple_steps.rb:4</span><br/>expected: false\n     got: true (using ==)<br/>./features/step_definitions/simple_steps.rb:5:in `/^a step fails$/'<br/>features/skipped.feature:3:in `When a step fails'"],
          ["ignore:Then a step is skipped <span class=\"source_file\">features/step_definitions/simple_steps.rb:7</span>"]
        ]
      """


