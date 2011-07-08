# cuke.rb

# FIXME: This is a hack to support running cucumber features.
# May have unwanted side-effects.
$:.unshift File.join(File.dirname(__FILE__), '..')

require 'json'
require 'fileutils'
require 'diff/lcs/array'

require 'cukable/helper'
require 'cukable/conversion'

module Cukable

  # Exception raised when a table is not in the expected format
  class FormatError < Exception
  end

  # This fixture allows running Cucumber from FitNesse via rubyslim.
  class Cuke

    include Cukable::Helper
    include Cukable::Conversion

    # Hash mapping the MD5 digest of a feature to the .json output for that
    # feature. This tells `do_table` whether a feature has already been
    # run by the accelerator, and prevents it from being run again.
    @@output_files = Hash.new

    # Last-run FitNesse suite. Indicates whether a higher-level accelerator
    # has already run. For example, if `HelloWorld.AaaAccelerator` has already
    # run, then there's no need to run `HelloWorld.SuiteOne.AaaAccelerator` or
    # `HelloWorld.SuiteTwo.AaaAccelerator`.
    @@last_suite_name = nil


    # Execute a block inside `@project_dir`.
    def in_project_dir(&block)
      Dir.chdir(@project_dir, &block)
    end


    # Create the fixture, with optional Cucumber command-line arguments.
    #
    # @param [String] cucumber_args
    #   If this constructor is called from a `Cuke` table, then
    #   these arguments will be passed to Cucumber for that single
    #   test. Otherwise, the `cucumber_args` passed to `accelerate`
    #   take precedence.
    #
    def initialize(cucumber_args='', project_dir='')
      # Path to where temporary .feature files will be written
      # (relative to @project_dir)
      @features_dir = File.join('features', 'fitnesse')
      # Where JSON output files will be written by Cucumber
      # (relative to @project_dir)
      @output_dir = 'slim_results'
      # Cucumber command-line arguments
      @cucumber_args = cucumber_args or ''
      @project_dir = File.expand_path((project_dir or '.'))
      ensure_directory(@project_dir)
    end


    # Perform a batch-run of all features found in siblings of the given test
    # in the FitNesse wiki tree. This only takes effect if `test_name` ends
    # with `AaaAccelerator`; otherwise, nothing happens. The test results for
    # each feature are stored in `@@output_files`, indexed by a hash of the
    # feature contents; the individual tests in the suite will then invoke
    # `do_table`, which looks up the test results in `@@output_files`.
    #
    # @param [String] test_name
    #   Dotted name of the test page in FitNesse. For example,
    #   `'HelloWorld.AaaAccelerator'`
    # @param [String] cucumber_args
    #   Command-line arguments to pass to Cucumber for this run.
    #   Affects all tests in the suite.
    #
    def accelerate(test_name, cucumber_args='', project_dir='')
      # Remove wiki cruft from the test_path
      test_name = remove_cruft(test_name)
      @cucumber_args = cucumber_args
      @project_dir = File.expand_path((project_dir or '.'))
      ensure_directory(@project_dir)

      # Don't run the accelerator unless we're on a page called AaaAccelerator
      if !(test_name =~ /^.*AaaAccelerator$/)
        return true
      else
        # Get the suite path (everything up to the last '.')
        parts = test_name.split('.')
        suite_path = parts[0..-2].join('/')
      end

      # If a higher-level accelerator has already run, skip this run
      if @@last_suite_name != nil && suite_path =~ /^#{@@last_suite_name}/
        return true
      # Otherwise, this is the top-level accelerator in the suite
      else
        @@last_suite_name = suite_path
      end

      # Find the suite in the FitNesseRoot
      suite = "FitNesseRoot/" + suite_path

      # Delete and recreate @features_dir and @output_dir
      # FIXME: May need to be smarter about this--what happens if
      # two people are running different suites at the same time?
      # The same suite at the same time?
      [@features_dir, @output_dir].each do |dir|
        in_project_dir do
          FileUtils.rm_rf(dir)
          FileUtils.mkdir(dir)
        end
      end

      # Reset the digest-to-json map, then fill it in with the
      # digest and .json output file of each feature that ran
      @@output_files = Hash.new

      # Write all .feature files and run Cucumber on them
      in_project_dir do
        feature_filenames = write_suite_features(suite)
        run_cucumber(feature_filenames)
      end

      # Parse the results out over their sources.
      return true # Wait for someone to test one of the same tables.
    end


    # Write `.feature` files for all scenarios found in `suite`,
    # and return an array of all `.feature` filenames.
    def write_suite_features(suite)
      # For all FitNesse content files in the suite
      feature_filenames = []

      Dir.glob(File.join(suite, '**', 'content.txt')).each do |fitnesse_filename|
        feature = clean_filename(fitnesse_filename, suite, 'content.txt')
        number = 0
        # For all feature tables in the content file
        fitnesse_to_features(File.open(fitnesse_filename)).each do |table|
          # Write the table to a .feature file with a unique name
          feature_filename = File.join(
            @features_dir, "#{feature}_#{number}.feature")
          feature_filenames << feature_filename
          begin
            in_project_dir do
              write_feature(table, feature_filename)
            end
          rescue FormatError => err
            puts "!!!! Error writing #{feature_filename}:"
            puts err.message
            puts err.backtrace[0..5].join("\n")
            puts ".... Continuing anyway."
          end

          # Store the JSON filename in the digest hash
          digest = table_digest(table)
          json_filename = File.join(@project_dir, @output_dir, "#{feature_filename}.json")
          @@output_files[digest] = json_filename
        end
      end
      return feature_filenames
    end


    # Execute a single test in a FitNesse TableTable.
    #
    # @param [Array] table
    #   Rows in the TableTable, where each row is an Array of strings
    #   containing cell contents.
    #
    # @return [Array]
    #   Same structure and number of rows as the input table, but with standard
    #   SliM status indicators and additional HTML formatting for displaying
    #   the test results in place of the original table.
    #
    def do_table(table)
      # If the digest of this table already exists in @output files,
      # simply return the results that were already generated.
      existing = @@output_files[table_digest(table)]
      if existing
        results = existing
      # Otherwise, run Cucumber from scratch on this table,
      # and return the results
      else
        feature_filename = File.join(@features_dir, 'fitnesse_test.feature')
        # Create the feature file, run cucumber, return results
        in_project_dir do
          ensure_directory(@features_dir)
          write_feature(table, feature_filename)
          run_cucumber([feature_filename])
        end
        results = File.join(@project_dir, @output_dir, "#{feature_filename}.json")
      end

      # If the results file exists, parse it, merge with the original table,
      # and return the results
      if File.exist?(results)
        json = JSON.load(File.open(results))
        merged = merge_table_with_results(table, json)
        return merged
      # Otherwise, return an 'ignore' for all rows/cells in the table
      else
        return table.collect { |row| row.collect { |cell| 'ignore' } }
      end
    end


    # Merge the original input table with the actual results, and
    # return a new table that puts the results section in the correct place,
    # with all other original rows marked as ignored.
    #
    # @param [Array] input_table
    #   The original TableTable content as it came from FitNesse
    # @param [Array] json_results
    #   JSON results returned from Cucumber, via the SlimJSON formatter
    #
    # @return [Array]
    #   Original table with JSON results merged into the corresponding
    #   rows, and all other rows (if any) marked as ignored.
    #
    def merge_table_with_results(input_table, json_results)
      final_results = []
      # Strip extra stuff from the results to get the original line
      clean_results = json_results.collect do |row|
        row.collect do |cell|
          clean_cell(cell)
        end
      end
      # Perform a context-diff
      input_table.sdiff(clean_results).each do |diff|
        # If this row was in the input table, but not in the results,
        # output it as an ignored row
        if diff.action == '-'
          # Ignore all cells in the row
          final_results << input_table[diff.old_position].collect do |cell|
            "ignore:#{cell}"
          end
        # In all other cases, output the row from json_results
        else # '=', '+', '!'
          final_results << json_results[diff.new_position]
        end
      end
      return final_results
    end


    # Write a Cucumber `.feature` file containing the lines of Gherkin text
    # found in `table`.
    #
    # @param [Array] table
    #   TableTable content as it came from FitNesse
    # @param [String] feature_filename
    #   Name of `.feature` file to write the converted Cucumber feature to
    #
    def write_feature(table, feature_filename)
      # Have 'Feature:' or 'Scenario:' been found in the input?
      got_feature = false
      got_scenario = false

      ensure_directory(@features_dir)
      file = File.open(feature_filename, 'w')

      # Error if there is not exactly one "Feature" row
      features = table.select { |row| row.first =~ /^\s*Feature:/ }
      if features.count != 1
        raise FormatError, "Table needs exactly one 'Feature:' row."
      end

      # Error if there are no "Scenario" or "Scenario Outline" rows
      scenarios = table.select { |row| row.first =~ /^\s*Scenario( Outline)?:/ }
      if scenarios.count < 1:
        raise FormatError, "Table needs at least one 'Scenario:' or 'Scenario Outline:' row."
      end

      # Write all other lines from the table
      table.each do |row|
        # If this row starts with an empty cell, output remaining cells
        # as a |-delimited table
        if row.first.strip == ""
          file.puts "  | " + unescape(row[1..-1].join(" | ")) + " |"
        # For all other rows, output all cells joined by spaces
        else
          # Replace &lt; and &gt; so scenario outlines will work
          line = unescape(row.join(" "))
          file.puts line
        end
      end

      file.close
    end


    # Run cucumber on `feature_filenames`, and output
    # results in FitNesse table format to `@output_dir`.
    #
    # @param [Array] feature_filenames
    #   All `.feature` files to execute
    #
    def run_cucumber(feature_filenames)
      # Tell cucumber to require the directory where this file lives,
      # so it can find the SlimJSON formatter
      req = "--require #{File.expand_path(File.dirname(__FILE__))}"
      format = "--format Cucumber::Formatter::SlimJSON"
      output = "--out #{@output_dir}"
      args = @cucumber_args
      features = feature_filenames.join(" ")

      #puts "cucumber #{req} #{format} #{output} #{args} #{features}"
      system "cucumber #{req} #{format} #{output} #{args} #{features}"

      # TODO: Ensure that the correct number of output files were written
      #if !File.exist?(@results_filename)
        #raise "Cucumber failed to write '#{@results_filename}'"
      #end
    end


    # Ensure that a directory `path` exists
    def ensure_directory(path)
      FileUtils.mkdir_p(path) unless File.directory?(path)
    end

  end
end

