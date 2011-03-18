require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Cukable::Conversion do

  context "#feature_to_fitnesse" do
    it "adds table markup" do
      feature = [
        'Feature: User account',
        '  Scenario: Login',
        '    When I am on the login page',
        '    And I fill in "Username" with "Eric"',
        '    And I fill in "Password" with "foobar"',
      ]
      fitnesse = [
        '!| Table: Cuke |',
        '| Feature: User account |',
        '| Scenario: Login |',
        '| When I am on the login page |',
        '| And I fill in "Username" with "Eric" |',
        '| And I fill in "Password" with "foobar" |',
      ]
      feature_to_fitnesse(feature).should == fitnesse
    end

    it "includes unparsed text" do
      feature = [
        'Feature: User account',
        '',
        '  As a user with an account',
        '  I want to login to the website',
        '',
        '  Scenario: Login',
        '    When I am on the login page',
      ]
      fitnesse = [
        'As a user with an account',
        'I want to login to the website',
        '',
        '!| Table: Cuke |',
        '| Feature: User account |',
        '| Scenario: Login |',
        '| When I am on the login page |',
      ]
      feature_to_fitnesse(feature).should == fitnesse
    end

    it "correctly marks up table rows" do
      feature = [
        'Feature: User account',
        '',
        '  Background:',
        '    Given a user exists:',
        '      | Username | Password |',
        '      | Eric     | foobar   |',
        '      | Ken      | barfoo   |',
        '',
        '  Scenario: Login',
        '    When I am on the login page',
      ]
      fitnesse = [
        '!| Table: Cuke |',
        '| Feature: User account |',
        '| Background: |',
        '| Given a user exists: |',
        '| | Username | Password |',
        '| | Eric     | foobar   |',
        '| | Ken      | barfoo   |',
        '| Scenario: Login |',
        '| When I am on the login page |',
      ]
      feature_to_fitnesse(feature).should == fitnesse
    end

    it "correctly marks up scenario outlines with examples" do
      feature = [
        'Feature: Scenario outlines',
        '',
        '  Scenario: Different pages',
        '    When I am on the <page> page',
        '    Then I should see "<text>"',
        '',
        '    Examples:',
        '      | page   | text        |',
        '      | home   | Relax       |',
        '      | office | Get to work |',
      ]
      fitnesse = [
        '!| Table: Cuke |',
        '| Feature: Scenario outlines |',
        '| Scenario: Different pages |',
        '| When I am on the <page> page |',
        '| Then I should see "<text>" |',
        '| Examples: |',
        '| | page   | text        |',
        '| | home   | Relax       |',
        '| | office | Get to work |',
      ]
      feature_to_fitnesse(feature).should == fitnesse
    end

    it "correctly includes multi-line strings" do
      feature = [
        'Feature: Strings',
        '',
        '  Scenario: Multi-line string',
        '    Given a multi-line string:',
        '      """',
        '      Hello world',
        '      Goodbye world',
        '      """',
      ]
      fitnesse = [
        '!| Table: Cuke |',
        '| Feature: Strings |',
        '| Scenario: Multi-line string |',
        '| Given a multi-line string: |',
        '| """ |',
        '| Hello world |',
        '| Goodbye world |',
        '| """ |',
      ]
      feature_to_fitnesse(feature).should == fitnesse
    end

    it "outputs @tags on separate lines" do
      feature = [
        '@tag_a @tag_b',
        'Feature: Tags',
        '',
        '  @tag_c @tag_d @tag_e',
        '  Scenario: Tags',
        '    Given a scenario',
      ]
      fitnesse = [
        '!| Table: Cuke |',
        '| @tag_a |',
        '| @tag_b |',
        '| Feature: Tags |',
        '| @tag_c |',
        '| @tag_d |',
        '| @tag_e |',
        '| Scenario: Tags |',
        '| Given a scenario |',
      ]
      feature_to_fitnesse(feature).should == fitnesse
    end
  end


  context "#fitnesse_to_features" do
    it "returns one table for each feature" do
      fitnesse = [
        '!| Table: Cuke |',
        '| Feature: First |',
        '| Scenario: Scenario 1A |',
        '| Given a scenario |',
        '| Scenario: Scenario 1B |',
        '| Given a scenario |',
        '',
        '!| Table: Cuke |',
        '| Feature: Second |',
        '| Scenario: Scenario 2A |',
        '| Given a scenario |',
        '| Scenario: Scenario 2B |',
        '| Given a scenario |',
      ]
      features = [
        [
          ['Feature: First'],
          ['Scenario: Scenario 1A'],
          ['Given a scenario'],
          ['Scenario: Scenario 1B'],
          ['Given a scenario'],
        ],
        [
          ['Feature: Second'],
          ['Scenario: Scenario 2A'],
          ['Given a scenario'],
          ['Scenario: Scenario 2B'],
          ['Given a scenario'],
        ],
      ]
      fitnesse_to_features(fitnesse).should == features
    end

    it "correctly interprets tables" do
      fitnesse = [
        '!| Table: Cuke |',
        '| Feature: Tables |',
        '| Scenario: Table rows |',
        '| Given a table: |',
        '| | First | Last |',
        '| | Eric  | Pierce |',
        '| | Ken   | Brazier |',
      ]
      features = [
        [
          ['Feature: Tables'],
          ['Scenario: Table rows'],
          ['Given a table:'],
          ['', 'First', 'Last'],
          ['', 'Eric', 'Pierce'],
          ['', 'Ken', 'Brazier'],
        ],
      ]
      fitnesse_to_features(fitnesse).should == features
    end


    it "correctly escapes brackets in Scenario Outlines" do
      fitnesse = [
        '!| Table: Cuke |',
        '| Feature: Scenario Outlines |',
        '| Scenario Outline: With tables |',
        '| Given a user: |',
        '| | First | Last |',
        '| | <first> | <last> |',
        '| Examples: |',
        '| | first | last |',
        '| | Eric  | Pierce |',
        '| | Ken   | Brazier |',
      ]
      features = [
        [
          ['Feature: Scenario Outlines'],
          ['Scenario Outline: With tables'],
          ['Given a user:'],
          ['', 'First', 'Last'],
          ['', '<first>','<last>'],
          ['Examples:'],
          ['', 'first', 'last'],
          ['', 'Eric', 'Pierce'],
          ['', 'Ken', 'Brazier'],
        ],
      ]
      fitnesse_to_features(fitnesse).should == features
    end


    it "ignores non-table lines" do
      fitnesse = [
        'This text should be ignored',
        '!| Table: Cuke |',
        '| Feature: Extra text |',
        '| Scenario: Ignore extra text|',
        '| Given a scenario |',
        'This line should also be ignored',
        'And this one too',
      ]
      features = [
        [
          ['Feature: Extra text'],
          ['Scenario: Ignore extra text'],
          ['Given a scenario'],
        ],
      ]
      fitnesse_to_features(fitnesse).should == features
    end

    it "returns an empty list if no Cuke tables are present" do
      fitnesse = [
        'This wiki page has no Cuke tables',
        'So there are no tables to parse',
        '| there is | this table |',
        '| but it is not | a Cuke table |',
        '| so it will also | be ignored |',
      ]
      features = []
      fitnesse_to_features(fitnesse).should == features
    end
  end

end


