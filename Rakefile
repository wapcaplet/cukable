require 'rubygems'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'

desc "Run RSpec and generate coverage report"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = ['--color', '--format doc']
  t.rcov = true
  t.rcov_opts = [
    '--exclude /.gem/,/gems/,spec,features',
    '--include lib/**/*.rb',
    #'--aggregate coverage.data',
  ]
end

desc "Run Cucumber and generate coverage report"
Cucumber::Rake::Task.new(:cucumber) do |t|
  t.cucumber_opts = "--format pretty"
  t.rcov = true
  t.rcov_opts = [
    '--exclude /.gem/,/gems/,spec,features',
    '--include lib/**/*.rb',
    #'--aggregate coverage.data',
  ]
end

#namespace :rcov do
  #desc "Run specs and features to generate aggregated coverage"
  #task :all do |t|
    #rm 'coverage.data' if File.exist?('coverage.data')
    #Rake::Task['rcov:spec'].invoke
    #Rake::Task['rcov:cucumber'].invoke
  #end
#end
