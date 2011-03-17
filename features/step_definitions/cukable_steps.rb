# Steps for Cukable self-tests
# NOTE: Helper methods are defined in features/support/env.rb

require 'json'
require 'cukable/cuke'


Given /^a standard Cucumber project directory structure$/ do
  create_standard_cucumber_dir
end


Given /^a FitNesse wiki$/ do
  create_standard_fitnesse_dir
end


Given /^a FitNesse suite "(.+)" with:$/ do |page_name, content|
  create_fitnesse_page(page_name, content)
end


Given /^a FitNesse test "(.+)" with:$/ do |page_name, content|
  create_fitnesse_page(page_name, content)
end


Given /^a file named "(.+)" with:$/ do |filename, content|
  create_file(filename, content)
end


When /^I run cucumber on "(.+)"$/ do |feature_files|
  format = "--format Cucumber::Formatter::SlimJSON --out slim_results"
  run_cucumber("#{format} #{feature_files}")
end


Then /^"(.+)" should contain:$/ do |filename, text|
  file_should_contain(filename, text)
end


Then /^"(.+)" should contain JSON:$/ do |filename, json_text|
  file_should_contain_json(filename, json_text)
end


Given /^a Cuke fixture$/ do
  in_test_dir do
    @cuke = Cukable::Cuke.new
  end
end


When /^I do this table:$/ do |table|
  in_test_dir do
    @cuke.do_table(table.raw)
  end
end


When /^I write features for suite "(.+)"$/ do |suite_name|
  in_test_dir do
    @cuke.write_suite_features("FitNesseRoot/#{suite_name}")
  end
end


When /^I convert features to FitNesse$/ do
  in_test_dir do
    @converter = Cukable::Converter.new
    @converter.features_to_fitnesse('features', 'FitNesseRoot')
  end
end


