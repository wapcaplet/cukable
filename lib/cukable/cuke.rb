# Cucumber fixture, for running tests with Rubyslim
#
# Create a TableTable formatted like this:
#
#   | Table: Cuke |
#   | Feature:    | Optional feature name  |
#   | Scenario:   | Optional scenario name |
#   | Given       | some initial condition |
#   | When        | I do some action       |
#   | Then        | the result is correct  |

#require 'rubygems'
require 'json'
require 'fileutils'
require 'digest/md5'

class FormatError < Exception
end

module Cukable
  class Cuke

    # Hash mapping the MD5 digest of a feature to the .json output for that
    # feature. Something of a hack, using a class variable for this, but it
    # seems the easiest way to make the hash persist across test runs.
    @@output_files = Hash.new
    @@lastSuiteName = nil

    def initialize
      # Directory where temporary .feature files will be written
      @features_dir = File.join('features', 'fitnesse')
      # Directory where JSON output files will be written by Cucumber
      @output_dir = 'slim_results'
    end


    # Fixture method call.  Pass the path of the suite. (RubySlim.HelloWorld, for example.)
    def run_suite(suite_name, parent='')
      # Remove wiki cruft from the suite_name
      suite_name = remove_cruft(suite_name)

      # Verify that a higher-level accelerator has not already run analyzeSuite
      # covering this part of the tree. E.g. RubySlim.HelloWorld.NewTest starts
      # with "RubySlim.HelloWorld". But RubySlim.NewTest does not start with
      # "RubySlim.HelloWorld".
      if @@lastSuiteName != nil && suite_name =~ /^#{@@lastSuiteName}/
        puts "@@lastSuiteName: #{@@lastSuiteName}"
        return true;
      end
      @@lastSuiteName = suite_name

      suitePath = suite_name.gsub('.', '/')

      # Find the FitNesseRoot.
      # Find the suite in the FitNesseRoot.
      suite = "FitNesseRoot/"+suitePath

      # Delete and recreate @features_dir and @output_dir
      # FIXME: May need to be smarter about this--what happens if
      # two people are running different suites at the same time?
      # The same suite at the same time?
      [@features_dir, @output_dir].each do |dir|
        FileUtils.rm_rf(dir)
        FileUtils.mkdir(dir)
      end

      # Reset the digest-to-json map, then fill it in with the
      # digest and .json output file of each feature that ran
      @@output_files = Hash.new

      # Write all .feature files and run Cucumber on them
      feature_filenames = write_suite_features(suite)
      run_cucumber(feature_filenames, @output_dir)

      # Parse the results out over their sources.
      return true # Wait for someone to test one of the same tables.
    end


    # Write `.feature` files for all scenarios found in `suite`,
    # and return an array of all `.feature` filenames.
    def write_suite_features(suite)
      # For all FitNesse content files in the suite
      feature_filenames = []
      fitnesse_content_files(suite).each do |fitnesse_filename|
        feature = clean_filename(fitnesse_filename, suite, 'content.txt')
        number = 0
        # For all feature tables in the content file
        cuke_tables(fitnesse_filename).each do |table|
          # Write the table to a .feature file with a unique name
          feature_filename = File.join(
            @features_dir, "#{feature}_#{number}.feature")
          feature_filenames << feature_filename
          write_feature(table, feature_filename)

          # Store the JSON filename in the digest hash
          digest = table_digest(table)
          json_filename = File.join(@output_dir, "#{feature_filename}.json")
          @@output_files[digest] = json_filename
        end
      end
      return feature_filenames
    end


    # Process the given Cucumber table, containing one step per line
    # Table Table fixture method call.
    def do_table(table)
      # If the digest of this table already exists in @output files,
      # simply return the results that were already generated.
      existing = @@output_files[table_digest(table)]
      if existing
        return get_results(existing)
      # Otherwise, run Cucumber from scratch on this table,
      # and return the results
      else
        # FIXME: Move this to a separate method?
        # Create @features_dir if it doesn't exist
        FileUtils.mkdir(@features_dir) unless File.directory?(@features_dir)
        feature_filename = File.join(@features_dir, 'fitnesse_test.feature')
        out_file = File.join(@output_dir, "#{feature_filename}.json")
        # Create the feature file, run cucumber, return results
        write_feature(table, feature_filename)
        run_cucumber([feature_filename], @output_dir)
        return get_results(out_file)
      end
    end


    # Write a Cucumber .feature file containing the lines of Gherkin text
    # found in `table`, where `table` is an array of arrays of strings.
    def write_feature(table, feature_filename)
      # Have 'Feature:' or 'Scenario:' been found in the input?
      got_feature = false
      got_scenario = false

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
          file.puts "  | " + row[1..-1].join(" | ") + " |"
        # For all other rows, output all cells joined by spaces
        else
          # Replace &lt; and &gt; so scenario outlines will work
          line = row.join(" ").gsub('&lt;', '<').gsub('&gt;', '>')
          file.puts line
        end
      end

      file.close
    end


    # Run cucumber on `feature_filenames`, and output
    # results in FitNesse table format to `output_dir`.
    def run_cucumber(feature_filenames, output_dir)
      format = "--format Cucumber::Formatter::SlimJSON"
      output = "--out #{output_dir}"
      features = feature_filenames.join(" ")

      system "cucumber #{format} #{output} #{features}"

      # TODO: Ensure that the correct number of output files were written
      #if !File.exist?(@results_filename)
        #raise "Cucumber failed to write '#{@results_filename}'"
      #end
    end


    # Read results from given JSON filename and return a 2D array
    def get_results(json_filename)
      results = JSON.load(File.open(json_filename))
      return results
    end


    # Return a list of all FitNesse content files within the given directory
    # (recursing into subdirectories).
    def fitnesse_content_files(dir)
      pattern = File.join(dir, '**', 'content.txt')
      return Dir.glob(pattern)
    end


    # Return an MD5 digest string for `table`, where `table` is in the same
    # format accepted by `do_table`.
    def table_digest(table)
      digest = Digest::MD5.new
      table.flatten.each do |cell|
        digest.update(cell.gsub('&lt;', '<').gsub('&gt;', '>'))
      end
      return digest.to_s
    end


    # Return an array of Cucumber tables found in the given FitNesse content
    # file, or an empty array if no tables are found. Each table in the array
    # is in the same format as a table passed to the `do_table` method; that is,
    # a table is an array of rows, where each row is an array of strings found
    # in each cell of the table.
    def cuke_tables(fitnesse_filename)

      tables = []         # List of all tables parsed so far
      current_table = []  # List of lines in the current table
      in_table = false    # Are we inside a table right now?

      File.open(fitnesse_filename).each do |line|
        # Strip newline
        line = line.strip

        # Beginning of a new table?
        if line =~ /\| *Table *: *Cuke *\| *$/
          in_table = true
          current_table = []

        # Already in a table?
        elsif in_table
          # Append a new row to the current table, with pipes
          # and leading/trailing whitespace removed
          if line =~ /\| *(.*) *\| *$/
            row = $1.split('|').collect { |cell| cell.strip }
            current_table << row
          # No more rows; end this table and append to the results
          else
            in_table = false
            tables << current_table
            current_table = []
          end

        else
          # Ignore all non-table lines in the content
        end
      end

      # If we're still inside a table, append it (this means that the last line
      # of the table was the last line of the file, and there were no more
      # lines after the table to terminate it)
      if in_table
        tables << current_table
      end

      return tables
    end


    # Return `filename` with `prefix` and `suffix` removed, and any
    # path-separators converted to underscores.
    def clean_filename(filename, prefix, suffix)
      middle = filename.gsub(/^#{prefix}\/(.+)\/#{suffix}$/, '\1')
      return middle.gsub('/', '_')
    end


    # Remove FitNesse-generated link cruft from a string. Strips <a ...></a> tags,
    # keeping the inner content unless that content is '[?]'.
    def remove_cruft(string)
      string.gsub(/<a [^>]*>([^<]*)<\/a>/, '\1').gsub('[?]', '')
    end

  end
end

