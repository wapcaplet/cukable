$:.unshift File.join(File.dirname(__FILE__), '../../lib')

require 'rubygems'
require 'fileutils'
require 'tempfile'

class CukableHelper
  def initialize
    remove_test_dir
    create_test_dir
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
      FileUtils.mkdir_p 'features/support'
      FileUtils.mkdir 'features/step_definitions'
      create_env_rb
      create_stepdefs
    end
  end


  def create_standard_fitnesse_dir
    in_test_dir do
      FileUtils.mkdir_p 'FitNesseRoot'
    end
  end


  def create_test_dir
    FileUtils.mkdir_p test_dir
  end


  def remove_test_dir
    FileUtils.rm_rf test_dir
  end


  def create_fitnesse_page(page_name, content)
    in_test_dir do
      page_dir = File.join('FitNesseRoot', page_name)
      page_file = File.join(page_dir, 'content.txt')
      FileUtils.mkdir_p page_dir
      File.open(page_file, 'w') do |file|
        file.puts(content)
      end
    end
  end


  # Create features/support/env.rb with necessary configuration for running
  # cucumber there
  def create_env_rb
    in_test_dir do
      File.open('features/support/env.rb', 'w') do |file|
        file.puts "$:.unshift File.join(File.dirname(__FILE__), '../../../lib')"
        file.puts "require 'cukable/slim_json_formatter'"
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
          Given /^I have a table:$/ do |table|
            table.raw.each do |row|
              row.each do |cell|
                cell.should == 'OK'
              end
            end
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


  # Ensure that the given file contains exactly the given text
  # (extra newlines/whitespace at beginning or end don't count)
  def file_should_contain(filename, text)
    in_test_dir do
      IO.read(filename).strip.should == text.strip
    end
  end


  # Ensure that the given filename contains JSON text.
  #
  # JSON does not need to match exactly; the output of each line
  # should *start* with the expected JSON text, but could contain
  # additional stuff afterwards.
  def file_should_contain_json(filename, json_text)
    in_test_dir do
      got_json = JSON.load(File.open(filename))
      want_json = JSON.parse(json_text)

      got_json.zip(want_json).each do |got_row, want_row|
        got_row.zip(want_row).each do |got, want|
          got.should =~ /^#{want}/
        end
      end
    end
  end
end

World do
  CukableHelper.new
end

After do
  #remove_test_dir
end

