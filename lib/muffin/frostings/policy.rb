require_relative "../error"

module Muffin
  module Policy
    module ClassMethods
      attr_reader :permission_block

      def permitted?(&block)
        @permission_block = block
      end
    end

    def permit!
      raise NotPermittedError unless permitted?
    end

    def permitted?
      return true unless self.class.permission_block
      instance_eval(&self.class.permission_block)
    end

    def attribute_permitted?(name)
      block = self.class.attributes[name]&.permit
      return instance_exec(&block) if block
      true
    end

    def permit_attribute!(name, value)
      return false unless attribute_permitted?(name)
      permitted = attribute_value_permitted?(name, value)
      return false if value == nil && !permitted
      raise NotPermittedError unless permitted
      true
    end

    def permitted_values(name)
      block = self.class.attributes[name]&.permitted_values
      return instance_exec(&block) if block
      nil
    end

    def attribute_value_permitted?(name, value)
      block = self.class.attributes[name]&.permitted_values
      return true unless block
      instance_exec(&block).include? value
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end
