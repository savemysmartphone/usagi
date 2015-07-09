module Usagi
  class ApiResponse
    def initialize(data)
      @data = data
    end

    def ==(other_data)
      return true if @data == Usagi::ApiResponse::any_value
      raise "non-matching data: #{@data}__#{other_data}__" unless @data.class == other_data.class
      case @data.class.to_s
      when 'Array'
        raise "non-matching array length: #{@data}__#{other_data}__" unless @data.length == other_data.length
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
      attr_accessor :unmatchable_keys

      def any_value
        @any_value || 'ANY_VALUE'
      end

      def unmatchable_keys
        @unmatchable_keys || %i(created_at updated_at deleted_at)
      end
    end
  end
end
