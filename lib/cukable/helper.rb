# Helper functions for Cukable

require 'cgi'
require 'digest/md5'

module Cukable

  # Common/shared methods supporting the Cukable library
  module Helper

    # Return `filename` with `prefix` and `suffix` removed, and any
    # path-separators converted to underscores.
    #
    # @example
    #   clean_filename('abc/some/path/xyz', 'abc', 'xyz')
    #     #=> 'some_path'
    #
    # @param [String] filename
    #   Filename to clean
    # @param [String] prefix
    #   Leading text to remove
    # @param [String] suffix
    #   Trailing text to remove
    #
    # @return [String]
    #   Cleaned filename with prefix and suffix removed
    #
    def clean_filename(filename, prefix, suffix)
      middle = filename.gsub(/^#{prefix}\/(.+)\/#{suffix}$/, '\1')
      return middle.gsub('/', '_')
    end


    # Remove FitNesse-generated link cruft from a string. Strips `<a ...></a>`
    # tags, keeping the inner content unless that content is '[?]'.
    #
    # @example
    #   remove_cruft('Go to <a href="SomePage">this page</a>')
    #     #=> 'Go to this page'
    #   remove_cruft('See SomePage<a href="SomePage">[?]</a>')
    #     #=> 'See SomePage'
    #
    # @param [String] string
    #   The string to remove link-cruft from
    #
    # @return [String]
    #   Same string with `<a ...></a>` and `[?]` removed.
    #
    def remove_cruft(string)
      string.gsub(/<a [^>]*>([^<]*)<\/a>/, '\1').gsub('[?]', '')
    end


    # Wikify (CamelCase) the given string, removing spaces, underscores, dashes
    # and periods, and CamelCasing the remaining words. If this does not result
    # in a CamelCase word with at least two words in it (that is, if the input was
    # only a single word), then the last letter in the word is capitalized so
    # as to make FitNesse happy.
    #
    # @example
    #   wikify('file.extension')   #=> 'FileExtension'
    #   wikify('with_underscore')  #=> 'WithUnderscore'
    #   wikify('having spaces')    #=> 'HavingSpaces'
    #   wikify('foo')              #=> 'FoO'
    #
    # @param [String] string
    #   String to wikify
    #
    # @return [String]
    #   Wikified string
    #
    # FIXME: This will not generate valid FitNesse wiki page names for
    # pathological cases, such as any input that would result in consecutive
    # capital letters, including words having only two letters in them.
    #
    def wikify(string)
      string.gsub!(/^[a-z]|[_.\s\-]+[a-z]/) { |a| a.upcase }
      string.gsub!(/[_.\s\-]/, '')
      if string =~ /(([A-Z][a-z]*){2})/
        return string
      else
        return string.gsub(/.\b/) { |c| c.upcase }
      end
    end


    # Return the given string with any CamelCase words, email addresses, and
    # URLs escaped with FitNesse's `!-...-!` string-literal markup.
    #
    # @example
    #   literalize('With a CamelCase word')
    #     #=> 'With a !-CamelCase-! word'
    #
    # @param [String] string
    #   String to escape CamelCase words in
    #
    # @return [String]
    #   Same string with CamelCase words escaped
    #
    # FIXME: Literals inside other literals will cause too much escaping!
    def literalize(string)
      result = string.strip

      # Literalize email addresses
      # FitNesse pattern for email addresses, per TextMaker.java:
      #   [\w\-_.]+@[\w\-_.]+\.[\w\-_.]+
      result.gsub!(/([\w\-_.]+@[\w\-_.]+\.[\w\-_.]+)/, '!-\1-!')


      # Literalize CamelCase words
      # Regex for matching wiki words, according to FitNesse.UserGuide.WikiWord
      #   \b[A-Z](?:[a-z0-9]+[A-Z][a-z0-9]*)+
      result.gsub!(/(\b[A-Z](?:[a-z0-9]+[A-Z][a-z0-9]*)+)/, '!-\1-!')

      # Literalize URLs
      # Brain-dead URL matcher, should do the trick in most cases though
      # (Better to literalize too much than not enough)
      result.gsub!(/(http[^ ]+)/, '!-\1-!')

      return result
    end


    # Wikify the given path name, and return a path that's suitable
    # for use as a FitNesse wiki page path. Any path component having only
    # a single word in it will have the last letter in that word capitalized.
    #
    # @example
    #   wikify_path('features/account/create.feature')
    #     #=> 'FeatureS/AccounT/CreateFeature'
    #
    # @param [String] path
    #   Arbitrary path name to convert
    #
    # @return [String]
    #   New path with each component being a WikiWord
    #
    def wikify_path(path)
      wiki_parts = path.split(File::SEPARATOR).collect do |part|
        wikify(part)
      end
      return File.join(wiki_parts)
    end


    # Return an MD5 digest string for `table`. Any HTML entities and FitNesse
    # markup in the table is unescaped before the digest is calculated.
    #
    # @example
    #   table_digest(['foo'], ['bar'])
    #     #=> '3858f62230ac3c915f300c664312c63f'
    #   table_digest(['foo', 'baz'])
    #     #=> '80338e79d2ca9b9c090ebaaa2ef293c7'
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
        digest.update(unescape(cell))
      end
      return digest.to_s
    end


    # Unescape any HTML entities and FitNesse markup in the given string.
    #
    # @example
    #   unescape('Some &lt;stuff&gt; to !-unescape-!')
    #     #=> 'Some <stuff> to unescape'
    #
    # @param [String] string
    #   The string to unescape HTML entities in
    #
    # @return [String]
    #   Original string with HTML entities unescaped, and FitNesse `!-...-!`
    #   markup removed.
    #
    def unescape(string)
      result = CGI.unescapeHTML(string)
      result.gsub!(/!-(.*?)-!/, '\1')
      return result
    end


    # Return the given string, cleaned of any HTML tags and status indicators
    # added by the JSON output formatter. The intent here is to take a table
    # cell from JSON output, and make it match the original FitNesse table
    # cell.
    #
    # @example
    #   clean_cell('pass:Given some <b>bold text</b>')
    #     #=> 'Given some bold text'
    #   clean_cell('pass:Given a step <br>with line break')
    #     #=> 'Given a step'
    #
    # @param [String] string
    #   String to clean
    #
    # @return [String]
    #   String with any SlimJSON-added stuff removed.
    #
    def clean_cell(string)
      # FIXME: This may not be terribly efficient...
      # strip first to get a copy of the string
      result = string.strip
      # Remove extra stuff added by JSON formatter
      result.gsub!(/^[^:]*:(.*)$/, '\1')        # status indicator
      result.gsub!(/<b>|<\/b>/, '')             # all bold tags
      result.gsub!(/<br\/?>.*/, '')             # <br> and anything that follows
      result.gsub!(/<span[^>]*>.*<\/span>/, '') # spans and their content
      result.gsub!(/\(Undefined Step\)/, '')    # (Undefined Step)
      return result.strip
    end
  end
end

