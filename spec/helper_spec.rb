require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Cukable::Helper do

  context "#escape_camel_case" do
    it "escapes CamelCase words with string-literal markup" do
      escape_camel_case("Has a CamelCase word").should == "Has a !-CamelCase-! word"
    end
  end


  context "#wikify" do
    it "strips underscores" do
      wikify("name_with_underscore").should == "NameWithUnderscore"
    end

    it "strips spaces" do
      wikify("name with spaces").should == "NameWithSpaces"
    end

    it "strips periods" do
      wikify("name.with.periods").should == "NameWithPeriods"
    end
  end


  context "#wikify_path" do
    it "appends Dir to directories" do
      wikify_path("features/basic/some.feature").should == "FeaturesDir/BasicDir/SomeFeature"
    end
  end


  context "#clean_filename" do
    it "should convert path separators to underscores" do
      clean_filename('some/path/name', '', '').should == 'some_path_name'
    end

    it "should remove prefix and suffix" do
      clean_filename('abc/some/path/xyz', 'abc', 'xyz').should == 'some_path'
    end
  end


  context "#remove_cruft" do
    it "should remove anchor tags and keep the content" do
      string = 'Go to <a href="SomePage">this page</a>'
      expect = 'Go to this page'
      remove_cruft(string).should == expect
    end

    it "should remove [?] content" do
      string = 'See SomePage<a href="SomePage">[?]</a>'
      expect = 'See SomePage'
      remove_cruft(string).should == expect
    end
  end


  context "#table_digest" do
    it "should return the same digest for identical input" do
      table1 = [
        ["Name", "Quest"],
        ["Arthur", "Holy Grail"],
        ["Bevedere", "Holy Grail"],
      ]
      table2 = [
        ["Name", "Quest"],
        ["Arthur", "Holy Grail"],
        ["Bevedere", "Holy Grail"],
      ]
      table_digest(table1).should == table_digest(table2)
    end

    it "should return different digest for different input" do
      table1 = [
        ["Name", "Quest"],
        ["Arthur", "Holy Grail"],
        ["Bevedere", "Holy Grail"],
      ]
      table2 = [
        ["Name", "Quest"],
        ["Arthur", "Holy Grail"],
        ["Lancelot", "Holy Grail"],
      ]
      table_digest(table1).should_not == table_digest(table2)
    end
  end

end
