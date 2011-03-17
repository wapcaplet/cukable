require 'json'
require 'cukable/cuke'


Given /^a standard Cucumber project directory structure$/ do
  create_standard_cucumber_dir
end


Given /^a file named "(.+)" with:$/ do |filename, content|
  create_file(filename, content)
end


When /^I run cucumber on "(.+)"$/ do |feature_files|
  format = "--format Cucumber::Formatter::SlimJSON --out slim"
  run_cucumber("#{format} #{feature_files}")
end


Then /^"(.+)" should contain:$/ do |filename, text|
  in_test_dir do
    IO.read(filename).should == text
  end
end


Then /^"(.+)" should contain JSON:$/ do |filename, json_text|
  in_test_dir do
    got_json = JSON.load(File.open(filename))
    want_json = JSON.parse(json_text)

    # JSON does not need to match exactly; the output of each line
    # should *start* with the expected JSON text, but could contain
    # additional stuff afterwards.
    got_json.zip(want_json).each do |got_row, want_row|
      got_row.zip(want_row).each do |got, want|
        got.should =~ /^#{want}/
      end
    end
  end
end


Given /^a Cuke fixture$/ do
  @cuke = Cukable::Cuke.new
end


When /^I do this table:$/ do |table|
  @cuke.do_table(table.raw)
  @cuke.accelerate("foo")
end


# Simple steps
# TODO: Move these to a separate file, and copy it over to create the standard
# cucumber directory structure for use by the embedded tests
Given /^a step passes$/ do
  true.should == true
end

Given /^a step fails$/ do
  true.should == false
end

Given /^a step is skipped$/ do
  true.should == true
end

Given /^a table:$/ do |table|
  table.raw.each do |row|
    #row.each do |cell|
      #cell.should == 'OK'
    #end
  end
end

When /^I fill in:$/ do |table|
  table.rows_hash.each do |name, value|
    When %{I fill in "#{name}" with "#{value}"}
  end
end

When /^I fill in "(.+)" with "(.+)"$/ do |field, value|
  value.should == 'OK'
end
