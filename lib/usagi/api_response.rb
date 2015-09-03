require_relative 'matcher_container'
require_relative 'usagi_matchers'

module Usagi
  class ApiResponse
    def initialize(data)
      @data = data
    end

    def ==(other_data)
      ## matchers
      if @data =~ /^STORE_VALUE\((:.*)\)$/
        return Usagi::ApiResponse.store_value($1, other_data)
      end
      if @data =~ /^REUSE_VALUE\((:.*)\)$/
        @data = Usagi::ApiResponse.reuse_value($1)
        unless @data == other_data
          raise "non-matching stored data: #{@data}__#{other_data}__"
        end
        return true
      end

      # usagi_matchers
      if matcher_and_args = Usagi.matchers.find_from_scenario(@data)
        matcher, args = *matcher_and_args
        return true if matcher.matches?(other_data, args)
      else
        raise "non-matching data: (expected: #{@data}, got: #{other_data})" unless @data.class == other_data.class
        case @data.class.to_s
        when 'Array'
          raise "non-matching array length (expected: #{@data.length}, got #{other_data.length})" unless @data.length == other_data.length
          raise "non-matching arrays (expected: #{@data}, got: #{other_data})" unless @data.each_with_index.all? do |value, i|
            Usagi::ApiResponse.new(value) == other_data[i]
          end
        when 'Hash'
          exp_keys = @data.keys.map(&:to_sym) - Usagi::ApiResponse.unmatchable_keys
          got_keys = other_data.keys.map(&:to_sym) - Usagi::ApiResponse.unmatchable_keys
          raise "non-matching hash keys (expected: #{exp_keys}, got: #{got_keys}" unless exp_keys.length == got_keys.length
          raise "non-matching hashes (expected #{@data}, got: #{other_data})" unless @data.all? do |key, value|
            next true if Usagi::ApiResponse.unmatchable_keys.include?(key)
            Usagi::ApiResponse.new(value) == other_data[key]
          end
        else
          raise "non-matching data (expected: #{@data}, got: #{other_data})" unless @data == other_data
        end
      end
      true
    end

    class << self
      attr_accessor :unmatchable_keys
      attr_accessor :stored_values

      def unmatchable_keys
        Usagi.suite_options[:unmatchable_keys] ||%i(created_at updated_at)
      end

      def reuse_value(name)
        @stored_values ||= {}
        unless @stored_values.keys.include?(name) || Usagi.options[:allow_nil_store_values]
          raise ArgumentError, "stored value name #{name} was never used"
        end
        value = @stored_values[name]
        puts "[usagi][#{Usagi.pid}] REUSE _#{value}_"
        value
      end

      def store_value(name, value)
        @stored_values ||= {}
        if @stored_values.keys.include?(name) && !Usagi.options[:allow_store_key_reuse]
          raise ArgumentError, "stored value name #{name} already used"
        end
        @stored_values[name] = value
        puts "[usagi][#{Usagi.pid}] STORE #{name} => #{value}"
        return true
      end
    end
  end
end

