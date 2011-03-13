
require 'fileutils'
require 'cukable/helper'

module Cukable
  module Conversion

    # Wikify the given feature, and return lines of FitNesse wikitext.
    #
    # @param [Array, File] feature
    #   An iterable that yields each line of a Cucumber feature. May be
    #   an open File object, or an Array of strings.
    #
    # @return [Array]
    #   FitNesse wikitext as a list of strings
    #
    def feature_to_fitnesse(feature)

      # Unparsed text (between 'Feature:' line and the first Background/Scenario)
      unparsed = []
      # Table (all Background, Scenario, and Scenario Outlines with steps
      table = []
      table << "| Table: Cuke |"

      # Are we in the unparsed-text section of the .feature file?
      in_unparsed = false

      feature.each do |line|
        line = escape_camel_case(line.strip)

        # The Feature: line starts the table, and also starts the unparsed
        # section of the feature file
        if line =~ /^Feature:.*$/
          table << "| #{line} |"
          in_unparsed = true

        # When the first Background/Scenario block is reached, end the unparsed
        # text section
        elsif line =~ /^(Background:|Scenario:|Scenario Outline:)/
          in_unparsed = false
          table << "| #{line} |"

        # Between 'Feature:...' and the first Background/Scenario/Scenario Outline
        # block, we're in the unparsed text section
        elsif in_unparsed and !line.empty?
          unparsed << line

        # If line contains a table row, insert a '|' at the beginning
        elsif line =~ /^\|.+\|$/
          table << "| #{line}"

        # If line is commented out, skip it
        elsif line =~ /^#.*$/
          nil

        # Otherwise, if line is non-empty, insert a '|' at beginning and end
        elsif !line.empty?
          table << "| #{line} |"

        end
      end
      # If there was unparsed text, include an empty line after it
      if !unparsed.empty?
        unparsed << ''
      end
      return unparsed + table
    end


    # Return an array of Cucumber tables found in the given FitNesse content
    # file, or an empty array if no tables are found. Each table in the array
    # is in the same format as a table passed to the `do_table` method; that is,
    # a table is an array of rows, where each row is an array of strings found
    # in each cell of the table.
    #
    # @param [Array, File] wiki_page
    #   An iterable that yields each line of a FitNesse wiki page. May be
    #   an open File object, or an Array of strings.
    #
    # @return [Array]
    #   All Cucumber tables found in the given wiki page, or an empty array if
    #   no tables are found.
    #
    def fitnesse_to_features(wiki_page)

      tables = []         # List of all tables parsed so far
      current_table = []  # List of lines in the current table
      in_table = false    # Are we inside a table right now?

      wiki_page.each do |line|
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

        # Ignore all non-table lines in the content
        else
          nil
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

  end
end


module Cukable
  class Converter

    include Cukable::Helper
    include Cukable::Conversion

    # Convert all .feature files in `features_path` to FitNesse wiki pages
    # under `fitnesse_path`.
    #
    # @example
    #   features_to_fitnesse('features/account', 'FitNesseRoot/AccountTests')
    #
    # @param [String] features_path
    #   Directory where `.feature` files reside
    # @param [String] fitnesse_path
    #   Directory within the FitNesse wiki hierarchy where converted features
    #   will be written as wiki pages. This must be the path of an existing page.
    #
    def features_to_fitnesse(features_path, fitnesse_path)
      # Ensure FitNesse directory already exists
      if !File.directory?(fitnesse_path)
        raise ArgumentError, "FitNesse path must be an existing directory."
      end

      # Get all .feature files
      features = Dir.glob(File.join(features_path, '**', '*feature'))

      # For each .feature file
      features.each do |feature_path|
        # Determine the appropriate wiki path name
        wiki_path = File.join(fitnesse_path, wikify_path(feature_path))
        # Fill that wiki path with content stubs
        create_content_stubs(wiki_path)
        # Convert the .feature to wikitext
        content = feature_to_fitnesse(File.open(feature_path)).join("\n")
        # Write the wikitext to a wiki page
        create_wiki_page(wiki_path, content, 'test')
        # Show user some status output
        puts "OK: #{feature_path} => #{wiki_path}"
      end
    end


    # Create a new wiki page at the given path, with the given content.
    #
    # @param [String] path
    #   Directory name where page should reside. Will be created if it
    #   does not already exist.
    # @param [String] content
    #   Raw string content of the new page. May contain newlines.
    # @param [String] type
    #   Type of page to write. May be 'normal', 'test', or 'suite'.
    #
    def create_wiki_page(path, content, type='normal')
      FileUtils.mkdir_p(path)
      # Write the content
      File.open(File.join(path, 'content.txt'), 'w') do |file|
        file.write(content)
      end
      # Write the properties.xml
      File.open(File.join(path, 'properties.xml'), 'w') do |file|
        file.puts '<?xml version="1.0"?>'
        file.puts '<properties>'
        file.puts '  <Edit>true</Edit>'
        file.puts '  <Files>true</Files>'
        file.puts '  <Properties>true</Properties>'
        file.puts '  <RecentChanges>true</RecentChanges>'
        file.puts '  <Refactor>true</Refactor>'
        file.puts '  <Search>true</Search>'
        if type == 'test'
          file.puts '  <Test/>'
        elsif type == 'suite'
          file.puts '  <Suite/>'
        end
        file.puts '  <Versions>true</Versions>'
        file.puts '  <WhereUsed>true</WhereUsed>'
        file.puts '</properties>'
      end
    end


    # Create a stub `content.txt` file in the given directory, and all
    # ancestor directories, if a `content.txt` does not already exist.
    #
    # @example
    #   create_content_stubs('FitNesseRoot/PageOne/PageTwo/PageThree')
    #     # Creates these files, and their containing directories:
    #     #   FitNesseRoot/PageOne/content.txt
    #     #   FitNesseRoot/PageOne/PageTwo/content.txt
    #     #   FitNesseRoot/PageOne/PageTwo/PageThree/content.txt
    #
    # @param [String] fitnesse_path
    #   Directory name of deepest level in the wiki hierarchy where
    #   you want content stubs to be created
    #
    def create_content_stubs(fitnesse_path)
      path = fitnesse_path
      # While there are ancestor directories
      while path != '.'
        # If there is no content.txt file, create one
        if !File.exists?(File.join(path, 'content.txt'))
          create_wiki_page(path, '!contents')
        end
        # Get the parent path
        path = File.dirname(path)
      end
    end

  end
end

