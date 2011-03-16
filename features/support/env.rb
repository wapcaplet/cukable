require 'rubygems'
require 'fileutils'
require 'tempfile'

class CukableHelper
  def initialize
    FileUtils.rm_rf test_dir
    FileUtils.mkdir_p test_dir
  end


  def test_dir
    @test_dir ||= File.expand_path(File.join(File.dirname(__FILE__), '../../self_test'))
  end


  # Execute `block` within `test_dir`
  def in_test_dir(&block)
    Dir.chdir(test_dir, &block)
  end


  # Create a standard cucumber features/ directory in `test_dir`
  def create_standard_cucumber_dir
    in_test_dir do
      FileUtils.rm_rf 'features' if File.directory?('features')
      FileUtils.mkdir_p 'features/support'
      FileUtils.mkdir 'features/step_definitions'
      create_env_rb
      create_stepdefs
    end
  end


  # Create features/support/env.rb with necessary configuration for running
  # cucumber there
  def create_env_rb
    in_test_dir do
      File.open('features/support/env.rb', 'w') do |file|
        file.puts "require File.join(File.dirname(__FILE__) + '/../../../lib/cukable/slim_json_formatter')"
      end
    end
  end


  def create_stepdefs
    in_test_dir do
      File.open('features/step_definitions/simple_steps.rb', 'w') do |file|
        file.puts <<-EOF
          Given /^a step passes$/ do
            true.should == true
          end
          Given /^a step fails$/ do
            true.should == false
          end
          Given /^a step is skipped$/ do
            true.should == true
          end
        EOF
      end
    end
  end

  # Create a file relative to `test_dir`
  def create_file(filename, content)
    in_test_dir do
      FileUtils.mkdir_p(File.dirname(filename)) unless File.directory?(File.dirname(filename))
      File.open(filename, 'w') { |f| f << content + "\n" }
    end
  end


  # Run cucumber with the given command-line argument string
  def run_cucumber(args)
    stderr_file = Tempfile.new('cucumber')
    stderr_file.close
    in_test_dir do
      mode = Cucumber::RUBY_1_9 ? {:external_encoding=>"UTF-8"} : 'r'
      IO.popen("cucumber #{args} 2> #{stderr_file.path}", mode) do |io|
        @last_stdout = io.read
        puts @last_stdout
      end
      #@last_exit_status = $?.exitstatus
    end
    @last_stderr = IO.read(stderr_file.path)
    puts @last_stderr
  end

end

World do
  CukableHelper.new
end

