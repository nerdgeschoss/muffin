require_relative "./types/any"
require_relative "./types/date_time"
require_relative "./types/hash"
require_relative "./types/symbol"

module Muffin
  class Attribute
    class << self
      def default_types
        {
          any: Muffin::Type::Any,
          binary: ActiveRecord::Type::Binary,
          boolean: ActiveRecord::Type::Boolean,
          date: ActiveRecord::Type::Date,
          datetime: Muffin::Type::DateTime,
          decimal: ActiveRecord::Type::Decimal,
          float: ActiveRecord::Type::Float,
          hash: Muffin::Type::Hash,
          integer: ActiveRecord::Type::Integer,
          string: ActiveRecord::Type::String,
          symbol: Muffin::Type::Symbol
        }
      end

      def register_type(name, type)
        @types ||= default_types
        @types[name] = type
      end

      def lookup_type(name)
        @types ||= default_types
        @types[name]&.new
      end
    end

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

    def lookup(type)
      return type if type.respond_to? :call

      serializer = type.new if type.respond_to?(:new)
      return serializer if serializer.respond_to?(:deserialize)

      self.class.lookup_type(type) || raise(StandardError, "Unknown type #{type} for #{name}")
    end

    def convert(value, access_array: false)
      return convert(default) if value == nil && default
      return (value || []).map { |e| convert(e, access_array: true) } if array? && !access_array

      deserializer = lookup(type)
      deserializer.respond_to?(:call) ? deserializer.call(value) : deserializer.deserialize(value)
    end
  end
end
