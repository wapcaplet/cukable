require 'fileutils'

module Cukable
  class Converter

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
        wiki_path = File.join(fitnesse_path, wikify_path(filename))
        # Fill that wiki path with content stubs
        create_content_stubs(wiki_path)
        # Convert the .feature to wikitext
        content = wikify_feature(File.open(feature_path))
        # Write the wikitext to a wiki page
        create_wiki_page(wiki_path, content, 'test')
        # Show user some status output
        puts "OK: #{feature_path} => #{wiki_path}"
      end
    end


    # Wikify (CamelCase) the given string, removing spaces, underscores,
    # dashes and periods, and CamelCasing the remaining words.
    #
    # @example
    #   wikify("file.extension")   #=> "FileExtension"
    #   wikify("with_underscore")  #=> "WithUnderscore"
    #   wikify("having spaces")    #=> "HavingSpaces"
    #
    # @param [String] string
    #   String to wikify
    #
    # @return [String]
    #   Wikified string
    #
    def wikify(string)
      string.gsub!(/^[a-z]|[_.\s\-]+[a-z]/) { |a| a.upcase }
      string.gsub!(/[_.\s\-]/, '')
      return string
    end


    # Return the given string with any CamelCase words escaped with
    # FitNesse's `!-...-!` string-literal markup.
    #
    # @example
    #   sanitize("With a CamelCase word") #=> "With a !-CamelCase-! word"
    #
    # @param [String] string
    #   String to sanitize
    #
    # @return [String]
    #   Same string with CamelCase words escaped
    #
    def sanitize(string)
      return string.gsub(/(([A-Z][a-z]*){2,99})/, '!-\1-!')
    end


    # Wikify the given path name, and return a path that's suitable
    # for use as a FitNesse wiki page path. Directories will have 'Dir'
    # appended (to ensure a valid CamelCase name), and the filename will
    # have its extension CamelCased.
    #
    # @example
    #   wikify_path('features/account/create.feature')
    #     #=> 'FeaturesDir/AccountDir/CreateFeature'
    #
    # @param [String] path
    #   Arbitrary path name to convert
    #
    # @return [String]
    #   New path with each component being a WikiWord
    #
    def wikify_path(path)
      parts = path.split(File::SEPARATOR)
      wiki_parts = parts[0..-2].map {|dir| wikify(dir) + 'Dir'} + [wikify(parts[-1])]
      wiki_path = File.join(wiki_parts)
      return wiki_path
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


    # Wikify the given feature, and return FitNesse wikitext.
    #
    # @param [Array, File] feature
    #   An iterable that yields each line in a Cucumber feature. May be
    #   an open File object, or an Array of lines.
    #
    # @return [String]
    #   FitNesse wikitext, containing a table with all scenarios in the feature
    #
    def wikify_feature(feature)

      # Unparsed text (between 'Feature:' line and the first Background/Scenario)
      unparsed = []
      # Table (all Background, Scenario, and Scenario Outlines with steps
      table = []
      table << "| Table: Cuke |"

      # Are we in the unparsed-text section of the .feature file?
      in_unparsed = false

      feature.each do |line|
        line = sanitize(line.strip)

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
      # Join with newlines, and add one more newline at the end
      return unparsed.join("\n") + "\n\n" + table.join("\n") + "\n"
    end


  end
end

