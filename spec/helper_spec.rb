require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Cukable::Helper do

  context "#escape_camel_case" do
    it "escapes CamelCase words with string-literal markup" do
      escape_camel_case("Has a CamelCase word").should == "Has a !-CamelCase-! word"
    end
  end


  context "#wikify" do
    context "recognizes word separators and strips them out" do
      it "underscores" do
        wikify("name_with_underscores").should == "NameWithUnderscores"
      end

      it "hyphens" do
        wikify("name-with-hyphens").should == "NameWithHyphens"
      end

      it "spaces" do
        wikify("name with spaces").should == "NameWithSpaces"
      end

      it "periods" do
        wikify("name.with.periods").should == "NameWithPeriods"
      end
    end

    it "appends 'Wiki' to single-word inputs" do
      wikify("name").should == "NameWiki"
      wikify("quest").should == "QuestWiki"
    end

    it "leaves already-CamelCased inputs unchanged" do
      wikify("CamelCase").should == "CamelCase"
      wikify("WikiWord with suffix").should == "WikiWordWithSuffix"
      wikify("prefix before WikiWord").should == "PrefixBeforeWikiWord"
    end
  end


  context "#wikify_path" do
    it "turns each path component into a WikiWord" do
      wikify_path("hello_world").should == "HelloWorld"
      wikify_path("hello_world/readme.txt").should == "HelloWorld/ReadmeTxt"
    end

    it "appends 'Wiki' to single-word path components" do
      wikify_path("features/basic").should == "FeaturesWiki/BasicWiki"
      wikify_path("features/basic/some.feature").should == "FeaturesWiki/BasicWiki/SomeFeature"
    end
  end


  context "#clean_filename" do
    it "converts path separators to underscores" do
      clean_filename('some/path/name', '', '').should == 'some_path_name'
    end

    it "removes prefix and suffix" do
      clean_filename('abc/some/path/xyz', 'abc', 'xyz').should == 'some_path'
    end
  end


  context "#remove_cruft" do
    it "removes anchor tags and keep the content" do
      string = 'Go to <a href="SomePage">this page</a>'
      expect = 'Go to this page'
      remove_cruft(string).should == expect
    end

    it "removes [?] content" do
      string = 'See SomePage<a href="SomePage">[?]</a>'
      expect = 'See SomePage'
      remove_cruft(string).should == expect
    end
  end


  context "#table_digest" do
    it "returns the same digest for identical input" do
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

    it "returns different digests for different input" do
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
