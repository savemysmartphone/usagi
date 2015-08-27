module Usagi
  class ApiResponse
    def initialize(data)
      @data = data
    end

    def ==(other_data)
      puts "EXPECTED: #{@data}"
      puts "GOT: #{other_data}"
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
      return true if @data == Usagi::ApiResponse::any_value
      return true if @data == Usagi::ApiResponse::any_value_not_nil && @data != nil
      raise "non-matching data: #{@data}__#{other_data}__" unless @data.class == other_data.class
      case @data.class.to_s
      when 'Array'
        raise "non-matching array length (#{@data.length} != #{other_data.length}): #{@data}__#{other_data}__" unless @data.length == other_data.length
        raise "non-matching arrays: #{@data}__#{other_data}__" unless @data.each_with_index.all? do |value, i|
          Usagi::ApiResponse.new(value) == other_data[i]
        end
      when 'Hash'
        raise "non-matching hash keys: #{@data.keys}__#{other_data.keys}__" unless @data.keys.length == other_data.keys.length
        raise "non-matching hashes: #{@data}__#{other_data}__" unless @data.all? do |key, value|
          next true if Usagi::ApiResponse.unmatchable_keys.include?(key)
          Usagi::ApiResponse.new(value) == other_data[key]
        end
      else
        raise "non-matching data: #{@data}__#{other_data}" unless @data == other_data
      end
      true
    end

    class << self
      attr_accessor :any_value
      attr_accessor :any_value_not_nil
      attr_accessor :unmatchable_keys
      attr_accessor :stored_values

      def any_value
        @any_value || 'ANY_VALUE'
      end

      def any_value_not_nil
        @any_value_not_nil || 'ANY_VALUE_NOT_NIL'
      end

      def unmatchable_keys
        @unmatchable_keys || %i(created_at updated_at deleted_at)
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
