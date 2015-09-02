class Matcher
  attr_accessor :name

  def initialize(name, &block)
    @name = name
    @matcher = block
  end

  def matches?(api_value, args)
    mi = MatcherInstance.new(@matcher, api_value, args)
    raise mi.error_message unless mi.matches?
  end

  class MatcherInstance
    attr_accessor :api_value, :args

    def initialize(matcher_block, api_value, args)
      @api_value = api_value
      instance_exec(*args, &matcher_block)
    end

    def error_block
      @error || lambda{|api_value| "non-matching value: #{api_value}" }
    end

    def error_message
      error_block.call(api_value)
    end

    def matches?
      @match.call(api_value)
    end

    private
    def error(&block)
      @error = block
    end

    def match(&block)
      @match = block
    end
  end
end

