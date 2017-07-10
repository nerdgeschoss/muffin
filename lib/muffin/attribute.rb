module Muffin
  class Attribute
    def initialize(name:, type:, array:, default:, permit:, permitted_values:, block:)
      array = true if array == nil && (type&.is_a?(Array) || block)
      array ||= false
      type = type.first if type&.is_a? Array
      @name = name
      @type = type
      @array = array
      @default = default
      @permit = permit
      @permitted_values = permitted_values
    end

    attr_reader :name, :type, :default, :permit, :permitted_values

    def array?
      @array
    end

    def coercise(value)
      convert value
    end

    private

    def convert(value, access_array: false)
      return convert(default) if value == nil && default
      return (value || []).map { |e| convert(e, access_array: true) } if array? && !access_array
      if type <= Integer
        value&.to_i
      elsif type <= Float
        value&.to_f
      elsif type <= String
        value&.to_s
      elsif type <= Muffin::Boolean
        type.new(value).to_bool
      else
        type.new(value || {})
      end
    end
  end
end
