require_relative "../attribute"
require_relative "../boolean"
require_relative "policy"
require_relative "validation"

module Muffin
  module Attributes
    module ClassMethods
      def attribute(name, type = String, default: nil, array: nil, permit: nil, permitted_values: nil, coerce: nil, &block)
        type = define_class name, block if block
        attributes[name] = Muffin::Attribute.new name: name, type: type, default: default, array: array, permit: permit, permitted_values: permitted_values, coerce: coerce, block: block
        define_method name do
          attributes && attributes[name]
        end
        define_method "#{name}=" do |value|
          @attributes ||= {}
          value = self.class.attributes[name].coercise(value)
          attributes[name] = value if permit_attribute!(name, value)
        end
      end

      def attributes
        @attributes ||= {}
        superclass <= Muffin::Base ? @attributes.merge!(superclass.attributes) : @attributes
        @attributes
      end

      def introspect(name)
        attributes[name]
      end

      private

      def define_class(name, block)
        class_name = name.to_s.split("_").map(&:capitalize).join
        return const_get class_name if const_defined? class_name
        klass = const_set class_name, Class.new(Muffin::NestedAttribute)
        klass.instance_eval(&block)
        klass
      end
    end

    attr_reader :attributes

    def attributes=(value)
      HashWithIndifferentAccess.new(self.class.attributes.keys.map { |e| [e, nil] }.to_h).merge(value.to_h).each do |k, v|
        setter_name = "#{k}="
        send(setter_name, v) if self.class.attributes[k.to_sym] && respond_to?(setter_name) # for nested forms we don't have setters on the base form
      end
    end

    def assign_attributes
      self.attributes = params
    end

    def self.included(base)
      base.extend ClassMethods
    end

    def persisted?
      attributes[:id].present?
    end

    # fields_for checks wether an object responds to [foo_attributes=]
    def respond_to_missing?(method_name, include_private = false)
      return true if method_name.to_s[/_attributes=\Z/]
      super
    end

    Boolean = Muffin::Boolean.freeze
  end

  class NestedAttribute
    include Attributes
    include Policy
    include Validation

    validates_with Muffin::Validation::NestedAttributesValidator

    def initialize(attributes)
      self.attributes = attributes
    end
  end
end
