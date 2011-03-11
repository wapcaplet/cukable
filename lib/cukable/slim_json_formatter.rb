require 'cucumber/formatter/console'
require 'cucumber/formatter/io'
require 'fileutils'
require 'json'

module Cucumber
  module Formatter
    # FitNesse SliM JSON output formatter
    class SlimJSON
      include Console
      include Io
      include FileUtils

      # Create a new SlimJSON formatter, with the provided path_or_io (as given
      # by the --out option) and any additional options passed to cucumber.
      def initialize(step_mother, path_or_io, options)
        @step_mother = step_mother

        # Output directory
        @out_dir = path_or_io
        ensure_dir(@out_dir, "FitNesse")

        # There should be no IO until we get a feature, and
        # create the output directory in before_feature
        @io = nil

        # Cache of data lines to write
        @data = []
        # Multi-line output (must be cached and printed after the step that
        # precedes it)
        @multiline = []
      end


      # Before each .feature is run, create a new output file
      # for the results in @out_dir
      def before_feature(feature)
        file = File.join(@out_dir, "#{feature.file}.json")
        dir = File.dirname(file)
        mkdir_p(dir) unless File.directory?(dir)
        @io = ensure_file(file, "FitNesse")
        @data = []
      end


      # After each .feature is run, write output to the JSON file, then
      # close the output file.
      def after_feature(feature)
        @io.puts JSON.pretty_generate(@data)
        @io.flush
        @io.close
      end


      # Called when "Feature: <name>" is read
      # Generates a single row of SliM JSON output with the feature name.
      def feature_name(keyword, name)
        @data << [section_message(keyword, name)]
      end


      # Called when "Scenario: <name>" is read
      # Generates a single row of SliM JSON output with the scenario name.
      def scenario_name(keyword, name, file_colon_line, source_indent)
        @data << [section_message(keyword, name, file_colon_line)]
      end


      # Called when "Background:" is read
      # Generates a single row of SliM JSON output
      def background_name(keyword, name, file_colon_line, source_indent)
        @data << [section_message(keyword, name, file_colon_line)]
      end


      # Start a new multiline arg (such as a table)
      def before_multiline_arg(multiline_arg)
        @multiline = []
      end


      # Add each | table | row | to the multiline arg (these will be output
      # later, in after_step_result, since they should follow the step's output)
      def after_table_row(table_row)
        if table_row.exception
          # TODO: Output stack trace
          @multiline << ["report: "] + table_row.collect {|cell| "fail: #{cell.value}"}
        else
          @multiline << ["report: "] + table_row.collect {|cell| "pass: #{cell.value}"}
        end
      end


      # An "Examples:" table works similarly to a multiline argument, except
      # there is no associated step to output them. The after_table_row method
      # will still accumulate the table rows, but we need to rely on
      # after_examples to output them.
      def before_examples(examples)
        @multiline = []
      end


      def examples_name(keyword, name)
        @data << ["report:#{keyword}: #{name}"]
      end


      def after_examples(examples)
        # Output any multiline args that followed this step
        @multiline.each do |row|
          @data << row
        end
        @multiline = []
      end


      # Called after a step has been executed, but before any output from
      # that step has been done
      def before_step(step)
        @current_step = step
      end


      # Called when a multi-line string argument is read
      # Generates a row of SliM JSON for each line in the multi-line string
      # (including the """ opening and closing lines), colored based on
      # the status of the current step.
      def py_string(string)
        status = status_map[@current_step.status]
        @multiline << [status + ':"""']
        string.split("\n").each do |line|
          @multiline << ["#{status}:#{line}"]
        end
        @multiline << [status + ':"""']
      end


      # Called when a tag name is found
      # Generates a single row of SliM JSON output with the tag name.
      # (Note that this will only work properly if there is only
      # one tag per line; otherwise, too many lines may be output.)
      def tag_name(tag_name)
        @data << ["ignore:#{tag_name}"]
      end


      # Called after a step has executed, and we have a result.
      # Generates a single row of SliM JSON output, including the status of the
      # completed step, along with one row for each line in a multi-line
      # argument (if any were provided).
      def after_step_result(keyword, step_match, multiline_arg, status, exception, source_indent, background)
        # One-line message to print
        message = ''
        # A bit of a hack here to support Scenario Outlines
        # Apparently, at the time of calling after_step_result, a StepMatch in
        # a Scenario Outline has a `name` attribute (and no arguments to
        # format, because they don't get pattern-matched until the Examples:
        # section that fills them in), whereas a StepMatch in a normal scenario
        # has no value set for its `name` attribute, and *does* have arguments
        # to format. This behavior is exploited here for the sake of replacing
        # the `<...>` angle brackets that appear in Scenario Outline steps.
        #
        # In other words, if `step_match` has a `name`, assume it's in a
        # Scenario Outline, and replace the angle brackets (so the bracketed
        # parameter can be displayed in an HTML page)
        if step_match.name
          step_name = keyword + step_match.name.gsub('<', '&lt;').gsub('>', '&gt;')
        # Otherwise, wrap the arguments in bold tags
        else
          step_name = keyword + step_match.format_args("<b>%s</b>")
        end

        # Color passed steps green
        if status == :passed
          message = "pass:#{step_name}"

        # Color failed steps red, and include the error message and stack trace
        elsif status == :failed
          message = "fail:#{step_name}"
          if exception
            message += "<br/>" + sanitize(exception.message) + "<br/>"
            message += exception.backtrace.collect { |line|
              sanitize(line)
            }.join("<br/>")
          end

        # Color undefined steps yellow
        elsif status == :undefined
          message = "error:#{step_name}<br/>(Undefined Step)"

        # Color skipped steps grey
        elsif status == :skipped
          message = "ignore:#{step_name}"

        end

        # Add the source file and line number where this step was defined
        message += source_message(step_match.file_colon_line)

        # Output the final message for this step
        @data << [message]

        # Output any multiline args that followed this step
        @multiline.each do |row|
          @data << row
        end
        @multiline = []
      end


      # ------------------------
      # Utility methods
      # (not called by Cucumber)
      # ------------------------

      # Map Cucumber status strings to FitNesse status strings
      def status_map
        {
          :passed => 'pass',
          :failed => 'fail',
          :undefined => 'error',
          :skipped => 'ignore',
        }
      end


      # Return `text` with any HTML-specific characters sanitized
      def sanitize(text)
        text.gsub('<', '&lt;').gsub('>', '&gt;')
      end


      # Return a string for outputting the source filename and line number
      def source_message(file_colon_line)
        ' <span class="source_file">' + file_colon_line + '</span>'
      end


      # Return a string suitable for use as a section heading for "Feature:",
      # "Scenario:" or "Scenario Outline:" output rows.
      def section_message(keyword, name, file_colon_line='')
        "report:#{keyword}: #{name}" + source_message(file_colon_line)
      end

    end
  end
end

