# slim_json_formatter.rb

require 'cucumber/formatter/console'
require 'cucumber/formatter/io'
require 'fileutils'
require 'json'


module Cucumber
  module Formatter
    # FitNesse SliM JSON output formatter for Cucumber
    class SlimJSON
      include Console
      include Io
      include FileUtils

      # Create a new SlimJSON formatter, with the provided `path_or_io` (as
      # given by the `--out` option) and any additional options passed to
      # cucumber.
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
        # Expected/actual, to support table diffs
        @expected_row = []
        @actual_row = []

        # Not in background until we actually find one
        @in_background = false
      end


      # Called before each `.feature` is run. Creates a new output file for the
      # results in `@out_dir`, and empties `@data`.
      def before_feature(feature)
        file = File.join(@out_dir, "#{feature.file}.json")
        dir = File.dirname(file)
        mkdir_p(dir) unless File.directory?(dir)
        @io = ensure_file(file, "FitNesse")
        @data = []
      end


      # Called after each `.feature` is run. Write all `@data` to the JSON
      # file, then closes the output file.
      def after_feature(feature)
        @io.puts JSON.pretty_generate(@data)
        @io.flush
        @io.close
      end


      # Called when `Feature: <name>` is read. Generates a single row of output
      # in `@data` with the feature name.
      def feature_name(keyword, name)
        @data << [section_message(keyword, name)]
      end


      # Called when `Scenario: <name>` is read. Generates a single row of
      # output in `@data` with the scenario name.
      def scenario_name(keyword, name, file_colon_line, source_indent)
        @data << [section_message(keyword, name, file_colon_line)]
      end


      # Called before a `Background:` block.
      def before_background(background)
        @in_background = true
      end


      # Called when a `Background:` line is read. Generates a single row of
      # output in `@data` with the `Background:` line.
      def background_name(keyword, name, file_colon_line, source_indent)
        @data << [section_message(keyword, name, file_colon_line)]
      end


      # Called after a `Background:` block.
      def after_background(background)
        @in_background = false
      end


      # Start a new multiline arg (such as a table or Py-string). Initializes
      # `@multiline` and related arrays.
      def before_multiline_arg(multiline_arg)
        @multiline = []
        @expected_row = []
        @actual_row = []
      end


      # Called before a table row is read. Starts a new `@table_row`.
      def before_table_row(table_row)
        @table_row = []
      end


      # Called when a table cell value is read. Appends to `@table_row`.
      def table_cell_value(value, status)
        return if @hide_this_step
        stat = status_map(status)
        @table_row << "#{stat}:#{value}"
      end


      # Called after a table row is done being read. Appends `@table_row`
      # to `@multiline`, which will be output in `after_step_result`.
      #
      # There is some special handling here for handling table diffs;
      # when doing a table diff, and a row doesn't match, two rows are
      # generated. These need to be merged into a single row in the JSON
      # output, to maintain the 1:1 mapping between FitNesse table and
      # the returned results.
      def after_table_row(table_row)
        return if @hide_this_step

        # If we have an @expected_row and @actual_row at this point,
        # merge them into a single row and append to @multiline_arg
        if !@expected_row.empty? && !@actual_row.empty?
          cell_diff = []
          @expected_row.zip(@actual_row) do |expect, actual|
            expect.gsub!(/^ignore:/, '')
            actual.gsub!(/^error:/, '')
            # If we got what we wanted in this cell, consider it passed
            if actual == expect
              cell_diff << "pass:#{actual}"
            # Otherwise, show expected vs. actual as a failure
            else
              cell_diff << "fail:Expected: '#{expect}'<br/>Actual: '#{actual}'"
            end
          end
          @multiline << ["report: "] + cell_diff
          # Reset for upcoming rows
          @expected_row = []
          @actual_row = []
        end

        # Row with all cells having status == :comment (ignore)?
        # This row was part of a table diff, and contains the values
        # that were expected to be in the row.
        if @table_row.all? { |cell| cell =~ /^ignore:/ }
          @expected_row = @table_row

        # Row with all cells having status == :undefined (error)?
        # This row was part of a table diff, and contains the values
        # that actually appeared in the row.
        elsif @table_row.all? { |cell| cell =~ /^error:/ }
          @actual_row = @table_row

        # For any other row, append to multiline normally
        else
          # If an exception occurred in a table row, put the exception
          # message in the first cell (which is normally empty). This
          # allows us to show the exception without adding extra rows
          # (which messes up the original table's formatting)
          if table_row.exception
            @multiline << ["fail:#{backtrace(table_row.exception)}"] + @table_row
          # Otherwise, output an empty report: cell in the first column
          else
            @multiline << ["report: "] + @table_row
          end
        end

      end


      # Called before an `Examples:` section in a Scenario Outline. An
      # `Examples:` table works similarly to a multiline argument, except there
      # is no associated step to output them. The `after_table_row` method
      # will still accumulate the table rows, but we need to rely on
      # `after_examples` to output them. Thus, we will be accumulating these
      # rows in the multi-purpose `@multiline` variable, initialized here.
      def before_examples(examples)
        @multiline = []
      end


      # Called when the `Examples:` line is read. Outputs the `Examples:` line
      # to `@data`.
      def examples_name(keyword, name)
        @data << ["report:#{keyword}: #{name}"]
      end


      # Called after an `Examples:` section. Outputs anything accumulated in
      # `@multiline`, and empties it.
      def after_examples(examples)
        # Output any multiline args that followed this step
        @multiline.each do |row|
          @data << row
        end
        @multiline = []
      end


      # Called *after* a step has been executed, but *before* any output from
      # that step has been done.
      def before_step(step)
        @current_step = step
      end


      # Called when a multi-line string argument is read. Generates a row of
      # output for each line in the multi-line string (including the `"""`
      # opening and closing lines), colored based on the status of the current
      # step. The output is accumulated in `@multiline`, for output in
      # `after_step_result`.
      def py_string(string)
        return if @hide_this_step
        status = status_map(@current_step.status)
        @multiline << [status + ':"""']
        string.split("\n").each do |line|
          @multiline << ["#{status}:#{line}"]
        end
        @multiline << [status + ':"""']
      end


      # Called when a tag name is found. Generates a single row of output in
      # `@data` with the tag name. (Note that this will only work properly if
      # there is only one tag per line; otherwise, too many lines may be
      # output.)
      def tag_name(tag_name)
        @data << ["ignore:#{tag_name}"]
      end


      # Called before any output from a step result. To avoid redundant output,
      # we want to show the results of `Background` steps only once, within the
      # `Background` section (unless a background step somehow failed when it
      # was executed at the top of a Scenario). Here, `background` is true if
      # the step was defined in the `Background` section, and `@in_background`
      # is true if we are actually inside the `Background` section during
      # execution. In short, if a step was defined in the `Background` section,
      # but we are *not* within the `Background` section now, we want to hide
      # the step's output.
      def before_step_result(keyword, step_match, multiline_arg, status,
                             exception, source_indent, background)
        if status != :failed && @in_background ^ background
          @hide_this_step = true
        else
          @hide_this_step = false
        end
      end


      # Called after a step has executed, and we have a result. Generates a
      # single row of output in `@data`, including the status of the completed
      # step, along with one row for each line accumulated in a multi-line
      # argument (`@multiline`) if any were provided. Resets `@multiline` when
      # done.
      def after_step_result(keyword, step_match, multiline_arg, status,
                            exception, source_indent, background)
        return if @hide_this_step
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

        # Output the step name with appropriate colorization
        stat = status_map(status)
        message = "#{stat}:#{step_name}"

        # Add the source file and line number where this step was defined
        message += source_message(step_match.file_colon_line)

        # Include additional info for undefined and failed steps
        if status == :undefined
          message += "<br/>(Undefined Step)"
        elsif status == :failed && exception
          message += backtrace(exception)
        end

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
      def status_map(status)
        case status
          when nil        then 'pass'
          when :passed    then 'pass'
          when :failed    then 'fail'
          when :undefined then 'error'
          when :skipped   then 'ignore'
          when :comment   then 'ignore'
          else 'pass'
        end
      end


      # Return `text` with any HTML-specific characters sanitized
      def sanitize(text)
        text.gsub('<', '&lt;').gsub('>', '&gt;')
      end


      # Return a string for outputting the source filename and line number
      def source_message(file_colon_line)
        return " <span class=\"source_file\">" + file_colon_line + '</span>'
      end


      # Return a string suitable for use as a section heading for "Feature:",
      # "Scenario:" or "Scenario Outline:" output rows.
      def section_message(keyword, name, file_colon_line='')
        "report:#{keyword}: #{name}" + source_message(file_colon_line)
      end


      # Return an exception message and backtrace
      def backtrace(exception)
        message = "<br/>" + sanitize(exception.message) + "<br/>"
        message += exception.backtrace.collect { |line|
          sanitize(line)
        }.join("<br/>")
        return message
      end

    end
  end
end

