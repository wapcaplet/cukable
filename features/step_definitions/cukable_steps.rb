require 'json'

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
    JSON.load(File.open(filename)).should == JSON.parse(json_text)
  end
end

