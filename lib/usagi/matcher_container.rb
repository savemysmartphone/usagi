require_relative 'matcher'

class MatcherContainer
  extend Enumerable

  def each
    matchers.each do |matcher|
      yield matcher
    end
  end

  def find_from_scenario(scenario_value)
    return nil unless scenario_value =~ /^([A-Z_]+)(\(.*\))?$/
    matcher, args = matchers[$1], $2
    args = eval("[#{args[1..-2]}]") if args
    return nil unless matcher
    [matcher, args]
  end

  def [](name)
    matchers[name.to_s.upcase]
  end

  def []=(name, value)
    matchers[name.to_s.upcase] = value
  end

  private
  def matchers
    @matchers ||= {}
  end
end
