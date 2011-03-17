@focus
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

    Then "FitNesseRoot/FeatureS/PassingFeature/content.txt" should contain:
      """
      | Table: Cuke |
      | Feature: Passing |
      | Scenario: Passing |
      | Given a step passes |
      """

    And "FitNesseRoot/FeatureS/PassingFeature/properties.xml" should contain:
      """
      <?xml version="1.0"?>
      <properties>
        <Edit>true</Edit>
        <Files>true</Files>
        <Properties>true</Properties>
        <RecentChanges>true</RecentChanges>
        <Refactor>true</Refactor>
        <Search>true</Search>
        <Test/>
        <Versions>true</Versions>
        <WhereUsed>true</WhereUsed>
      </properties>
      """

    And "FitNesseRoot/FeatureS/FailingFeature/content.txt" should contain:
      """
      | Table: Cuke |
      | Feature: Failing |
      | Scenario: Failing |
      | Given a step fails |
      """

    And "FitNesseRoot/FeatureS/FailingFeature/properties.xml" should contain:
      """
      <?xml version="1.0"?>
      <properties>
        <Edit>true</Edit>
        <Files>true</Files>
        <Properties>true</Properties>
        <RecentChanges>true</RecentChanges>
        <Refactor>true</Refactor>
        <Search>true</Search>
        <Test/>
        <Versions>true</Versions>
        <WhereUsed>true</WhereUsed>
      </properties>
      """

    And "FitNesseRoot/FeatureS/content.txt" should contain:
      """
      !define TEST_SYSTEM {slim}
      !define TEST_RUNNER {rubyslim}
      !define COMMAND_PATTERN {rubyslim}

      !contents -R9 -p -f -h
      """

    And "FitNesseRoot/FeatureS/properties.xml" should contain:
      """
      <?xml version="1.0"?>
      <properties>
        <Edit>true</Edit>
        <Files>true</Files>
        <Properties>true</Properties>
        <RecentChanges>true</RecentChanges>
        <Refactor>true</Refactor>
        <Search>true</Search>
        <Suite/>
        <Versions>true</Versions>
        <WhereUsed>true</WhereUsed>
      </properties>
      """

