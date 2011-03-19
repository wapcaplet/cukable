require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'tmpdir'

describe Cukable::Cuke do
  before(:each) do
    @cuke = Cukable::Cuke.new
    @feature = File.join(Dir.tmpdir, 'cuke_spec.feature')
  end

  after(:each) do
    File.delete(@feature) if File.exists?(@feature)
  end


  context '#do_table' do
  end # do_table


  context '#write_feature' do
    context "raises a FormatError" do
      it "for empty tables" do
        table = []
        lambda do
          @cuke.write_feature(table, @feature)
        end.should raise_error(Cukable::FormatError)
      end

      it "when table has no Feature" do
        table = [
          ['Scenario: No feature'],
        ]
        lambda do
          @cuke.write_feature(table, @feature)
        end.should raise_error(Cukable::FormatError)
      end

      it "when table has too many Features" do
        table = [
          ['Feature: Too many features'],
          ['Feature: There can be only one'],
          ['Scenario: Too many features'],
        ]
        lambda do
          @cuke.write_feature(table, @feature)
        end.should raise_error(Cukable::FormatError)
      end

      it "when table has no Scenario" do
        table = [
          ['Feature: No scenario'],
        ]
        lambda do
          @cuke.write_feature(table, @feature)
        end.should raise_error(Cukable::FormatError)
      end
    end # FormatError

    it "writes embedded tables correctly" do
      table = [
        ['Feature: Table'],
        ['Scenario: Table'],
        ['Given a table:'],
        ['', 'foo', 'bar'],
        ['', 'boo', 'far'],
      ]
      feature_text = [
        ['Feature: Table'],
        ['Scenario: Table'],
        ['Given a table:'],
        ['  | foo | bar |'],
        ['  | boo | far |'],
      ].join("\n")
      @cuke.write_feature(table, @feature)
      File.read(@feature).strip.should == feature_text
    end

    it "unescapes &lt; and &gt;" do
      table = [
        ['Feature: Brackets'],
        ['Scenario Outline: Brackets'],
        ['Given <thing>'],
        ['Examples:'],
        ['', 'thing'],
        ['', 'spaceship'],
        ['', 'time machine'],
      ]
      feature_text = [
        ['Feature: Brackets'],
        ['Scenario Outline: Brackets'],
        ['Given <thing>'],
        ['Examples:'],
        ['  | thing |'],
        ['  | spaceship |'],
        ['  | time machine |'],
      ].join("\n")
      @cuke.write_feature(table, @feature)
      File.read(@feature).strip.should == feature_text
    end

  end # write_feature


  context "#merge_table_with_results" do
    it "marks missing lines as ignored" do
      input_table = [
        ['Feature: Merge'],
        ['Scenario: Skip'],
        ['Given a scenario is skipped'],
        ['Scenario: Run'],
        ['Given a scenario is run'],
        ['Scenario: Skip again'],
        ['Given a scenario is skipped'],
      ]
      json_results = [
        ['report:Feature: Merge'],
        ['report:Scenario: Run'],
        ['pass:Given a <b>scenario</b> is run'],
      ]
      expected_results = [
        ['report:Feature: Merge'],
        ['ignore:Scenario: Skip'],
        ['ignore:Given a scenario is skipped'],
        ['report:Scenario: Run'],
        ['pass:Given a <b>scenario</b> is run'],
        ['ignore:Scenario: Skip again'],
        ['ignore:Given a scenario is skipped'],
      ]
      actual_results = @cuke.merge_table_with_results(input_table, json_results)
      actual_results.should == expected_results
    end
  end # merge_table_with_results

end
