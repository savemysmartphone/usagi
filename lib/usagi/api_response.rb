module Usagi
  class ApiResponse
    def initialize(data)
      @data = data
    end

    def ==(other_data)
      return true if @data == 'ANY_VALUE'
      raise "non-matching data: #{@data}__#{other_data}__" unless @data.class == other_data.class
      case @data.class.to_s
      when 'Array'
        raise "non-matching array length: #{@data}__#{other_data}__" unless @data.length == other_data.length
        @data.each_with_index.all? do |value, i|
          Usagi::ApiResponse.new(value) == other_data[i]
        end
      when 'Hash'
        raise "non-matching hash name: #{@data}__#{other_data}__" unless @data.keys.length == other_data.keys.length
        @data.all? do |key, value|
          next true if %i(created_at updated_at deleted_at).include?(key)
          Usagi::ApiResponse.new(value) == other_data[key]
        end
      else
        @data == other_data
      end
    end
  end
end
