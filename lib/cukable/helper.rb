# Helper functions for Cukable

require 'cgi'
require 'digest/md5'

module Cukable
  module Helper
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
    #   escape_camel_case("With a CamelCase word") #=> "With a !-CamelCase-! word"
    #
    # @param [String] string
    #   String to escape CamelCase words in
    #
    # @return [String]
    #   Same string with CamelCase words escaped
    #
    def escape_camel_case(string)
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
      # TODO: Handle the case where the last path component is a directory,
      # or is a filename without an extension
      parts = path.split(File::SEPARATOR)
      wiki_parts = parts[0..-2].map {|dir| wikify(dir) + 'Dir'} + [wikify(parts[-1])]
      wiki_path = File.join(wiki_parts)
      return wiki_path
    end


    # Return an MD5 digest string for `table`. Any HTML entities in the table
    # are unescaped before the digest is calculated.
    #
    # @param [Array] table
    #   Array of strings, or nested Array of strings
    #
    # @return [String]
    #   Accumulated MD5 digest of all strings in `table`
    #
    def table_digest(table)
      digest = Digest::MD5.new
      table.flatten.each do |cell|
        digest.update(CGI.unescapeHTML(cell))
      end
      return digest.to_s
    end

  end
end

