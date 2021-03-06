require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Cukable::Helper do

  context "#literalize" do
    it "escapes CamelCase words" do
      literalize("E2E").should == "!-E2E-!"
      literalize("BoB").should == "!-BoB-!"
      literalize("CamelCase").should == "!-CamelCase-!"
      literalize("Has a CamelCase word").should == "Has a !-CamelCase-! word"
      literalize("CamelCase at start").should == "!-CamelCase-! at start"
      literalize("ending with CamelCase").should == "ending with !-CamelCase-!"
    end

    it "escapes email addresses" do
      literalize("epierce@foo-bar.com").should == "!-epierce@foo-bar.com-!"
      literalize("Email epierce@foo-bar.com").should == "Email !-epierce@foo-bar.com-!"
      literalize("epierce@foo-bar.com is my email").should == "!-epierce@foo-bar.com-! is my email"
      literalize("Email epierce@foo-bar.com again").should == "Email !-epierce@foo-bar.com-! again"
    end

    it "escapes URLs" do
      literalize("http://my.site/").should == "!-http://my.site/-!"
      literalize("Go to http://my.site/").should == "Go to !-http://my.site/-!"
      literalize("http://my.site/ is my site").should == "!-http://my.site/-! is my site"
      literalize("My site http://my.site/ is cool").should == "My site !-http://my.site/-! is cool"
    end
  end # literalize


  context "#wikify" do
    context "recognizes word separators and strips them out" do
      it "underscores" do
        wikify("one_underscore").should == "OneUnderscore"
        wikify("two_under_scores").should == "TwoUnderScores"
        wikify("_underscore_at_start").should == "UnderscoreAtStart"
        wikify("underscore_at_end_").should == "UnderscoreAtEnd"
      end

      it "hyphens" do
        wikify("one-hyphen").should == "OneHyphen"
        wikify("with-two-hyphens").should == "WithTwoHyphens"
        wikify("-hyphen-at-start").should == "HyphenAtStart"
        wikify("hyphen-at-end-").should == "HyphenAtEnd"
      end

      it "spaces" do
        wikify("one space").should == "OneSpace"
        wikify("with two spaces").should == "WithTwoSpaces"
        wikify(" space at start").should == "SpaceAtStart"
        wikify("space at end ").should == "SpaceAtEnd"
      end

      it "periods" do
        wikify("one.period").should == "OnePeriod"
        wikify("with.two.periods").should == "WithTwoPeriods"
        wikify(".period.at.start").should == "PeriodAtStart"
        wikify("period.at.end.").should == "PeriodAtEnd"
      end

      it "mixed periods, hyphens, underscores, and spaces" do
        wikify("period.with space").should == "PeriodWithSpace"
        wikify("period.with-hyphen").should == "PeriodWithHyphen"
        wikify("period.with-underscore").should == "PeriodWithUnderscore"
        wikify("under_with space").should == "UnderWithSpace"
        wikify("under_with.period").should == "UnderWithPeriod"
        wikify("under_with-hyphen").should == "UnderWithHyphen"
        wikify("with_under.period-hyphen space").should == "WithUnderPeriodHyphenSpace"
      end
    end

    it "capitalizes the last letter of single-word inputs" do
      wikify("name").should == "NamE"
      wikify("quest").should == "QuesT"
    end

    it "leaves already-CamelCased inputs unchanged" do
      wikify("CamelCase").should == "CamelCase"
      wikify("WikiWord with suffix").should == "WikiWordWithSuffix"
      wikify("prefix before WikiWord").should == "PrefixBeforeWikiWord"
    end
  end # wikify


  context "#wikify_path" do
    it "turns each path component into a WikiWord" do
      wikify_path("hello_world").should == "HelloWorld"
      wikify_path("hello_world/readme.txt").should == "HelloWorld/ReadmeTxt"
    end

    it "capitalizes the last letter of single-word path components" do
      wikify_path("features/basic").should == "FeatureS/BasiC"
      wikify_path("features/basic/some.feature").should == "FeatureS/BasiC/SomeFeature"
    end
  end # wikify_path


  context "#clean_filename" do
    it "converts path separators to underscores" do
      clean_filename('some/path/name', '', '').should == 'some_path_name'
    end

    it "removes prefix and suffix" do
      clean_filename('abc/some/path/xyz', 'abc', 'xyz').should == 'some_path'
    end
  end # clean_filename


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
  end # remove_cruft


  context "#table_digest" do
    it "returns the expected digest for a known table" do
      table_digest(['foo', 'bar']).should == '3858f62230ac3c915f300c664312c63f'
      table_digest(['foo', 'baz']).should == '80338e79d2ca9b9c090ebaaa2ef293c7'
    end

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

    it "unescapes HTML entities before calculating digest" do
      table1 = [
        ["Name", "Quest"],
        ["!-Arthur-!", "Holy &lt;Grail&gt;"],
      ]
      table2 = [
        ["Name", "Quest"],
        ["Arthur", "Holy <Grail>"],
      ]
      table_digest(table1).should == table_digest(table2)
    end
  end # table_digest


  context "#clean_cell" do
    it "strips all markup added by the SlimJSON formatter" do
      clean_cell("report:Feature: Some feature").should == "Feature: Some feature"
      clean_cell("report:Scenario: A scenario").should == "Scenario: A scenario"
      clean_cell("ignore:@some_tag").should == "@some_tag"
      clean_cell("pass:Given a passing step").should == "Given a passing step"
      clean_cell("pass:Given some <b>bold text</b>").should == "Given some bold text"
      clean_cell("pass:Given some <b>bold text</b>").should == "Given some bold text"
      clean_cell("fail:When failing step <br>With line break").should == "When failing step"
      span = '<span class="source_file">features/steps/whatever.rb:15</span>'
      clean_cell("pass:Given a step #{span}").should == "Given a step"
      clean_cell("pass:Given a <b>bold</b> step #{span}").should == "Given a bold step"
      clean_cell("pass:Given a step #{span} <br>with line break").should == "Given a step"
    end
  end # clean_cell


  context "#unescape" do
    it "unescapes HTML entities" do
      unescape("With &lt;angle brackets&gt;").should == "With <angle brackets>"
      unescape("Stuff &amp; things").should == "Stuff & things"
    end

    it "unescapes FitNesse literal markup" do
      unescape("!-a literal-!").should == "a literal"
      unescape("ends with !-a literal-!").should == "ends with a literal"
      unescape("!-starts with-! a literal").should == "starts with a literal"
    end
  end # unescape

end

