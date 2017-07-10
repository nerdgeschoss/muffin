module Muffin
  module Attributes
    module ClassMethods
      def attribute(name, type = String, default: nil, array: false, permit: nil, permitted_values: nil, &block)
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end

    class Boolean
      def initialize(value)
      end
    end
  end
end
