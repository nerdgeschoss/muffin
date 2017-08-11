module Muffin
  class Attribute
    def initialize(name:, type:, array:, default:, permit:, permitted_values:, coerce:, block:)
      array = true if array == nil && (type&.is_a?(Array) || block)
      array ||= false
      type = type.first if type&.is_a? Array
      @name = name
      @type = type
      @array = array
      @default = default
      @permit = permit
      @permitted_values = permitted_values
      @coerce = coerce
    end

    attr_reader :name, :type, :default, :permit, :permitted_values, :coerce

    def array?
      @array
    end

    def coercise(value)
      # the benefit of having @coerce here instead of in #convert is that the whole convert magic (like arrays) works as is
      convert coerce.respond_to?(:call) ? coerce.call(value) : value
    end

    private

    def convert(value, access_array: false)
      return convert(default) if value == nil && default
      return (value || []).map { |e| convert(e, access_array: true) } if array? && !access_array
      return value if value.is_a? type # do not coerce if type matches; do not deep dup else AR instances do not match (e.g. for permitted values)
      return value if value.nil?

      if type <= DateTime
        DateTime.parse(value).in_time_zone if value.present?
      elsif type <= Date # needs to come *after* DateTime because DateTime <= Date
        Date.parse(value) if value.present?
      elsif type <= Integer
        value&.to_i
      elsif type <= Float
        value&.to_f
      elsif type <= String
        value&.to_s
      elsif type <= Symbol
        value.class <= Integer ? value.to_s.to_sym : value&.to_sym
      elsif type <= Time
        Time.parse(value).in_time_zone if value.present?
      elsif type <= BigDecimal
        type.new(value) if value.present?
      elsif type <= Hash
        type.new.merge!(value&.to_h&.deep_dup) if value.present?
      elsif type <= Muffin::Boolean
        type.new(value).to_bool
      else
        type.new(value || {})
      end
    end
  end
end
