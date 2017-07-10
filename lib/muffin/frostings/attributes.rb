require_relative "../attribute"
require_relative "../boolean"

module Muffin
  module Attributes
    module ClassMethods
      def attribute(name, type = String, default: nil, array: nil, permit: nil, permitted_values: nil, &block)
        attributes[name] = Muffin::Attribute.new name: name, type: type, default: default, array: array, permit: permit, permitted_values: permitted_values, block: block
        define_method name do
          attributes && attributes[name]
        end
        define_method "#{name}=" do |value|
          @attributes ||= {}
          attributes[name] = self.class.attributes[name].coercise(value)
        end
      end

      def attributes
        @attributes ||= {}
      end

      def introspect(name)
        attributes[name]
      end
    end

    attr_reader :attributes

    def attributes=(value)
      self.class.attributes.keys.map { |e| [e, nil] }.to_h.merge(value.to_h).each do |k, v|
        send("#{k}=", v) if self.class.attributes[k.to_sym]
      end
    end

    def assign_attributes
      self.attributes = params
    end

    def self.included(base)
      base.extend ClassMethods
    end

    Boolean = Muffin::Boolean.freeze
  end
end
