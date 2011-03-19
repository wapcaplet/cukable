# Steps for Cukable self-tests
# NOTE: Helper methods are defined in features/support/env.rb

require 'json'
require 'cukable/cuke'


Given /^a standard Cucumber project directory structure$/ do
  create_standard_cucumber_dir
end


Given /^a FitNesse wiki$/ do
  create_standard_fitnesse_dir
  @fitnesse_root = 'FitNesseRoot'
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


Then /^"(.+)" should not exist$/ do |filename|
  in_test_dir do
    if File.exist?(filename)
      raise Exception, "Expected #{filename} to be non-existent, but it exists"
    end
  end
end


Given /^a (Test|Suite) "(.+)" containing:$/ do |type, filename, content|
  content_file = File.join(@fitnesse_root, filename, 'content.txt')
  properties_file = File.join(@fitnesse_root, filename, 'properties.xml')
  create_file(content_file, content)
  create_file(properties_file, xml_content(type))
end


Then /^I should have a (Test|Suite) "(.+)" containing:$/ do |type, filename, content|
  content_file = File.join(@fitnesse_root, filename, 'content.txt')
  properties_file = File.join(@fitnesse_root, filename, 'properties.xml')
  file_should_contain(content_file, content)
  file_should_contain(properties_file, xml_content(type))
end


Given /^a Cuke fixture$/ do
  in_test_dir do
    @cuke = Cukable::Cuke.new
    @cucumber_args = ''
  end
end


When /^I do this table:$/ do |table|
  in_test_dir do
    @table = @cuke.do_table(table.raw)
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
    @converter.features_to_fitnesse('features', @fitnesse_root)
  end
end


When /^I set CUCUMBER_ARGS to "(.+)"$/ do |args|
  @cucumber_args = args
end


When /^I run the accelerator for suite "(.+)"$/ do |suite_name|
  in_test_dir do
    @cuke.accelerate("#{suite_name}.AaaAccelerator", @cucumber_args)
  end
end

