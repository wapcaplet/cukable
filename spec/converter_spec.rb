require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Cukable::Converter do
  before(:each) do
    @converter = Cukable::Converter.new
  end

  context "#wikify" do
    it "strips underscores" do
      @converter.wikify("name_with_underscore").should == "NameWithUnderscore"
    end

    it "strips spaces" do
      @converter.wikify("name with spaces").should == "NameWithSpaces"
    end

    it "strips periods" do
      @converter.wikify("name.with.periods").should == "NameWithPeriods"
    end
  end


  context "#wikify_path" do
    it "appends Dir to directories" do
      @converter.wikify_path("features/basic/some.feature").should == "FeaturesDir/BasicDir/SomeFeature"
    end
  end


  context "#sanitize" do
    it "escapes CamelCase words with string-literal markup" do
      @converter.sanitize("Has a CamelCase word").should == "Has a !-CamelCase-! word"
    end
  end


  context "#wikify_feature" do
    it "adds table markup" do
      feature = [
        'Feature: User account',
        '  Scenario: Login',
        '    When I am on the login page',
        '    And I fill in "Username" with "Eric"',
        '    And I fill in "Password" with "foobar"',
      ]
      wiki = [
        '| Table: Cuke |',
        '| Feature: User account |',
        '| Scenario: Login |',
        '| When I am on the login page |',
        '| And I fill in "Username" with "Eric" |',
        '| And I fill in "Password" with "foobar" |',
      ].join("\n")
      @converter.wikify_feature(feature).strip.should == wiki
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
      wiki = [
        'As a user with an account',
        'I want to login to the website',
        '',
        '| Table: Cuke |',
        '| Feature: User account |',
        '| Scenario: Login |',
        '| When I am on the login page |',
      ].join("\n")
      @converter.wikify_feature(feature).strip.should == wiki
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
      wiki = [
        '| Table: Cuke |',
        '| Feature: User account |',
        '| Background: |',
        '| Given a user exists: |',
        '| | Username | Password |',
        '| | Eric     | foobar   |',
        '| | Ken      | barfoo   |',
        '| Scenario: Login |',
        '| When I am on the login page |',
      ].join("\n")
      @converter.wikify_feature(feature).strip.should == wiki
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
      wiki = [
        '| Table: Cuke |',
        '| Feature: Scenario outlines |',
        '| Scenario: Different pages |',
        '| When I am on the <page> page |',
        '| Then I should see "<text>" |',
        '| Examples: |',
        '| | page   | text        |',
        '| | home   | Relax       |',
        '| | office | Get to work |',
      ].join("\n")
      @converter.wikify_feature(feature).strip.should == wiki
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
      wiki = [
        '| Table: Cuke |',
        '| Feature: Strings |',
        '| Scenario: Multi-line string |',
        '| Given a multi-line string: |',
        '| """ |',
        '| Hello world |',
        '| Goodbye world |',
        '| """ |',
      ].join("\n")
      @converter.wikify_feature(feature).strip.should == wiki
    end
  end

end


