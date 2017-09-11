module ToRegex
  module StringMixin
    class << self
      def literal?(str)
        REGEXP_DELIMITERS.none? { |s, e| str.start_with?(s) and str =~ /#{e}#{INLINE_OPTIONS}\z/ }
      end
    end

    INLINE_OPTIONS = /[imxnesu]*/
    REGEXP_DELIMITERS = {
      '%r{' => '}',
      '/' => '/',
    }

    # Get a regex back
    #
    # Without :literal or :detect, `"foo".to_regex` will return nil.
    #
    # @param [optional, Hash] options
    # @option options [true,false] :literal Treat meta characters and other regexp codes as just text; always return a regexp
    # @option options [true,false] :detect If string starts and ends with valid regexp delimiters, treat it as a regexp; otherwise, interpret it literally
    # @option options [true,false] :ignore_case /foo/i
    # @option options [true,false] :multiline /foo/m
    # @option options [true,false] :extended /foo/x
    # @option options [true,false] :lang /foo/[nesu]
    def to_regex(options = {})
      if args = as_regexp(options)
        ::Regexp.new(*args)
      end
    end

    # Return arguments that can be passed to `Regexp.new`
    # @see to_regexp
    def as_regexp(options = {})
      unless options.is_a?(::Hash)
        raise ::ArgumentError, "[to_regexp] Options must be a Hash"
      end
      str = self

      return if options[:detect] and str == ''

      if options[:literal] or (options[:detect] and ToRegexp::String.literal?(str))
        content = ::Regexp.escape str
      elsif delim_set = REGEXP_DELIMITERS.detect { |k, _| str.start_with?(k) }
        delim_start, delim_end = delim_set
        /\A#{delim_start}(.*)#{delim_end}(#{INLINE_OPTIONS})\z/u =~ str
        content = $1
        inline_options = $2
        return unless content.is_a?(::String)
        content.gsub! '\\/', '/'
        if inline_options
          options[:ignore_case] = true if inline_options.include?('i')
          options[:multiline] = true if inline_options.include?('m')
          options[:extended] = true if inline_options.include?('x')
          # 'n', 'N' = none, 'e', 'E' = EUC, 's', 'S' = SJIS, 'u', 'U' = UTF-8
          options[:lang] = inline_options.scan(/[nesu]/i).join.downcase
        end
      else
        return
      end

      ignore_case = options[:ignore_case] ? ::Regexp::IGNORECASE : 0
      multiline = options[:multiline] ? ::Regexp::MULTILINE : 0
      extended = options[:extended] ? ::Regexp::EXTENDED : 0
      lang = options[:lang] || ''
      if ::RUBY_VERSION > '1.9' and lang.include?('u')
        lang = lang.delete 'u'
      end

      if lang.empty?
        [ content, (ignore_case|multiline|extended) ]
      else
        [ content, (ignore_case|multiline|extended), lang ]
      end
    end
  end
end

class String
  include ToRegex::StringMixin
end
