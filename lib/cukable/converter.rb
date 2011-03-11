require 'fileutils'

module Cukable
  module Converter
    # Recursively find all .feature files in the given directory
    def feature_hierarchy(dir)
      pattern = File.join(dir, '**', '*.feature')
      return Dir.glob(pattern)
    end


    # Wikify (CamelCase) the given string, removing spaces, underscores,
    # dashes and periods, and CamelCasing the remaining words.
    #
    # Examples:
    #
    #   wikify("file.extension") => "FileExtension"
    #   wikify("with_underscore") => "WithUnderscore"
    #   wikify("having spaces") => "HavingSpaces"
    #
    def wikify(string)
      string.gsub!(/^[a-z]|[_.\s\-]+[a-z]/) { |a| a.upcase }
      string.gsub!(/[_.\s\-]/, '')
      return string
    end


    # Wikify the given path name, and return a path that's suitable
    # for use as a FitNesse wiki page path. Directories will have 'Dir'
    # appended (to ensure a valid CamelCase name), and the filename will
    # have its extension CamelCased.
    #
    #   wikify_path('features/marketing_campaign/create.feature')
    #   => 'FeaturesDir/MarketingCampaignDir/CreateFeature'
    #
    def wikify_path(path)
      parts = path.split(File::SEPARATOR)
      wiki_parts = parts[0..-2].map {|dir| wikify(dir) + 'Dir'} + [wikify(parts[-1])]
      wiki_path = File.join(wiki_parts)
      return wiki_path
    end


    # Return a FitNesse wiki-page hierarchy corresponding to the given
    # list of .feature filenames. For example:
    #
    #   'features/dealer/new.feature',
    #   'features/dealer/test_restaurant.feature',
    #   'features/marketing_campaign/create.feature',
    #   'features/marketing_campaign/create_template.feature'
    #
    #   =>
    #
    #   'FitNesseRoot/FeaturesDir/DealerDir/NewFeature'
    #   'FitNesseRoot/FeaturesDir/DealerDir/TestRestaurantFeature'
    #   'FitNesseRoot/FeaturesDir/MarketingCampaignDir/CreateFeature'
    #   'FitNesseRoot/FeaturesDir/MarketingCampaignDir/CreateTemplateFeature'
    #
    def features_to_wiki(feature_files, wiki_dir='')
      feature_files.collect do |filename|
        if !wiki_dir.empty?
          File.join(wiki_dir, wikify_path(filename))
        else
          File.join(wikify_path(filename))
        end
      end
    end


    # Create a new wiki page at the given path, with the given content.
    # `type` may be 'normal', 'test', or 'suite'.
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


    # Return the given string with any CamelCase words escaped with
    # FitNesse's `!- ... -!` string-literal markup.
    def sanitize(string)
      return string.gsub(/(([A-Z][a-z]*){2,99})/, '!-\1-!')
    end


    # Read the given `.feature` file, and return its content converted to
    # FitNesse wiki-page format.
    def wikify_content(feature_filename)

      # Unparsed text (between 'Feature:' line and the first Background/Scenario)
      unparsed = []
      # Table (all Background, Scenario, and Scenario Outlines with steps
      table = []
      table << "| Table: Cuke |"

      # Are we in the unparsed-text section of the .feature file?
      in_unparsed = false

      File.open(feature_filename).each do |line|
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
        elsif in_unparsed and line != ''
          puts "  Unparsed: #{line}"
          unparsed << line

        # If line contains a table row, insert a '|' at the beginning
        elsif line =~ /^\|.+\|$/
          table << "| #{line}"

        # If line is commented out, skip it
        elsif line =~ /^#.*$/
          nil

        # Otherwise, if line is non-empty, insert a '|' at beginning and end
        elsif line != ''
          table << "| #{line} |"

        end
      end
      # Join with newlines, and add one more newline at the end
      return unparsed.join("\n") + "\n\n" + table.join("\n") + "\n"
    end


    # Create a stub `content.txt` file in the given directory, and all
    # ancestor directories, if a `content.txt` does not already exist.
    def stub_content(fitnesse_path)
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


    # Convert all .feature files in `features_path` to FitNesse wiki pages
    # under `fitnesse_path`.
    def convert_features_to_fitnesse(features_path, fitnesse_path)
      if !File.directory?(fitnesse_path)
        raise ArgumentError, "FitNesse path must be an existing directory."
      end
      # Get all .feature files
      features = feature_hierarchy(features_path)
      wiki_paths = features_to_wiki(features, fitnesse_path)

      features.zip(wiki_paths).each do |feature_path, wiki_path|
        puts "#{feature_path} => #{wiki_path}"
        # Create stub content pages all along this path
        stub_content(wiki_path)
        content = wikify_content(feature_path)
        create_wiki_page(wiki_path, content, 'test')
      end
    end

  end
end

