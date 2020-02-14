require_relative "../attribute"
require_relative "../boolean"
require_relative "policy"
require_relative "validation"

module Muffin
  module Attributes
    module ClassMethods
      def attribute(name, type = :string, default: nil, array: nil, permit: nil, permitted_values: nil, &block)
        if block
          type_class = define_class name, block
          type = ->(value) { type_class.new(value && value.to_h) }
        end
        attributes[name] = Muffin::Attribute.new name: name, type: type, default: default, array: array, permit: permit, permitted_values: permitted_values, block: block
        define_method name do
          instance_variable_get "@#{name}"
        end
        define_method "#{name}=" do |value|
          instance_variable_set "@#{name}", self.class.attributes[name].coercise(value.nil? ? default : value) if permit_attribute!(name, value)
        end
      end

      def attributes
        @attributes ||= {}
      end

      def introspect(name)
        attributes[name]
      end

      def reflect_on_association(name)
        OpenStruct.new klass: attributes[name].type
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
      self.class.attributes.keys.map { |e| [e, nil] }.to_h.merge(value.to_h).each do |k, v|
        send("#{k}=", v) if self.class.attributes[k.to_sym]
      end
    end

    def attributes
      self.class.attributes.keys.select { |e| attribute_permitted?(e) }.map do |key|
        [key, public_send(key)]
      end.to_h
    end

    def assign_attributes
      params.each do |key, value|
        public_send("#{key}=", value) if self.class.attributes[key.to_sym]
      end
    end

    def assign_defaults
      self.class.attributes.values.reject { |e| e.default.nil? }.map do |attribute|
        public_send("#{attribute.name}=", attribute.default) if public_send(attribute.name).nil?
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end

    def persisted?
      try(:id).present?
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

    def initialize(attributes = {})
      self.attributes = attributes
    end
  end
end
