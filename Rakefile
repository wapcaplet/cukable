require 'rubygems'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'

RSpec::Core::RakeTask.new do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--color', '--format doc']
end

desc "Generate RCov coverage report"
RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--color', '--format doc']
  spec.rcov = true
  spec.rcov_opts = %w{--exclude osx\/objc,gems\/,spec\/,features\/}
end

desc "Run Cucumber and generate RCov report"
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "--format pretty"
  t.rcov = true
  t.rcov_opts = %w{--exclude gems\/ -i lib\/cukable\/slim_json_formatter.rb}
end

